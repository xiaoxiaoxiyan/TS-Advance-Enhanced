#!/system/bin/sh
# ============================================================================
#  performance-tuner.sh
#  系统性能调度脚本 (System Performance Tuning Scheduler)
# ----------------------------------------------------------------------------
#  功能模块：
#    1. CPU 频率设置        (CPU Frequency Scaling)
#    2. GPU 频率设置        (GPU Frequency Scaling)
#    3. 温控设置            (Thermal Control / Throttling)
#    4. 屏幕采样率设置      (Touch / Display Sampling Rate)
#    5. 调速器设置          (CPU/GPU Governor & Tunables)
#    6. 动态场景调度        (Performance / Balance / Powersave + 自适应)
#
#  适用平台：Android (root) / 嵌入式 Linux (root)
#  依赖    ：BusyBox / Toybox 兼容的 sh、sysfs 接口
#  作者    ：Z.ai
#  版本    ：3.0.0  (新增交互式菜单)
# ============================================================================
#
#  快速使用：
#      ./performance-tuner.sh                       # 进入交互式菜单（推荐！）
#      ./performance-tuner.sh menu                  # 同上，进入交互菜单
#      ./performance-tuner.sh apply performance     # 立即应用「性能」档位
#      ./performance-tuner.sh apply balance         # 立即应用「均衡」档位
#      ./performance-tuner.sh apply powersave       # 立即应用「省电」档位
#      ./performance-tuner.sh status                # 查看当前状态
#      ./performance-tuner.sh stop                  # 停止守护进程并恢复
#      ./performance-tuner.sh monitor               # 实时监控温度/频率
#      ./performance-tuner.sh reload                # 重新加载配置
#
#  交互菜单功能：
#      [1] CPU 频率设置       - 自由调整 min/max 百分比、核心上下线
#      [2] GPU 频率设置       - 调整 GPU min/max、选择 GPU 调速器
#      [3] 温控设置           - 自定义温度阈值、热降频开关
#      [4] 屏幕采样率设置     - 选择触摸采样率、屏幕刷新率
#      [5] 调速器设置         - 选择 CPU governor、schedutil 参数调优
#      [6] 一键预设档位       - performance/balance/powersave/game
#      [7] 实时监控           - 彩色 + 进度条
#      [8] 查看当前完整状态
#      [9] 保存当前设置为配置文件（可选导出）
#      [s] 一键应用当前所有设置到系统
#      [0] 退出菜单
#
# ============================================================================

set -u   # 引用未定义变量报错

# ----------------------------------------------------------------------------
# 全局变量
# ----------------------------------------------------------------------------
VERSION="3.0.0"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
PID_FILE="/data/local/tmp/performance-tuner.pid"
LOG_FILE="/data/local/tmp/performance-tuner.log"
CONFIG_FILE="${SCRIPT_DIR}/tuner.conf"

# 默认调度间隔（秒）—— 守护循环的轮询周期
SCHEDULE_INTERVAL=5

# 当前生效的档位
CURRENT_PROFILE="balance"

# 运行模式：daemon(后台守护) | once(一次性应用)
RUN_MODE="once"

# 是否启用各模块（可被配置文件覆盖）
ENABLE_CPU=1
ENABLE_GPU=1
ENABLE_THERMAL=1
ENABLE_SCREEN=1
ENABLE_GOVERNOR=1
ENABLE_DYNAMIC=1          # 是否启用动态自适应调度

# 备份目录（用于 stop 时恢复原始设置）
BACKUP_DIR="/data/local/tmp/tuner-backup"

# 日志级别：0=静默 1=错误 2=警告 3=信息 4=调试
LOG_LEVEL=3

# 是否启用彩色输出（运行时自动检测终端）
USE_COLOR=""

# CPU 核心拓扑（运行时自动探测）
CPU_CLUSTER_BIG=""
CPU_CLUSTER_LITTLE=""
CPU_CLUSTER_PRIME=""
TOTAL_CPUS=0

# ============================================================================
# 颜色系统 (ANSI Color Codes)
# ============================================================================

# 检测终端是否支持彩色（仅检测一次）
detect_color_support() {
    if [ -n "${USE_COLOR}" ]; then return 0; fi
    # 显式禁用
    case "${NO_COLOR:-}" in
        1|true|TRUE|yes|YES) USE_COLOR=0; return 0 ;;
    esac
    # 非 TTY 且未强制启用 -> 禁用
    if [ -t 1 ] || [ "${FORCE_COLOR:-0}" = "1" ]; then
        USE_COLOR=1
    else
        USE_COLOR=0
    fi
}

# 定义颜色变量（仅在彩色启用时赋值，否则置空）
# 注意：用 printf 赋值真实 ESC 字节，使 %s 也能正确输出颜色
init_colors() {
    detect_color_support
    if [ "${USE_COLOR}" = "1" ]; then
        # 前景色
        C_RED=$(printf '\033[31m')
        C_GREEN=$(printf '\033[32m')
        C_YELLOW=$(printf '\033[33m')
        C_BLUE=$(printf '\033[34m')
        C_MAGENTA=$(printf '\033[35m')
        C_CYAN=$(printf '\033[36m')
        C_WHITE=$(printf '\033[37m')
        C_GRAY=$(printf '\033[90m')
        # 亮色
        C_BRED=$(printf '\033[91m')
        C_BGREEN=$(printf '\033[92m')
        C_BYELLOW=$(printf '\033[93m')
        C_BBLUE=$(printf '\033[94m')
        C_BMAGENTA=$(printf '\033[95m')
        C_BCYAN=$(printf '\033[96m')
        # 样式
        C_BOLD=$(printf '\033[1m')
        C_DIM=$(printf '\033[2m')
        C_UNDERLINE=$(printf '\033[4m')
        C_BLINK=$(printf '\033[5m')
        C_RESET=$(printf '\033[0m')
    else
        C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_MAGENTA=''
        C_CYAN=''; C_WHITE=''; C_GRAY=''
        C_BRED=''; C_BGREEN=''; C_BYELLOW=''; C_BBLUE=''; C_BMAGENTA=''; C_BCYAN=''
        C_BOLD=''; C_DIM=''; C_UNDERLINE=''; C_BLINK=''; C_RESET=''
    fi
}

# 颜色辅助函数（按语义封装，便于调用）
# C_* 变量已包含真实 ESC 字节，所以用 %s 即可
color_red()    { printf '%s%s%s' "${C_RED}"    "$*" "${C_RESET}"; }
color_green()  { printf '%s%s%s' "${C_GREEN}"  "$*" "${C_RESET}"; }
color_yellow() { printf '%s%s%s' "${C_YELLOW}" "$*" "${C_RESET}"; }
color_blue()   { printf '%s%s%s' "${C_BLUE}"   "$*" "${C_RESET}"; }
color_cyan()   { printf '%s%s%s' "${C_CYAN}"   "$*" "${C_RESET}"; }
color_magenta(){ printf '%s%s%s' "${C_MAGENTA}" "$*" "${C_RESET}"; }
color_gray()   { printf '%s%s%s' "${C_GRAY}"   "$*" "${C_RESET}"; }
color_bold()   { printf '%s%s%s' "${C_BOLD}"   "$*" "${C_RESET}"; }
color_dim()    { printf '%s%s%s' "${C_DIM}"    "$*" "${C_RESET}"; }

# 根据温度返回带颜色的字符串（绿/黄/红/紫表示不同危险级别）
# 用法: color_temp <millicelsius>
color_temp() {
    _t="${1:-0}"
    _c=$((_t / 1000))
    if [ "${_c}" -ge 80 ] 2>/dev/null; then
        printf '%s%d.%d°C%s' "${C_BRED}${C_BOLD}" "$((_t / 1000))" "$(( (_t % 1000) / 100 ))" "${C_RESET}"
    elif [ "${_c}" -ge 70 ] 2>/dev/null; then
        printf '%s%d.%d°C%s' "${C_BYELLOW}" "$((_t / 1000))" "$(( (_t % 1000) / 100 ))" "${C_RESET}"
    elif [ "${_c}" -ge 50 ] 2>/dev/null; then
        printf '%s%d.%d°C%s' "${C_YELLOW}" "$((_t / 1000))" "$(( (_t % 1000) / 100 ))" "${C_RESET}"
    else
        printf '%s%d.%d°C%s' "${C_BGREEN}" "$((_t / 1000))" "$(( (_t % 1000) / 100 ))" "${C_RESET}"
    fi
}

# 根据频率百分比上色（高频=绿，低频=灰，中频=青）
# 用法: color_freq <mhz> <max_mhz>
color_freq() {
    _f="${1:-0}"
    _max="${2:-1}"
    if [ "${_max}" -le 0 ] 2>/dev/null; then _max=1; fi
    _pct=$(( _f * 100 / _max ))
    if [ "${_pct}" -ge 80 ] 2>/dev/null; then
        printf '%s%dMHz%s' "${C_BGREEN}" "${_f}" "${C_RESET}"
    elif [ "${_pct}" -ge 50 ] 2>/dev/null; then
        printf '%s%dMHz%s' "${C_BCYAN}" "${_f}" "${C_RESET}"
    elif [ "${_pct}" -ge 20 ] 2>/dev/null; then
        printf '%s%dMHz%s' "${C_YELLOW}" "${_f}" "${C_RESET}"
    else
        printf '%s%dMHz%s' "${C_GRAY}" "${_f}" "${C_RESET}"
    fi
}

# 根据状态返回 ✓/✗ 带颜色
color_status() {
    case "$1" in
        on|1|true|yes|在线|enabled) printf '%s✓%s' "${C_BGREEN}" "${C_RESET}" ;;
        off|0|false|no|离线|disabled) printf '%s✗%s' "${C_BRED}" "${C_RESET}" ;;
        *) printf '%s?%s' "${C_YELLOW}" "${C_RESET}" ;;
    esac
}

# 档位名称上色
color_profile() {
    case "$1" in
        performance) printf '%s%s%s' "${C_BRED}" "$1" "${C_RESET}" ;;
        balance)     printf '%s%s%s' "${C_BBLUE}" "$1" "${C_RESET}" ;;
        powersave)   printf '%s%s%s' "${C_BGREEN}" "$1" "${C_RESET}" ;;
        game)        printf '%s%s%s' "${C_BMAGENTA}" "$1" "${C_RESET}" ;;
        *)           printf '%s%s%s' "${C_BYELLOW}" "$1" "${C_RESET}" ;;
    esac
}

# ============================================================================
# 日志系统（带颜色）
# ============================================================================

log_debug()   { [ "${LOG_LEVEL}" -ge 4 ] && echo "$(date '+%H:%M:%S') [DEBUG] $*" >> "${LOG_FILE}" 2>/dev/null; }
log_info()    { [ "${LOG_LEVEL}" -ge 3 ] && echo "$(date '+%H:%M:%S') [INFO ] $*" >> "${LOG_FILE}" 2>/dev/null; printf '%s[INFO]%s %s\n' "${C_CYAN}" "${C_RESET}" "$*"; }
log_warn()    { [ "${LOG_LEVEL}" -ge 2 ] && echo "$(date '+%H:%M:%S') [WARN ] $*" >> "${LOG_FILE}" 2>/dev/null; printf '%s[WARN]%s %s\n' "${C_YELLOW}${C_BOLD}" "${C_RESET}" "$*"; }
log_error()   { [ "${LOG_LEVEL}" -ge 1 ] && echo "$(date '+%H:%M:%S') [ERROR] $*" >> "${LOG_FILE}" 2>/dev/null; printf '%s[ERROR]%s %s\n' "${C_BRED}${C_BOLD}" "${C_RESET}" "$*" >&2; }
log_ok()      { [ "${LOG_LEVEL}" -ge 3 ] && echo "$(date '+%H:%M:%S') [OK   ] $*" >> "${LOG_FILE}" 2>/dev/null; printf '%s[ OK ]%s %s\n' "${C_BGREEN}${C_BOLD}" "${C_RESET}" "$*"; }

# 安全写文件（处理权限/路径不存在）
# 用法: write_sysfs <path> <value>
write_sysfs() {
    _path="$1"
    _val="$2"
    if [ -w "${_path}" ]; then
        echo "${_val}" > "${_path}" 2>/dev/null && return 0
        log_debug "写入失败: ${_path} <- ${_val}"
        return 1
    elif [ -e "${_path}" ]; then
        # 文件存在但不可写，尝试通过 su
        if command -v su >/dev/null 2>&1; then
            echo "${_val}" | su -c "cat > '${_path}'" 2>/dev/null && return 0
        fi
        log_debug "无写入权限: ${_path}"
        return 1
    else
        log_debug "路径不存在: ${_path}"
        return 1
    fi
}

# 安全读文件
# 用法: read_sysfs <path> [default]
read_sysfs() {
    if [ -r "$1" ]; then
        cat "$1" 2>/dev/null
    else
        printf '%s' "${2:-}"
    fi
}

# ============================================================================
# 配置加载
# ============================================================================

# 初始化日志/PID 目录：不可写时回退到临时目录
init_paths() {
    for _f in "${LOG_FILE}" "${PID_FILE}"; do
        _dir="$(dirname "${_f}")"
        if [ ! -d "${_dir}" ]; then
            mkdir -p "${_dir}" 2>/dev/null || {
                # 不可写，回退到 /tmp 或脚本目录
                _fallback="/tmp"
                [ -w "${SCRIPT_DIR}" ] && _fallback="${SCRIPT_DIR}"
                case "${_f}" in
                    "${LOG_FILE}") LOG_FILE="${_fallback}/performance-tuner.log" ;;
                    "${PID_FILE}") PID_FILE="${_fallback}/performance-tuner.pid" ;;
                esac
            }
        fi
    done
    [ -d "${BACKUP_DIR}" ] || mkdir -p "${BACKUP_DIR}" 2>/dev/null || BACKUP_DIR="/tmp/tuner-backup"
}

load_config() {
    if [ -f "${CONFIG_FILE}" ]; then
        log_info "加载配置: ${CONFIG_FILE}"
        # shellcheck disable=SC1090
        . "${CONFIG_FILE}"
    else
        log_warn "配置文件不存在，使用内置默认值: ${CONFIG_FILE}"
    fi
}

# ============================================================================
# 档位定义 (Profiles)
# ----------------------------------------------------------------------------
#  每个档位定义一组参数，apply_profile <name> 会应用对应配置。
#  自定义档位可在 tuner.conf 中扩展。
# ============================================================================

# 性能档：全核高频，性能调速器，关闭温控限制（仅提高阈值）
PROFILE_PERFORMANCE="
CPU_GOVERNOR=performance
CPU_MIN_FREQ_PCT=70
CPU_MAX_FREQ_PCT=100
CPU_ONLINE_ALL=1
GPU_GOVERNOR=performance
GPU_MIN_FREQ_PCT=80
GPU_MAX_FREQ_PCT=100
THERMAL_TEMP_LIMIT=85
THERMAL_THROTTLE_ENABLE=1
SCREEN_SAMPLING_RATE=240
SCREEN_REFRESH_RATE=120
SCHEDUTIL_RATE_LIMIT_US=1000
"

# 均衡档：日常使用，动态响应
PROFILE_BALANCE="
CPU_GOVERNOR=schedutil
CPU_MIN_FREQ_PCT=30
CPU_MAX_FREQ_PCT=100
CPU_ONLINE_ALL=1
GPU_GOVERNOR=msm-adreno-tz
GPU_MIN_FREQ_PCT=20
GPU_MAX_FREQ_PCT=90
THERMAL_TEMP_LIMIT=75
THERMAL_THROTTLE_ENABLE=1
SCREEN_SAMPLING_RATE=160
SCREEN_REFRESH_RATE=90
SCHEDUTIL_RATE_LIMIT_US=5000
"

# 省电档：低频省电，减少在线核心
PROFILE_POWERSAVE="
CPU_GOVERNOR=powersave
CPU_MIN_FREQ_PCT=0
CPU_MAX_FREQ_PCT=60
CPU_ONLINE_ALL=0
GPU_GOVERNOR=powersave
GPU_MIN_FREQ_PCT=0
GPU_MAX_FREQ_PCT=50
THERMAL_TEMP_LIMIT=65
THERMAL_THROTTLE_ENABLE=1
SCREEN_SAMPLING_RATE=120
SCREEN_REFRESH_RATE=60
SCHEDUTIL_RATE_LIMIT_US=10000
"

# 游戏档：类似性能但保留温控保护
PROFILE_GAME="
CPU_GOVERNOR=performance
CPU_MIN_FREQ_PCT=60
CPU_MAX_FREQ_PCT=100
CPU_ONLINE_ALL=1
GPU_GOVERNOR=performance
GPU_MIN_FREQ_PCT=70
GPU_MAX_FREQ_PCT=100
THERMAL_TEMP_LIMIT=80
THERMAL_THROTTLE_ENABLE=1
SCREEN_SAMPLING_RATE=240
SCREEN_REFRESH_RATE=120
SCHEDUTIL_RATE_LIMIT_US=1000
"

# 应用档位：解析档位字符串并逐项应用
# 用法: apply_profile <profile_name>
apply_profile() {
    _profile_name="$1"
    case "${_profile_name}" in
        performance) _data="${PROFILE_PERFORMANCE}" ;;
        balance)     _data="${PROFILE_BALANCE}" ;;
        powersave)   _data="${PROFILE_POWERSAVE}" ;;
        game)        _data="${PROFILE_GAME}" ;;
        *)
            # 支持配置文件中自定义 PROFILE_<NAME>
            _var="PROFILE_$(echo "${_profile_name}" | tr '[:lower:]' '[:upper:]')"
            _data="$(eval echo "\"\$${_var}\"" 2>/dev/null)"
            if [ -z "${_data}" ]; then
                log_error "未知档位: ${_profile_name}"
                return 1
            fi
            ;;
    esac

    log_info "========== 应用档位: ${_profile_name} =========="
    CURRENT_PROFILE="${_profile_name}"

    # 解析档位变量到当前环境
    eval "${_data}"

    # 依次调用各模块
    [ "${ENABLE_GOVERNOR}" = "1" ] && set_governor
    [ "${ENABLE_CPU}"      = "1" ] && set_cpu_frequency
    [ "${ENABLE_GPU}"      = "1" ] && set_gpu_frequency
    [ "${ENABLE_SCREEN}"   = "1" ] && set_screen_sampling
    [ "${ENABLE_THERMAL}"  = "1" ] && set_thermal_control

    log_info "========== 档位应用完成: ${_profile_name} =========="
}

# ============================================================================
# 模块 1：CPU 频率设置
# ----------------------------------------------------------------------------
#  - 探测 CPU 拓扑（大小核/Prime核）
#  - 根据百分比设置 min/max freq
#  - 控制核心上下线
# ============================================================================

# 探测 CPU 拓扑
detect_cpu_topology() {
    TOTAL_CPUS=0
    CPU_CLUSTER_BIG=""
    CPU_CLUSTER_LITTLE=""
    CPU_CLUSTER_PRIME=""

    for _cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        [ -d "${_cpu}" ] || continue
        _idx="$(echo "${_cpu}" | grep -oE '[0-9]+$')"
        TOTAL_CPUS=$((_idx + 1))

        # 通过相关 cpu 获取集群信息
        _related="$(cat "${_cpu}/topology/thread_siblings_list" 2>/dev/null | head -1)"

        # 通过最大频率区分大小核
        _max_freq="$(cat "${_cpu}/cpufreq/cpuinfo_max_freq" 2>/dev/null || echo 0)"
        _max_freq="$((_max_freq / 1000))"  # kHz -> MHz

        if [ "${_max_freq}" -ge 2400 ] 2>/dev/null; then
            CPU_CLUSTER_PRIME="${CPU_CLUSTER_PRIME} ${_idx}"
        elif [ "${_max_freq}" -ge 1900 ] 2>/dev/null; then
            CPU_CLUSTER_BIG="${CPU_CLUSTER_BIG} ${_idx}"
        else
            CPU_CLUSTER_LITTLE="${CPU_CLUSTER_LITTLE} ${_idx}"
        fi
    done

    log_debug "CPU 拓扑: 总核心=${TOTAL_CPUS} Prime=[${CPU_CLUSTER_PRIME}] Big=[${CPU_CLUSTER_BIG}] Little=[${CPU_CLUSTER_LITTLE}]"
}

# 根据百分比计算目标频率
# 用法: calc_freq <cpu_idx> <percent>
calc_freq() {
    _cpu_idx="$1"
    _pct="$2"
    _fdir="/sys/devices/system/cpu/cpu${_cpu_idx}/cpufreq"
    _avail="$(cat "${_fdir}/scaling_available_frequencies" 2>/dev/null)"
    if [ -z "${_avail}" ]; then
        _min="$(cat "${_fdir}/cpuinfo_min_freq" 2>/dev/null || echo 0)"
        _max="$(cat "${_fdir}/cpuinfo_max_freq" 2>/dev/null || echo 0)"
        _target=$(( (_min + (_max - _min) * _pct / 100) ))
    else
        # 取可用频率列表中第 pct% 档位
        _count="$(echo "${_avail}" | wc -w)"
        _pos=$(( (_count * _pct / 100) ))
        [ "${_pos}" -ge "${_count}" ] && _pos=$((_count - 1))
        _target="$(echo "${_avail}" | tr ' ' '\n' | sed -n "$((_pos + 1))p")"
    fi
    echo "${_target}"
}

set_cpu_frequency() {
    log_info "[CPU] 设置 CPU 频率 (min=${CPU_MIN_FREQ_PCT}% max=${CPU_MAX_FREQ_PCT}%)"

    for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
        _fdir="/sys/devices/system/cpu/cpu${_idx}/cpufreq"
        [ -d "${_fdir}" ] || continue

        _min_target="$(calc_freq "${_idx}" "${CPU_MIN_FREQ_PCT}")"
        _max_target="$(calc_freq "${_idx}" "${CPU_MAX_FREQ_PCT}")"

        # 确保 min <= max
        [ "${_min_target}" -gt "${_max_target}" ] 2>/dev/null && _min_target="${_max_target}"

        write_sysfs "${_fdir}/scaling_min_freq" "${_min_target}"
        write_sysfs "${_fdir}/scaling_max_freq" "${_max_target}"

        log_debug "  cpu${_idx}: ${_min_target} ~ ${_max_target} kHz"
    done

    # 核心上下线控制（省电档位下关闭部分核心）
    if [ "${CPU_ONLINE_ALL:-1}" = "0" ]; then
        log_info "[CPU] 省电模式：离线部分大核"
        for _idx in ${CPU_CLUSTER_BIG}; do
            write_sysfs "/sys/devices/system/cpu/cpu${_idx}/online" "0"
        done
    else
        for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
            write_sysfs "/sys/devices/system/cpu/cpu${_idx}/online" "1"
        done
    fi
}

# ============================================================================
# 模块 2：GPU 频率设置
# ----------------------------------------------------------------------------
#  - 支持 Adreno (kgsl) 与 Mali (mali) 两种主流 GPU
#  - 根据百分比设置 min/max freq
# ============================================================================

detect_gpu_path() {
    GPU_PATH=""
    if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
        GPU_PATH="/sys/class/kgsl/kgsl-3d0"
        GPU_TYPE="adreno"
    elif [ -d "/sys/class/misc/mali0/device" ]; then
        GPU_PATH="/sys/class/misc/mali0/device"
        GPU_TYPE="mali"
    else
        # 尝试 devfreq 通用接口
        for _g in /sys/class/devfreq/*; do
            case "$(basename "${_g}")" in
                *gpu*|*3d*|*mali*) GPU_PATH="${_g}"; GPU_TYPE="devfreq"; break ;;
            esac
        done
    fi
    log_debug "GPU 路径: ${GPU_PATH} (类型: ${GPU_TYPE:-未知})"
}

set_gpu_frequency() {
    [ -n "${GPU_PATH}" ] || detect_gpu_path
    [ -n "${GPU_PATH}" ] || { log_warn "[GPU] 未找到 GPU 设备节点"; return 1; }

    log_info "[GPU] 设置 GPU 频率 (min=${GPU_MIN_FREQ_PCT}% max=${GPU_MAX_FREQ_PCT}%)"

    case "${GPU_TYPE}" in
        adreno)
            # Adreno 通过 devfreq/min_freq, devfreq/max_freq (单位 Hz)
            _avail="$(read_sysfs "${GPU_PATH}/devfreq/available_frequencies")"
            if [ -n "${_avail}" ]; then
                _count="$(echo "${_avail}" | wc -w)"
                _min_pos=$(( (_count * GPU_MIN_FREQ_PCT / 100) ))
                _max_pos=$(( (_count * GPU_MAX_FREQ_PCT / 100) ))
                [ "${_max_pos}" -ge "${_count}" ] && _max_pos=$((_count - 1))
                _min_f="$(echo "${_avail}" | tr ' ' '\n' | sed -n "$((_min_pos + 1))p")"
                _max_f="$(echo "${_avail}" | tr ' ' '\n' | sed -n "$((_max_pos + 1))p")"
            else
                _min_f="$(read_sysfs "${GPU_PATH}/min_clock_mhz" 0)"
                _max_f="$(read_sysfs "${GPU_PATH}/max_clock_mhz" 0)"
                _min_f=$(( _min_f * 1000000 ))
                _max_f=$(( _max_f * 1000000 ))
            fi
            write_sysfs "${GPU_PATH}/devfreq/min_freq" "${_min_f}"
            write_sysfs "${GPU_PATH}/devfreq/max_freq" "${_max_f}"
            write_sysfs "${GPU_PATH}/devfreq/governor" "${GPU_GOVERNOR}"
            write_sysfs "${GPU_PATH}/default_pwrlevel" "0" 2>/dev/null
            log_debug "  Adreno: ${_min_f} ~ ${_max_f} Hz, governor=${GPU_GOVERNOR}"
            ;;
        mali)
            # Mali: freq_table_min / freq_table_max
            _min_f="$(read_sysfs "${GPU_PATH}/min_freq" 0)"
            _max_f="$(read_sysfs "${GPU_PATH}/max_freq" 0)"
            _target_min=$(( _min_f + (_max_f - _min_f) * GPU_MIN_FREQ_PCT / 100 ))
            _target_max=$(( _min_f + (_max_f - _min_f) * GPU_MAX_FREQ_PCT / 100 ))
            write_sysfs "${GPU_PATH}/freq_table_min" "${_target_min}"
            write_sysfs "${GPU_PATH}/freq_table_max" "${_target_max}"
            log_debug "  Mali: ${_target_min} ~ ${_target_max}"
            ;;
        devfreq)
            _avail="$(read_sysfs "${GPU_PATH}/available_frequencies")"
            if [ -n "${_avail}" ]; then
                _count="$(echo "${_avail}" | wc -w)"
                _min_pos=$(( (_count * GPU_MIN_FREQ_PCT / 100) ))
                _max_pos=$(( (_count * GPU_MAX_FREQ_PCT / 100) ))
                [ "${_max_pos}" -ge "${_count}" ] && _max_pos=$((_count - 1))
                _min_f="$(echo "${_avail}" | tr ' ' '\n' | sed -n "$((_min_pos + 1))p")"
                _max_f="$(echo "${_avail}" | tr ' ' '\n' | sed -n "$((_max_pos + 1))p")"
                write_sysfs "${GPU_PATH}/min_freq" "${_min_f}"
                write_sysfs "${GPU_PATH}/max_freq" "${_max_f}"
                write_sysfs "${GPU_PATH}/governor" "${GPU_GOVERNOR}"
            fi
            log_debug "  DevFreq: ${_min_f:-?} ~ ${_max_f:-?}"
            ;;
    esac
}

# ============================================================================
# 模块 3：温控设置
# ----------------------------------------------------------------------------
#  - 设置温度阈值
#  - 配置冷却设备状态
#  - 动态热降频策略
# ============================================================================

set_thermal_control() {
    log_info "[温控] 设置温控策略 (阈值=${THERMAL_TEMP_LIMIT}°C 降频=${THERMAL_THROTTLE_ENABLE})"

    # 1. 配置 thermal_zone 的高级触发点（部分平台支持）
    for _tz in /sys/class/thermal/thermal_zone*; do
        [ -d "${_tz}" ] || continue
        _type="$(read_sysfs "${_tz}/type")"
        # 仅处理 cpu/gpu 相关温区
        case "${_type}" in
            *cpu*|*CPU*|*gpu*|*GPU*|*soc*|*SoC*)
                # 设置 trip_point 温度
                for _tp in "${_tz}"/trip_point_*_temp; do
                    [ -f "${_tp}" ] || continue
                    _tp_name="$(basename "${_tp}")"
                    case "${_tp_name}" in
                        trip_point_0_temp) write_sysfs "${_tp}" "${THERMAL_TEMP_LIMIT}000" ;;
                        trip_point_1_temp) write_sysfs "${_tp}" "$((THERMAL_TEMP_LIMIT + 5))000" ;;
                        trip_point_2_temp) write_sysfs "${_tp}" "$((THERMAL_TEMP_LIMIT + 10))000" ;;
                    esac
                done
                log_debug "  温区 ${_type}: trip 点已设置"
                ;;
        esac
    done

    # 2. 配置冷却设备最大状态（限制降频幅度）
    if [ "${THERMAL_THROTTLE_ENABLE}" = "1" ]; then
        for _cd in /sys/class/thermal/cooling_device*; do
            [ -d "${_cd}" ] || continue
            _cdtype="$(read_sysfs "${_cd}/type")"
            case "${_cdtype}" in
                *thermal-controller*|*cpufreq*|*devfreq*)
                    # 设置 max_state 为相对保守值（保留降频能力但不至于过度降频）
                    _cur_max="$(read_sysfs "${_cd}/max_state" 0)"
                    if [ "${_cur_max}" -gt 0 ] 2>/dev/null; then
                        _limited=$(( _cur_max * 80 / 100 ))
                        write_sysfs "${_cd}/cur_state" "0" 2>/dev/null
                    fi
                    ;;
            esac
        done
    fi

    # 3. 限制充电温度（部分平台支持）
    write_sysfs "/sys/class/power_supply/battery/battery_charging_enabled" "1" 2>/dev/null
    write_sysfs "/sys/class/qcom-battery/restricted_charging" "0" 2>/dev/null
}

# 动态温度检测：返回当前最高 CPU 温度（毫摄氏度）
get_max_temp() {
    _max=0
    for _tz in /sys/class/thermal/thermal_zone*; do
        [ -d "${_tz}" ] || continue
        _type="$(read_sysfs "${_tz}/type")"
        case "${_type}" in
            *cpu*|*CPU*|*soc*|*SoC*)
                _t="$(read_sysfs "${_tz}/temp" 0)"
                [ "${_t}" -gt "${_max}" ] 2>/dev/null && _max="${_t}"
                ;;
        esac
    done
    echo "${_max}"
}

# ============================================================================
# 模块 4：屏幕采样率设置
# ----------------------------------------------------------------------------
#  - 触摸采样率 (touch sampling rate)
#  - 屏幕刷新率 (refresh rate)
#  - 触摸灵敏度 / 按压阈值
# ============================================================================

set_screen_sampling() {
    log_info "[屏幕] 设置采样率=${SCREEN_SAMPLING_RATE}Hz 刷新率=${SCREEN_REFRESH_RATE}Hz"

    # ---- 触摸采样率 ----
    # 通用路径（不同厂商路径不同，逐一尝试）
    _touch_paths="
        /sys/class/input/event*/device/touch_sampling_rate
        /sys/class/input/event*/device/sampling_rate
        /sys/class/touchscreen/fts_ts/touch_firing_rate
        /sys/devices/virtual/input/input*/sampling_rate
        /sys/kernel/touchscreen/touch_sampling_rate
        /proc/touchscreen/sampling_rate
    "
    _applied=0
    for _pattern in ${_touch_paths}; do
        for _f in ${_pattern}; do
            if [ -w "${_f}" ]; then
                write_sysfs "${_f}" "${SCREEN_SAMPLING_RATE}"
                _applied=1
                log_debug "  采样率写入: ${_f} = ${SCREEN_SAMPLING_RATE}"
            fi
        done
    done

    # 高通平台：设置触摸报告率
    write_sysfs "/sys/devices/soc/soc:fingerprint/touch_boost" "1" 2>/dev/null

    # ---- 屏幕刷新率 ----
    # 通过 sf 切换（需要 surfaceflinger 支持）
    if command -v service >/dev/null 2>&1; then
        service call SurfaceFlinger 1035 i32 "${SCREEN_REFRESH_RATE}" 2>/dev/null
        log_debug "  刷新率设置: ${SCREEN_REFRESH_RATE}Hz (via SurfaceFlinger)"
    fi

    # 部分平台通过 sysfs 设置
    write_sysfs "/sys/class/drm/card0-DSI-1/refresh_rate" "${SCREEN_REFRESH_RATE}" 2>/dev/null
    write_sysfs "/sys/class/graphics/fb0/dynamic_fps" "${SCREEN_REFRESH_RATE}" 2>/dev/null

    # ---- 触摸灵敏度 / 按压阈值 ----
    for _f in /sys/class/input/event*/device/sensitivity \
              /sys/class/input/event*/device/press_threshold; do
        [ -w "${_f}" ] && write_sysfs "${_f}" "100" 2>/dev/null
    done

    [ "${_applied}" = "0" ] && log_warn "[屏幕] 未能写入采样率（设备路径不支持）"
}

# ============================================================================
# 模块 5：调速器设置
# ----------------------------------------------------------------------------
#  - 选择 CPU/GPU governor
#  - 配置调速器可调参数 (tunables)
#  - 支持 schedutil / interactive / ondemand / performance 等
# ============================================================================

set_governor() {
    log_info "[调速器] 设置 CPU governor=${CPU_GOVERNOR}"

    for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
        _gpath="/sys/devices/system/cpu/cpu${_idx}/cpufreq"
        [ -d "${_gpath}" ] || continue

        # 检查 governor 是否可用
        _avail_gov="$(read_sysfs "${_gpath}/scaling_available_governors")"
        if echo "${_avail_gov}" | grep -qw "${CPU_GOVERNOR}"; then
            write_sysfs "${_gpath}/scaling_governor" "${CPU_GOVERNOR}"
        else
            # 回退到 schedutil 或 ondemand
            for _fallback in schedutil ondemand interactive; do
                if echo "${_avail_gov}" | grep -qw "${_fallback}"; then
                    write_sysfs "${_gpath}/scaling_governor" "${_fallback}"
                    log_debug "  cpu${_idx}: ${CPU_GOVERNOR} 不可用，回退到 ${_fallback}"
                    break
                fi
            done
        fi
    done

    # 配置调速器参数
    tune_governor_params
}

# 调速器参数调优
tune_governor_params() {
    case "${CPU_GOVERNOR}" in
        schedutil)
            _rate_limit="${SCHEDUTIL_RATE_LIMIT_US:-5000}"
            for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
                _tpath="/sys/devices/system/cpu/cpu${_idx}/cpufreq/schedutil"
                [ -d "${_tpath}" ] || continue
                write_sysfs "${_tpath}/rate_limit_us" "${_rate_limit}"
                write_sysfs "${_tpath}/up_rate_limit_us" "${_rate_limit}" 2>/dev/null
                write_sysfs "${_tpath}/down_rate_limit_us" "${_rate_limit}" 2>/dev/null
            done
            log_debug "  schedutil: rate_limit_us=${_rate_limit}"
            ;;
        interactive)
            for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
                _tpath="/sys/devices/system/cpu/cpufreq/interactive"
                [ -d "${_tpath}" ] || continue
                write_sysfs "${_tpath}/timer_rate" "20000"
                write_sysfs "${_tpath}/min_sample_time" "40000"
                write_sysfs "${_tpath}/hispeed_freq" "0"
                write_sysfs "${_tpath}/go_hispeed_load" "99"
                write_sysfs "${_tpath}/target_loads" "85"
            done
            log_debug "  interactive: 已调优"
            ;;
        ondemand)
            for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
                _tpath="/sys/devices/system/cpu/cpufreq/ondemand"
                [ -d "${_tpath}" ] || continue
                write_sysfs "${_tpath}/sampling_rate" "20000"
                write_sysfs "${_tpath}/up_threshold" "85"
                write_sysfs "${_tpath}/io_is_busy" "1"
                write_sysfs "${_tpath}/powersave_bias" "0"
            done
            log_debug "  ondemand: 已调优"
            ;;
    esac
}

# ============================================================================
# 模块 6：动态自适应调度
# ----------------------------------------------------------------------------
#  守护循环中根据温度/负载动态切换档位：
#    - 温度过高 → 降级到 powersave
#    - 温度回落 → 恢复用户档位
# ============================================================================

# 全局：动态调度前的用户目标档位
USER_TARGET_PROFILE="balance"
DYNAMIC_DOWNGRADED=0

# 动态调度检查（每次循环调用）
dynamic_schedule_check() {
    [ "${ENABLE_DYNAMIC}" = "1" ] || return 0

    _temp="$(get_max_temp)"
    _temp_c=$((_temp / 1000))

    if [ "${DYNAMIC_DOWNGRADED}" = "0" ]; then
        # 正常态：检查是否需要降级
        if [ "${_temp_c}" -ge "${THERMAL_TEMP_LIMIT:-75}" ] 2>/dev/null; then
            log_warn "[动态] 温度过高 ${_temp_c}°C，降级到省电档"
            DYNAMIC_DOWNGRADED=1
            # 直接应用 powersave 的关键参数（不改变 USER_TARGET_PROFILE）
            _saved_dynamic="${ENABLE_DYNAMIC}"
            ENABLE_DYNAMIC=0
            apply_profile powersave
            ENABLE_DYNAMIC="${_saved_dynamic}"
        fi
    else
        # 降级态：检查是否可恢复
        _recover_threshold=$(( THERMAL_TEMP_LIMIT - 10 ))
        if [ "${_temp_c}" -lt "${_recover_threshold}" ] 2>/dev/null; then
            log_info "[动态] 温度恢复 ${_temp_c}°C，恢复用户档位 ${USER_TARGET_PROFILE}"
            DYNAMIC_DOWNGRADED=0
            _saved_dynamic="${ENABLE_DYNAMIC}"
            ENABLE_DYNAMIC=0
            apply_profile "${USER_TARGET_PROFILE}"
            ENABLE_DYNAMIC="${_saved_dynamic}"
        fi
    fi
}

# ============================================================================
# 备份与恢复
# ============================================================================

backup_settings() {
    mkdir -p "${BACKUP_DIR}"
    : > "${BACKUP_DIR}/cpu_backup.txt"
    for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
        _gpath="/sys/devices/system/cpu/cpu${_idx}/cpufreq"
        [ -d "${_gpath}" ] || continue
        {
            echo "cpu${_idx}_min=$(read_sysfs "${_gpath}/scaling_min_freq")"
            echo "cpu${_idx}_max=$(read_sysfs "${_gpath}/scaling_max_freq")"
            echo "cpu${_idx}_gov=$(read_sysfs "${_gpath}/scaling_governor")"
            echo "cpu${_idx}_online=$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/online" 1)"
        } >> "${BACKUP_DIR}/cpu_backup.txt"
    done
    log_info "已备份当前设置到 ${BACKUP_DIR}"
}

restore_settings() {
    [ -f "${BACKUP_DIR}/cpu_backup.txt" ] || { log_warn "无备份可恢复"; return 0; }
    log_info "恢复原始设置..."
    while IFS='=' read -r _key _val; do
        [ -n "${_key}" ] || continue
        case "${_key}" in
            cpu*_min)    write_sysfs "/sys/devices/system/cpu/${_key%_min}/cpufreq/scaling_min_freq" "${_val}" ;;
            cpu*_max)    write_sysfs "/sys/devices/system/cpu/${_key%_max}/cpufreq/scaling_max_freq" "${_val}" ;;
            cpu*_gov)    write_sysfs "/sys/devices/system/cpu/${_key%_gov}/cpufreq/scaling_governor" "${_val}" ;;
            cpu*_online) write_sysfs "/sys/devices/system/cpu/${_key%_online}/online" "${_val}" ;;
        esac
    done < "${BACKUP_DIR}/cpu_backup.txt"
    log_info "原始设置已恢复"
}

# ============================================================================
# 守护进程主循环
# ============================================================================

daemon_loop() {
    log_info "守护进程启动 (间隔=${SCHEDULE_INTERVAL}s, 目标档位=${USER_TARGET_PROFILE})"

    # 立即应用一次目标档位
    apply_profile "${USER_TARGET_PROFILE}"

    while true; do
        sleep "${SCHEDULE_INTERVAL}"
        dynamic_schedule_check
        log_debug "心跳: profile=${CURRENT_PROFILE} temp=$(get_max_temp)mC downgrade=${DYNAMIC_DOWNGRADED}"
    done
}

# ============================================================================
# 状态查询
# ============================================================================

show_status() {
    printf '%b========================================%b\n' "${C_CYAN}" "${C_RESET}"
    printf '  %bPerformance Tuner v%s  状态%b\n' "${C_BOLD}${C_BCYAN}" "${VERSION}" "${C_RESET}"
    printf '%b========================================%b\n' "${C_CYAN}" "${C_RESET}"
    printf '  当前档位      : %s\n' "$(color_profile "${CURRENT_PROFILE}")"
    printf '  用户目标档位  : %s\n' "$(color_profile "${USER_TARGET_PROFILE}")"
    if [ "${DYNAMIC_DOWNGRADED}" = "1" ]; then
        printf '  动态降级中    : %b是 ⚠%b\n' "${C_BRED}${C_BOLD}" "${C_RESET}"
    else
        printf '  动态降级中    : %b否%b\n' "${C_BGREEN}" "${C_RESET}"
    fi
    printf '  调度间隔      : %b%s%bs\n' "${C_YELLOW}" "${SCHEDULE_INTERVAL}" "${C_RESET}"
    printf '  日志文件      : %b%s%b\n' "${C_GRAY}" "${LOG_FILE}" "${C_RESET}"
    printf '  PID 文件      : %b%s%b\n' "${C_GRAY}" "${PID_FILE}" "${C_RESET}"
    printf '\n'
    printf '  %b---- 模块开关 ----%b\n' "${C_BOLD}${C_BLUE}" "${C_RESET}"
    printf '  CPU 频率   : %s\n' "$(color_status "${ENABLE_CPU}")"
    printf '  GPU 频率   : %s\n' "$(color_status "${ENABLE_GPU}")"
    printf '  温控       : %s\n' "$(color_status "${ENABLE_THERMAL}")"
    printf '  屏幕采样   : %s\n' "$(color_status "${ENABLE_SCREEN}")"
    printf '  调速器     : %s\n' "$(color_status "${ENABLE_GOVERNOR}")"
    printf '  动态调度   : %s\n' "$(color_status "${ENABLE_DYNAMIC}")"
    printf '\n'
    printf '  %b---- CPU 拓扑 ----%b\n' "${C_BOLD}${C_BLUE}" "${C_RESET}"
    printf '  总核心     : %b%d%b\n' "${C_BCYAN}" "${TOTAL_CPUS}" "${C_RESET}"
    printf '  Prime 核   : %b[%s]%b\n' "${C_BMAGENTA}" "${CPU_CLUSTER_PRIME}" "${C_RESET}"
    printf '  Big 核     : %b[%s]%b\n' "${C_BRED}" "${CPU_CLUSTER_BIG}" "${C_RESET}"
    printf '  Little 核  : %b[%s]%b\n' "${C_BGREEN}" "${CPU_CLUSTER_LITTLE}" "${C_RESET}"
    printf '\n'
    printf '  %b---- 实时数据 ----%b\n' "${C_BOLD}${C_BLUE}" "${C_RESET}"
    _t="$(get_max_temp)"
    printf '  最高 CPU 温度: '
    color_temp "${_t}"
    printf '\n'
    printf '\n'
    printf '  %b---- 各核心频率 ----%b\n' "${C_BOLD}${C_BLUE}" "${C_RESET}"
    for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
        _cur="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/cpufreq/scaling_cur_freq" 0)"
        _maxf="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/cpufreq/cpuinfo_max_freq" 1)"
        _gov="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/cpufreq/scaling_governor" "-")"
        _online="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/online" 1)"
        _cur_mhz=$((_cur / 1000))
        _max_mhz=$((_maxf / 1000))
        printf '  cpu%-2s [%s] ' "${_idx}" "$( [ "${_online}" = "1" ] && color_green '在线' || color_red '离线')"
        color_freq "${_cur_mhz}" "${_max_mhz}"
        printf ' gov=%b%s%b\n' "${C_MAGENTA}" "${_gov}" "${C_RESET}"
    done
    printf '%b========================================%b\n' "${C_CYAN}" "${C_RESET}"
}

# ============================================================================
# 实时监控模式
# ============================================================================

# 获取系统负载（/proc/loadavg）
get_loadavg() {
    if [ -r /proc/loadavg ]; then
        awk '{print $1}' /proc/loadavg 2>/dev/null
    else
        echo "0.00"
    fi
}

# 获取内存使用情况
get_mem_usage() {
    if [ -r /proc/meminfo ]; then
        _total=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null)
        _avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo 2>/dev/null)
        if [ -n "${_total}" ] && [ -n "${_avail}" ] && [ "${_total}" -gt 0 ] 2>/dev/null; then
            _used=$(( _total - _avail ))
            _pct=$(( _used * 100 / _total ))
            printf '%dM / %dM (%d%%)' $(( _used / 1024 )) $(( _total / 1024 )) "${_pct}"
            return
        fi
    fi
    printf 'N/A'
}

# 根据 loadavg 上色
color_loadavg() {
    _l="${1:-0}"
    _li=$(echo "${_l}" | awk '{printf "%d", $1 * 100}')
    if [ "${_li}" -ge 200 ] 2>/dev/null; then
        printf '%s%s%s' "${C_BRED}${C_BOLD}" "${_l}" "${C_RESET}"
    elif [ "${_li}" -ge 100 ] 2>/dev/null; then
        printf '%s%s%s' "${C_BYELLOW}" "${_l}" "${C_RESET}"
    else
        printf '%s%s%s' "${C_BGREEN}" "${_l}" "${C_RESET}"
    fi
}

# 根据 CPU 频率生成进度条
cpu_freq_bar() {
    _cur="${1:-0}"
    _max="${2:-1}"
    [ "${_max}" -le 0 ] 2>/dev/null && _max=1
    _pct=$(( _cur * 100 / _max ))
    _filled=$(( _pct / 5 ))
    _empty=$(( 20 - _filled ))
    _bar=""
    _i=0
    while [ "${_i}" -lt "${_filled}" ]; do _bar="${_bar}█"; _i=$((_i + 1)); done
    _i=0
    while [ "${_i}" -lt "${_empty}" ]; do _bar="${_bar}░"; _i=$((_i + 1)); done
    if [ "${_pct}" -ge 80 ] 2>/dev/null; then
        printf '%s%s%s %3d%%' "${C_BGREEN}" "${_bar}" "${C_RESET}" "${_pct}"
    elif [ "${_pct}" -ge 50 ] 2>/dev/null; then
        printf '%s%s%s %3d%%' "${C_BCYAN}" "${_bar}" "${C_RESET}" "${_pct}"
    elif [ "${_pct}" -ge 20 ] 2>/dev/null; then
        printf '%s%s%s %3d%%' "${C_YELLOW}" "${_bar}" "${C_RESET}" "${_pct}"
    else
        printf '%s%s%s %3d%%' "${C_GRAY}" "${_bar}" "${C_RESET}" "${_pct}"
    fi
}

# 实时监控模式（每秒刷新，带颜色 + 进度条 + 系统负载）
monitor_mode() {
    # 强制启用颜色（监控模式必须有颜色）
    FORCE_COLOR=1
    init_colors

    # 捕捉 Ctrl+C 优雅退出
    trap 'printf "\n%b退出监控%b\n" "${C_YELLOW}" "${C_RESET}"; tput cnorm 2>/dev/null; exit 0' INT TERM
    # 隐藏光标（如终端支持）
    tput civis 2>/dev/null

    _update=0
    while true; do
        _update=$((_update + 1))
        # 移动光标到屏幕顶端而非 clear，减少闪烁
        printf '\033[H\033[2J'

        # ---- 标题栏 ----
        printf '%b╔══════════════════════════════════════════════════════════════╗%b\n' "${C_BCYAN}" "${C_RESET}"
        printf '%b║%b %bPerformance Tuner v%s  实时监控%b %b%52s%b %b║%b\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BOLD}${C_WHITE}" "${VERSION}" "${C_RESET}" \
            "${C_GRAY}" "$(date '+%Y-%m-%d %H:%M:%S')" "${C_RESET}" \
            "${C_BCYAN}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        # ---- 系统概览 ----
        _t="$(get_max_temp)"
        _t_c=$((_t / 1000))
        _load="$(get_loadavg)"
        _mem="$(get_mem_usage)"

        # 温度告警图标
        if [ "${_t_c}" -ge 80 ] 2>/dev/null; then
            _icon="🔥"
        elif [ "${_t_c}" -ge 70 ] 2>/dev/null; then
            _icon="⚠️ "
        elif [ "${_t_c}" -ge 50 ] 2>/dev/null; then
            _icon="🌡️ "
        else
            _icon="❄️ "
        fi

        printf '%b║%b 当前档位  : %-12s 动态降级: %-8s               %b║%b\n' \
            "${C_BCYAN}" "${C_RESET}" \
            "$(color_profile "${CURRENT_PROFILE}")" \
            "$( [ "${DYNAMIC_DOWNGRADED}" = "1" ] && color_red '是⚠' || color_green '否')" \
            "${C_BCYAN}" "${C_RESET}"
        printf '%b║%b 最高温度  : %s %s   负载: %s   刷新: #%d\n' \
            "${C_BCYAN}" "${C_RESET}" "${_icon}" "$(color_temp "${_t}")" \
            "$(color_loadavg "${_load}")" "${_update}"
        printf '%b║%b 内存使用  : %b%s%b\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${_mem}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        # ---- 表头 ----
        printf '%b║%b %-4s %-6s %-22s %-12s %-10s %b║%b\n' \
            "${C_BCYAN}" "${C_RESET}" \
            "${C_BOLD}CPU${C_RESET}" "${C_BOLD}状态${C_RESET}" "${C_BOLD}频率进度条${C_RESET}" "${C_BOLD}调速器${C_RESET}" "${C_BOLD}Max${C_RESET}" \
            "${C_BCYAN}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        # ---- 各核心实时数据 ----
        for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
            _cur="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/cpufreq/scaling_cur_freq" 0)"
            _maxf="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/cpufreq/cpuinfo_max_freq" 1)"
            _gov="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/cpufreq/scaling_governor" "-")"
            _online="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/online" 1)"

            _cur_mhz=$((_cur / 1000))
            _max_mhz=$((_maxf / 1000))

            _state="$( [ "${_online}" = "1" ] && color_green '在线' || color_red '离线')"
            _bar="$(cpu_freq_bar "${_cur_mhz}" "${_max_mhz}")"

            printf '%b║%b %-4s %-6s %-22s %-12s %-10s %b║%b\n' \
                "${C_BCYAN}" "${C_RESET}" \
                "$(color_bold "cpu${_idx}")" "${_state}" "${_bar}" \
                "$(color_magenta "${_gov}")" "${_max_mhz}MHz" \
                "${C_BCYAN}" "${C_RESET}"
        done

        # ---- GPU 信息 ----
        if [ -n "${GPU_PATH:-}" ] && [ -d "${GPU_PATH:-}" ]; then
            printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"
            _gpu_cur="$(read_sysfs "${GPU_PATH}/devfreq/cur_freq" 0)"
            _gpu_max="$(read_sysfs "${GPU_PATH}/devfreq/max_freq" 1)"
            _gpu_gov="$(read_sysfs "${GPU_PATH}/devfreq/governor" "-")"
            _gpu_cur_mhz=$((_gpu_cur / 1000000))
            _gpu_max_mhz=$((_gpu_max / 1000000))
            printf '%b║%b %bGPU%b  %-6s %-22s %-12s %-10s %b║%b\n' \
                "${C_BCYAN}" "${C_RESET}" \
                "${C_BOLD}${C_BMAGENTA}" "${C_RESET}" \
                "$(color_status on)" \
                "$(cpu_freq_bar "${_gpu_cur_mhz}" "${_gpu_max_mhz}")" \
                "$(color_magenta "${_gpu_gov}")" \
                "${_gpu_max_mhz}MHz" \
                "${C_BCYAN}" "${C_RESET}"
        fi

        printf '%b╚══════════════════════════════════════════════════════════════╝%b\n' "${C_BCYAN}" "${C_RESET}"
        printf '%b  每 1s 刷新 · Ctrl+C 退出 · 实时读取 /sys/class/thermal 与 /sys/devices/system/cpu%b\n' "${C_GRAY}" "${C_RESET}"

        sleep 1
    done
}

# ============================================================================
# 进程管理
# ============================================================================

is_running() {
    [ -f "${PID_FILE}" ] || return 1
    _pid="$(cat "${PID_FILE}" 2>/dev/null)"
    [ -n "${_pid}" ] && kill -0 "${_pid}" 2>/dev/null
}

start_daemon() {
    if is_running; then
        log_warn "守护进程已在运行 (PID=$(cat "${PID_FILE}"))"
        return 0
    fi
    log_info "启动守护进程..."
    # 后台运行
    RUN_MODE="daemon"
    nohup "$0" _daemon_internal "${USER_TARGET_PROFILE}" >> "${LOG_FILE}" 2>&1 &
    _newpid=$!
    echo "${_newpid}" > "${PID_FILE}"
    sleep 1
    if is_running; then
        log_info "守护进程已启动 (PID=${_newpid})"
    else
        log_error "守护进程启动失败，查看日志: ${LOG_FILE}"
        return 1
    fi
}

stop_daemon() {
    if is_running; then
        _pid="$(cat "${PID_FILE}")"
        log_info "停止守护进程 (PID=${_pid})..."
        kill "${_pid}" 2>/dev/null
        sleep 1
        kill -9 "${_pid}" 2>/dev/null
        rm -f "${PID_FILE}"
        restore_settings
        log_info "守护进程已停止"
    else
        log_info "守护进程未运行"
        rm -f "${PID_FILE}"
    fi
}

# 内部入口：守护进程实际执行
_daemon_internal() {
    USER_TARGET_PROFILE="$1"
    trap 'log_info "收到终止信号，退出守护"; restore_settings; rm -f "${PID_FILE}"; exit 0' INT TERM
    daemon_loop
}

# ============================================================================
# 帮助信息
# ============================================================================

show_help() {
    cat <<EOF
${C_BCYAN}╔══════════════════════════════════════════════════════════════╗${C_RESET}
${C_BCYAN}║${C_RESET}  ${C_BOLD}${C_WHITE}Performance Tuner v${VERSION}  使用说明${C_RESET}                                ${C_BCYAN}║${C_RESET}
${C_BCYAN}╚══════════════════════════════════════════════════════════════╝${C_RESET}

${C_BOLD}用法:${C_RESET}
  ${C_YELLOW}./performance-tuner.sh${C_RESET} ${C_CYAN}<命令>${C_RESET} ${C_GRAY}[参数]${C_RESET}

${C_BOLD}命令:${C_RESET}
  ${C_BGREEN}(无参数)${C_RESET}              ${C_BOLD}进入交互式菜单${C_RESET}（推荐！自己选择要调整的项目）
  ${C_BGREEN}menu${C_RESET}                  进入交互式菜单（同上）
  ${C_BGREEN}start${C_RESET}                  启动后台守护进程（动态调度）
  ${C_BRED}stop${C_RESET}                   停止守护进程并恢复原设置
  ${C_BYELLOW}restart${C_RESET}                重启守护进程
  ${C_BCYAN}status${C_RESET}                 查看当前状态与各核心信息（带颜色）
  ${C_BMAGENTA}monitor${C_RESET}                实时监控温度/频率/负载（每秒刷新）
  ${C_BBLUE}apply${C_RESET} ${C_CYAN}<档位>${C_RESET}           立即应用指定档位（一次性）
    ${C_BOLD}可用档位:${C_RESET}
      ${C_BRED}performance${C_RESET}  - 性能模式（全核高频）
      ${C_BBLUE}balance${C_RESET}      - 均衡模式（日常推荐）
      ${C_BGREEN}powersave${C_RESET}    - 省电模式（降频省电）
      ${C_BMAGENTA}game${C_RESET}         - 游戏模式（性能+温控保护）
  ${C_BYELLOW}reload${C_RESET}                 重新加载配置文件
  ${C_GRAY}backup${C_RESET}                 备份当前系统设置
  ${C_GRAY}restore${C_RESET}                恢复备份的系统设置
  ${C_GRAY}help${C_RESET}                   显示此帮助信息

${C_BOLD}交互式菜单:${C_RESET}
  ${C_GRAY}运行 ./performance-tuner.sh 直接进入菜单${C_RESET}
  ${C_GRAY}菜单中可自由调整：${C_RESET}
    ${C_BGREEN}[1]${C_RESET} CPU 频率设置      - 调整 min/max 百分比、核心上下线
    ${C_BMAGENTA}[2]${C_RESET} GPU 频率设置      - 调整 min/max 百分比、选择 GPU 调速器
    ${C_BYELLOW}[3]${C_RESET} 温控设置          - 设置温度阈值、切换热降频
    ${C_BBLUE}[4]${C_RESET} 屏幕采样率设置      - 选择触摸采样率、屏幕刷新率
    ${C_BCYAN}[5]${C_RESET} 调速器设置          - 选择 CPU governor、调整 schedutil 参数
    ${C_BGREEN}[6]${C_RESET} 一键预设档位      - performance/balance/powersave/game
    ${C_BMAGENTA}[7]${C_RESET} 实时监控          - 彩色 + 进度条
    ${C_BCYAN}[8]${C_RESET} 查看当前完整状态
    ${C_BYELLOW}[9]${C_RESET} 保存当前设置为配置文件（可选导出）
    ${C_BGREEN}[s]${C_RESET} 一键应用当前所有设置到系统

${C_BOLD}配置文件 (可选):${C_RESET}
  ${C_CYAN}tuner.conf${C_RESET}             与脚本同目录，定义模块开关与档位参数
  ${C_GRAY}注: 不需要预先写配置文件，菜单里调整后即可立即生效${C_RESET}
  ${C_GRAY}    菜单选项 [9] 可将当前调整保存为自定义配置${C_RESET}

${C_BOLD}示例:${C_RESET}
  ${C_GRAY}# 进入交互式菜单（推荐）${C_RESET}
  ${C_YELLOW}./performance-tuner.sh${C_RESET}

  ${C_GRAY}# 立即切换到性能档${C_RESET}
  ${C_YELLOW}./performance-tuner.sh${C_RESET} ${C_BBLUE}apply${C_RESET} ${C_BRED}performance${C_RESET}

  ${C_GRAY}# 启动守护进程（默认均衡档，温度过高自动降级）${C_RESET}
  ${C_YELLOW}./performance-tuner.sh${C_RESET} ${C_BGREEN}start${C_RESET}

  ${C_GRAY}# 实时监控（彩色 + 进度条 + 温度告警）${C_RESET}
  ${C_YELLOW}./performance-tuner.sh${C_RESET} ${C_BMAGENTA}monitor${C_RESET}

${C_BOLD}环境变量:${C_RESET}
  ${C_GRAY}NO_COLOR=1${C_RESET}           禁用彩色输出
  ${C_GRAY}FORCE_COLOR=1${C_RESET}        强制启用彩色（非 TTY 时）
  ${C_GRAY}LOG_LEVEL=4${C_RESET}          设置日志级别（0-4，4=最详细）

EOF
}

# ============================================================================
# 交互式菜单系统 (Interactive TUI Menu System)
# ----------------------------------------------------------------------------
#  设计目标：
#    - 用户运行脚本无参数时直接进入菜单
#    - 所有调整即时生效（无需预写配置文件）
#    - 每个子菜单显示当前值，用户选择修改后才应用到系统
#    - 支持「保存当前设置为配置文件」作为可选导出
# ============================================================================

# 当前用户调整中的参数（菜单修改这些变量，然后调用 set_* 应用）
menu_cpu_min_pct=30
menu_cpu_max_pct=100
menu_cpu_online_all=1
menu_gpu_min_pct=20
menu_gpu_max_pct=90
menu_gpu_governor="msm-adreno-tz"
menu_thermal_limit=75
menu_thermal_throttle=1
menu_screen_sampling=160
menu_screen_refresh=90
menu_cpu_governor="schedutil"
menu_schedutil_rate=5000

# 读取用户输入（带提示，返回值放入全局 MENU_INPUT）
MENU_INPUT=""
menu_read() {
    MENU_INPUT=""
    printf '%s' "$*"
    read -r MENU_INPUT 2>/dev/null || MENU_INPUT=""
}

# 暂停等待回车
menu_pause() {
    printf '\n%s按回车键继续...%s' "${C_DIM}" "${C_RESET}"
    read -r _ 2>/dev/null
}

# 清屏
menu_clear() {
    printf '\033[H\033[2J'
}

# 画分割线
# 用法: menu_line <char> <color>
menu_line() {
    _char="${1:--}"
    _color="${2:-${C_CYAN}}"
    printf '%s' "${_color}"
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60; do
        printf '%s' "${_char}"
    done
    printf '%s\n' "${C_RESET}"
}

# 菜单状态栏：实时显示当前系统状态
menu_status_bar() {
    _t="$(get_max_temp)"
    _t_c=$((_t / 1000))
    _cur0="$(read_sysfs "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq" 0)"
    _cur0_mhz=$((_cur0 / 1000))
    _gov0="$(read_sysfs "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" "-")"

    # 温度告警图标
    if [ "${_t_c}" -ge 80 ] 2>/dev/null; then _icon="🔥"
    elif [ "${_t_c}" -ge 70 ] 2>/dev/null; then _icon="⚠️ "
    elif [ "${_t_c}" -ge 50 ] 2>/dev/null; then _icon="🌡️ "
    else _icon="❄️ "; fi

    printf '%b║%b 状态: ' "${C_BCYAN}" "${C_RESET}"
    printf '档位=%s ' "$(color_profile "${CURRENT_PROFILE}")"
    printf '温度=%s%s ' "${_icon}" "$(color_temp "${_t}")"
    printf 'CPU0=%s ' "$(color_freq "${_cur0_mhz}" 3000)"
    printf 'governor=%b%s%b' "${C_MAGENTA}" "${_gov0}" "${C_RESET}"
    # 补齐空格到边框宽度
    printf '                            %b║%b\n' "${C_BCYAN}" "${C_RESET}"
}

# ============================================================================
# 子菜单 1：CPU 频率设置
# ============================================================================
menu_cpu_freq() {
    while true; do
        menu_clear
        printf '%b╔══════════════════════════════════════════════════════════════╗%b\n' "${C_BCYAN}" "${C_RESET}"
        printf '%b║%b  %bCPU 频率设置%b                                              %b║%b\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BOLD}${C_BGREEN}" "${C_RESET}" "${C_BCYAN}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        # CPU 拓扑
        printf '%b║%b CPU 拓扑: %d 核' "${C_BCYAN}" "${C_RESET}" "${TOTAL_CPUS}"
        [ -n "${CPU_CLUSTER_PRIME}" ] && printf '  Prime=[%s]' "${C_BMAGENTA}${CPU_CLUSTER_PRIME}${C_RESET}"
        [ -n "${CPU_CLUSTER_BIG}" ] && printf '  Big=[%s]' "${C_BRED}${CPU_CLUSTER_BIG}${C_RESET}"
        [ -n "${CPU_CLUSTER_LITTLE}" ] && printf '  Little=[%s]' "${C_BGREEN}${CPU_CLUSTER_LITTLE}${C_RESET}"
        printf '\n'
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        # 当前调整中的值
        printf '%b║%b %b当前设置:%b\n' "${C_BCYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
        printf '%b║%b   最低频率: %b%d%%%b\n' "${C_BCYAN}" "${C_RESET}" "${C_BGREEN}" "${menu_cpu_min_pct}" "${C_RESET}"
        printf '%b║%b   最高频率: %b%d%%%b\n' "${C_BCYAN}" "${C_RESET}" "${C_BRED}" "${menu_cpu_max_pct}" "${C_RESET}"
        if [ "${menu_cpu_online_all}" = "1" ]; then
            printf '%b║%b   在线核心: %b全部在线%b\n' "${C_BCYAN}" "${C_RESET}" "${C_BGREEN}" "${C_RESET}"
        else
            printf '%b║%b   在线核心: %b部分大核离线（省电）%b\n' "${C_BCYAN}" "${C_RESET}" "${C_BYELLOW}" "${C_RESET}"
        fi
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        printf '%b║%b  %b[1]%b 调整最低频率百分比   (当前 %d%%)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${menu_cpu_min_pct}"
        printf '%b║%b  %b[2]%b 调整最高频率百分比   (当前 %d%%)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${menu_cpu_max_pct}"
        printf '%b║%b  %b[3]%b 切换大核上下线       (当前 %s)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" \
            "$([ "${menu_cpu_online_all}" = "1" ] && echo '全部在线' || echo '部分离线')"
        printf '%b║%b  %b[4]%b %b立即应用到系统%b\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BGREEN}${C_BOLD}" "${C_RESET}"
        printf '%b║%b  %b[0]%b 返回主菜单\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b╚══════════════════════════════════════════════════════════════╝%b\n' "${C_BCYAN}" "${C_RESET}"

        menu_read "请选择 [0-4]: "
        case "${MENU_INPUT}" in
            1)
                menu_read "请输入最低频率百分比 (0-100): "
                if [ "${MENU_INPUT}" -ge 0 ] 2>/dev/null && [ "${MENU_INPUT}" -le 100 ] 2>/dev/null; then
                    menu_cpu_min_pct="${MENU_INPUT}"
                    printf '%b✓ 已设置最低频率 = %d%%%b\n' "${C_BGREEN}" "${menu_cpu_min_pct}" "${C_RESET}"
                    menu_pause
                else
                    printf '%b✗ 无效输入，请输入 0-100 之间的数字%b\n' "${C_BRED}" "${C_RESET}"
                    menu_pause
                fi
                ;;
            2)
                menu_read "请输入最高频率百分比 (0-100): "
                if [ "${MENU_INPUT}" -ge 0 ] 2>/dev/null && [ "${MENU_INPUT}" -le 100 ] 2>/dev/null; then
                    menu_cpu_max_pct="${MENU_INPUT}"
                    printf '%b✓ 已设置最高频率 = %d%%%b\n' "${C_BGREEN}" "${menu_cpu_max_pct}" "${C_RESET}"
                    menu_pause
                else
                    printf '%b✗ 无效输入%b\n' "${C_BRED}" "${C_RESET}"
                    menu_pause
                fi
                ;;
            3)
                if [ "${menu_cpu_online_all}" = "1" ]; then
                    menu_cpu_online_all=0
                    printf '%b✓ 已切换：部分大核将离线（省电模式）%b\n' "${C_BYELLOW}" "${C_RESET}"
                else
                    menu_cpu_online_all=1
                    printf '%b✓ 已切换：全部核心在线%b\n' "${C_BGREEN}" "${C_RESET}"
                fi
                menu_pause
                ;;
            4)
                # 把菜单变量同步到全局，调用 set_cpu_frequency
                CPU_MIN_FREQ_PCT="${menu_cpu_min_pct}"
                CPU_MAX_FREQ_PCT="${menu_cpu_max_pct}"
                CPU_ONLINE_ALL="${menu_cpu_online_all}"
                printf '%b正在应用 CPU 频率设置...%b\n' "${C_CYAN}" "${C_RESET}"
                set_cpu_frequency
                printf '%b✓ CPU 频率设置已应用%b\n' "${C_BGREEN}" "${C_RESET}"
                menu_pause
                ;;
            0|q|Q)
                return 0
                ;;
            "")
                ;;
            *)
                printf '%b✗ 无效选择%b\n' "${C_BRED}" "${C_RESET}"
                menu_pause
                ;;
        esac
    done
}

# ============================================================================
# 子菜单 2：GPU 频率设置
# ============================================================================
menu_gpu_freq() {
    while true; do
        menu_clear
        printf '%b╔══════════════════════════════════════════════════════════════╗%b\n' "${C_BMAGENTA}" "${C_RESET}"
        printf '%b║%b  %bGPU 频率设置%b                                              %b║%b\n' \
            "${C_BMAGENTA}" "${C_RESET}" "${C_BOLD}${C_BMAGENTA}" "${C_RESET}" "${C_BMAGENTA}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BMAGENTA}" "${C_RESET}"

        if [ -z "${GPU_PATH:-}" ]; then
            detect_gpu_path
        fi
        if [ -z "${GPU_PATH:-}" ]; then
            printf '%b║%b  %b⚠ 未检测到 GPU 设备节点%b\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BRED}" "${C_RESET}"
            printf '%b║%b  GPU 设置将无法生效，但仍可调整参数\n' "${C_BMAGENTA}" "${C_RESET}"
        else
            _gpu_cur="$(read_sysfs "${GPU_PATH}/devfreq/cur_freq" 0)"
            _gpu_max="$(read_sysfs "${GPU_PATH}/devfreq/max_freq" 1)"
            _gpu_cur_mhz=$((_gpu_cur / 1000000))
            _gpu_max_mhz=$((_gpu_max / 1000000))
            printf '%b║%b GPU 设备: %b%s%b (%s)\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BCYAN}" "${GPU_PATH}" "${C_RESET}" "${GPU_TYPE:-unknown}"
            printf '%b║%b 当前频率: %s / 最大: %dMHz\n' "${C_BMAGENTA}" "${C_RESET}" "$(color_freq "${_gpu_cur_mhz}" "${_gpu_max_mhz}")" "${_gpu_max_mhz}"
        fi
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BMAGENTA}" "${C_RESET}"

        printf '%b║%b %b当前设置:%b\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
        printf '%b║%b   最低频率: %b%d%%%b\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BGREEN}" "${menu_gpu_min_pct}" "${C_RESET}"
        printf '%b║%b   最高频率: %b%d%%%b\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BRED}" "${menu_gpu_max_pct}" "${C_RESET}"
        printf '%b║%b   调速器  : %b%s%b\n' "${C_BMAGENTA}" "${C_RESET}" "${C_MAGENTA}" "${menu_gpu_governor}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BMAGENTA}" "${C_RESET}"

        printf '%b║%b  %b[1]%b 调整最低频率百分比  (当前 %d%%)\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${menu_gpu_min_pct}"
        printf '%b║%b  %b[2]%b 调整最高频率百分比  (当前 %d%%)\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${menu_gpu_max_pct}"
        printf '%b║%b  %b[3]%b 选择 GPU 调速器      (当前 %s)\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${menu_gpu_governor}"
        printf '%b║%b  %b[4]%b %b立即应用到系统%b\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BGREEN}${C_BOLD}" "${C_RESET}"
        printf '%b║%b  %b[0]%b 返回主菜单\n' "${C_BMAGENTA}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b╚══════════════════════════════════════════════════════════════╝%b\n' "${C_BMAGENTA}" "${C_RESET}"

        menu_read "请选择 [0-4]: "
        case "${MENU_INPUT}" in
            1)
                menu_read "请输入最低频率百分比 (0-100): "
                if [ "${MENU_INPUT}" -ge 0 ] 2>/dev/null && [ "${MENU_INPUT}" -le 100 ] 2>/dev/null; then
                    menu_gpu_min_pct="${MENU_INPUT}"
                    printf '%b✓ 已设置 GPU 最低频率 = %d%%%b\n' "${C_BGREEN}" "${menu_gpu_min_pct}" "${C_RESET}"
                    menu_pause
                else
                    printf '%b✗ 无效输入%b\n' "${C_BRED}" "${C_RESET}"; menu_pause
                fi
                ;;
            2)
                menu_read "请输入最高频率百分比 (0-100): "
                if [ "${MENU_INPUT}" -ge 0 ] 2>/dev/null && [ "${MENU_INPUT}" -le 100 ] 2>/dev/null; then
                    menu_gpu_max_pct="${MENU_INPUT}"
                    printf '%b✓ 已设置 GPU 最高频率 = %d%%%b\n' "${C_BGREEN}" "${menu_gpu_max_pct}" "${C_RESET}"
                    menu_pause
                else
                    printf '%b✗ 无效输入%b\n' "${C_BRED}" "${C_RESET}"; menu_pause
                fi
                ;;
            3)
                printf '%b可选 GPU 调速器:%b\n' "${C_CYAN}" "${C_RESET}"
                printf '  [1] performance    (性能优先)\n'
                printf '  [2] msm-adreno-tz  (Adreno 默认)\n'
                printf '  [3] powersave      (省电)\n'
                printf '  [4] simple_ondemand(按需)\n'
                printf '  [5] 其他（手动输入）\n'
                menu_read "请选择 [1-5]: "
                case "${MENU_INPUT}" in
                    1) menu_gpu_governor="performance" ;;
                    2) menu_gpu_governor="msm-adreno-tz" ;;
                    3) menu_gpu_governor="powersave" ;;
                    4) menu_gpu_governor="simple_ondemand" ;;
                    5) menu_read "请输入调速器名称: "; menu_gpu_governor="${MENU_INPUT}" ;;
                    *) printf '%b✗ 无效选择%b\n' "${C_BRED}" "${C_RESET}"; menu_pause; continue ;;
                esac
                printf '%b✓ GPU 调速器 = %s%b\n' "${C_BGREEN}" "${menu_gpu_governor}" "${C_RESET}"
                menu_pause
                ;;
            4)
                GPU_MIN_FREQ_PCT="${menu_gpu_min_pct}"
                GPU_MAX_FREQ_PCT="${menu_gpu_max_pct}"
                GPU_GOVERNOR="${menu_gpu_governor}"
                printf '%b正在应用 GPU 频率设置...%b\n' "${C_CYAN}" "${C_RESET}"
                set_gpu_frequency
                printf '%b✓ GPU 频率设置已应用%b\n' "${C_BGREEN}" "${C_RESET}"
                menu_pause
                ;;
            0|q|Q) return 0 ;;
            "") ;;
            *) printf '%b✗ 无效选择%b\n' "${C_BRED}" "${C_RESET}"; menu_pause ;;
        esac
    done
}

# ============================================================================
# 子菜单 3：温控设置
# ============================================================================
menu_thermal() {
    while true; do
        menu_clear
        printf '%b╔══════════════════════════════════════════════════════════════╗%b\n' "${C_BYELLOW}" "${C_RESET}"
        printf '%b║%b  %b温控设置%b                                                  %b║%b\n' \
            "${C_BYELLOW}" "${C_RESET}" "${C_BOLD}${C_BYELLOW}" "${C_RESET}" "${C_BYELLOW}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BYELLOW}" "${C_RESET}"

        # 显示当前温度
        _t="$(get_max_temp)"
        printf '%b║%b 当前最高 CPU 温度: %s\n' "${C_BYELLOW}" "${C_RESET}" "$(color_temp "${_t}")"

        # 列出温度区
        printf '%b║%b 温度区:\n' "${C_BYELLOW}" "${C_RESET}"
        _cnt=0
        for _tz in /sys/class/thermal/thermal_zone*; do
            [ -d "${_tz}" ] || continue
            _type="$(read_sysfs "${_tz}/type")"
            _ttemp="$(read_sysfs "${_tz}/temp" 0)"
            _ttemp_c=$((_ttemp / 1000))
            case "${_type}" in
                *cpu*|*CPU*|*soc*|*SoC*|*gpu*|*GPU*)
                    printf '%b║%b   %-20s %s\n' "${C_BYELLOW}" "${C_RESET}" "${_type}" "$(color_temp "${_ttemp}")"
                    _cnt=$((_cnt + 1))
                    [ "${_cnt}" -ge 4 ] && break
                    ;;
            esac
        done
        [ "${_cnt}" = "0" ] && printf '%b║%b   (无可用温区)%b\n' "${C_BYELLOW}" "${C_RESET}" "${C_DIM}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BYELLOW}" "${C_RESET}"

        printf '%b║%b %b当前设置:%b\n' "${C_BYELLOW}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
        printf '%b║%b   温度阈值: %b%d°C%b (超过则触发降频)\n' "${C_BYELLOW}" "${C_RESET}" "${C_BRED}" "${menu_thermal_limit}" "${C_RESET}"
        printf '%b║%b   热降频  : %b%s%b\n' "${C_BYELLOW}" "${C_RESET}" \
            "$([ "${menu_thermal_throttle}" = "1" ] && printf '%b' "${C_BGREEN}" || printf '%b' "${C_GRAY}")" \
            "$([ "${menu_thermal_throttle}" = "1" ] && echo '开启' || echo '关闭')" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BYELLOW}" "${C_RESET}"

        printf '%b║%b  %b[1]%b 调整温度阈值      (当前 %d°C)\n' "${C_BYELLOW}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${menu_thermal_limit}"
        printf '%b║%b  %b[2]%b 切换热降频开关    (当前 %s)\n' "${C_BYELLOW}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" \
            "$([ "${menu_thermal_throttle}" = "1" ] && echo '开' || echo '关')"
        printf '%b║%b  %b[3]%b 预设: 性能优先    (阈值=85°C)\n' "${C_BYELLOW}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[4]%b 预设: 均衡保护    (阈值=75°C)\n' "${C_BYELLOW}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[5]%b 预设: 保守省电    (阈值=65°C)\n' "${C_BYELLOW}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[6]%b %b立即应用到系统%b\n' "${C_BYELLOW}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BGREEN}${C_BOLD}" "${C_RESET}"
        printf '%b║%b  %b[0]%b 返回主菜单\n' "${C_BYELLOW}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b╚══════════════════════════════════════════════════════════════╝%b\n' "${C_BYELLOW}" "${C_RESET}"

        menu_read "请选择 [0-6]: "
        case "${MENU_INPUT}" in
            1)
                menu_read "请输入温度阈值 (40-95°C): "
                if [ "${MENU_INPUT}" -ge 40 ] 2>/dev/null && [ "${MENU_INPUT}" -le 95 ] 2>/dev/null; then
                    menu_thermal_limit="${MENU_INPUT}"
                    printf '%b✓ 温度阈值 = %d°C%b\n' "${C_BGREEN}" "${menu_thermal_limit}" "${C_RESET}"
                else
                    printf '%b✗ 无效输入（建议 40-95）%b\n' "${C_BRED}" "${C_RESET}"
                fi
                menu_pause
                ;;
            2)
                if [ "${menu_thermal_throttle}" = "1" ]; then
                    menu_thermal_throttle=0
                    printf '%b✓ 热降频已关闭%b\n' "${C_BYELLOW}" "${C_RESET}"
                else
                    menu_thermal_throttle=1
                    printf '%b✓ 热降频已开启%b\n' "${C_BGREEN}" "${C_RESET}"
                fi
                menu_pause
                ;;
            3) menu_thermal_limit=85; printf '%b✓ 已选择性能优先 (85°C)%b\n' "${C_BRED}" "${C_RESET}"; menu_pause ;;
            4) menu_thermal_limit=75; printf '%b✓ 已选择均衡保护 (75°C)%b\n' "${C_BCYAN}" "${C_RESET}"; menu_pause ;;
            5) menu_thermal_limit=65; printf '%b✓ 已选择保守省电 (65°C)%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            6)
                THERMAL_TEMP_LIMIT="${menu_thermal_limit}"
                THERMAL_THROTTLE_ENABLE="${menu_thermal_throttle}"
                printf '%b正在应用温控设置...%b\n' "${C_CYAN}" "${C_RESET}"
                set_thermal_control
                printf '%b✓ 温控设置已应用%b\n' "${C_BGREEN}" "${C_RESET}"
                menu_pause
                ;;
            0|q|Q) return 0 ;;
            "") ;;
            *) printf '%b✗ 无效选择%b\n' "${C_BRED}" "${C_RESET}"; menu_pause ;;
        esac
    done
}

# ============================================================================
# 子菜单 4：屏幕采样率设置
# ============================================================================
menu_screen() {
    while true; do
        menu_clear
        printf '%b╔══════════════════════════════════════════════════════════════╗%b\n' "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b屏幕采样率设置%b                                            %b║%b\n' \
            "${C_BBLUE}" "${C_RESET}" "${C_BOLD}${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BBLUE}" "${C_RESET}"

        printf '%b║%b %b当前设置:%b\n' "${C_BBLUE}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
        printf '%b║%b   触摸采样率: %b%dHz%b\n' "${C_BBLUE}" "${C_RESET}" "${C_BGREEN}" "${menu_screen_sampling}" "${C_RESET}"
        printf '%b║%b   屏幕刷新率: %b%dHz%b\n' "${C_BBLUE}" "${C_RESET}" "${C_BRED}" "${menu_screen_refresh}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BBLUE}" "${C_RESET}"

        printf '%b║%b  %b触摸采样率选项:%b\n' "${C_BBLUE}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
        printf '%b║%b  %b[1]%b 120 Hz  (普通)\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[2]%b 160 Hz  (流畅)\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[3]%b 240 Hz  (电竞)\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[4]%b 360 Hz  (极致)\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[5]%b 手动输入\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b\n' "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b屏幕刷新率选项:%b\n' "${C_BBLUE}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
        printf '%b║%b  %b[6]%b 60 Hz   (省电)\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[7]%b 90 Hz   (均衡)\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[8]%b 120 Hz  (高刷)\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[9]%b 144 Hz  (电竞)\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b\n' "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[a]%b %b立即应用到系统%b\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BGREEN}${C_BOLD}" "${C_RESET}"
        printf '%b║%b  %b[0]%b 返回主菜单\n' "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b╚══════════════════════════════════════════════════════════════╝%b\n' "${C_BBLUE}" "${C_RESET}"

        menu_read "请选择: "
        case "${MENU_INPUT}" in
            1) menu_screen_sampling=120; printf '%b✓ 采样率 = 120Hz%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            2) menu_screen_sampling=160; printf '%b✓ 采样率 = 160Hz%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            3) menu_screen_sampling=240; printf '%b✓ 采样率 = 240Hz%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            4) menu_screen_sampling=360; printf '%b✓ 采样率 = 360Hz%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            5)
                menu_read "请输入采样率 Hz (60-480): "
                if [ "${MENU_INPUT}" -ge 60 ] 2>/dev/null && [ "${MENU_INPUT}" -le 480 ] 2>/dev/null; then
                    menu_screen_sampling="${MENU_INPUT}"
                    printf '%b✓ 采样率 = %dHz%b\n' "${C_BGREEN}" "${menu_screen_sampling}" "${C_RESET}"
                else
                    printf '%b✗ 无效输入%b\n' "${C_BRED}" "${C_RESET}"
                fi
                menu_pause
                ;;
            6) menu_screen_refresh=60; printf '%b✓ 刷新率 = 60Hz%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            7) menu_screen_refresh=90; printf '%b✓ 刷新率 = 90Hz%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            8) menu_screen_refresh=120; printf '%b✓ 刷新率 = 120Hz%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            9) menu_screen_refresh=144; printf '%b✓ 刷新率 = 144Hz%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            a|A)
                SCREEN_SAMPLING_RATE="${menu_screen_sampling}"
                SCREEN_REFRESH_RATE="${menu_screen_refresh}"
                printf '%b正在应用屏幕设置...%b\n' "${C_CYAN}" "${C_RESET}"
                set_screen_sampling
                printf '%b✓ 屏幕采样率设置已应用%b\n' "${C_BGREEN}" "${C_RESET}"
                menu_pause
                ;;
            0|q|Q) return 0 ;;
            "") ;;
            *) printf '%b✗ 无效选择%b\n' "${C_BRED}" "${C_RESET}"; menu_pause ;;
        esac
    done
}

# ============================================================================
# 子菜单 5：调速器设置
# ============================================================================
menu_governor() {
    while true; do
        menu_clear
        printf '%b╔══════════════════════════════════════════════════════════════╗%b\n' "${C_BCYAN}" "${C_RESET}"
        printf '%b║%b  %b调速器设置%b                                                %b║%b\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BOLD}${C_BCYAN}" "${C_RESET}" "${C_BCYAN}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        # 显示各核当前 governor + 可用 governor
        printf '%b║%b %b各核心当前调速器:%b\n' "${C_BCYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
        _avail_gov=""
        for _idx in $(seq 0 $((TOTAL_CPUS - 1))); do
            _gov="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/cpufreq/scaling_governor" "-")"
            [ -z "${_avail_gov}" ] && _avail_gov="$(read_sysfs "/sys/devices/system/cpu/cpu${_idx}/cpufreq/scaling_available_governors")"
            printf '%b║%b   cpu%d: %b%s%b\n' "${C_BCYAN}" "${C_RESET}" "${_idx}" "${C_MAGENTA}" "${_gov}" "${C_RESET}"
        done
        printf '%b║%b 可用调速器: %b%s%b\n' "${C_BCYAN}" "${C_RESET}" "${C_DIM}" "${_avail_gov:-unknown}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        printf '%b║%b %b当前选择:%b %b%s%b\n' "${C_BCYAN}" "${C_RESET}" "${C_BOLD}" "${C_RESET}" "${C_MAGENTA}" "${menu_cpu_governor}" "${C_RESET}"
        if [ "${menu_cpu_governor}" = "schedutil" ]; then
            printf '%b║%b schedutil rate_limit: %b%dμs%b\n' "${C_BCYAN}" "${C_RESET}" "${C_YELLOW}" "${menu_schedutil_rate}" "${C_RESET}"
        fi
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        printf '%b║%b  %b[1]%b performance    (性能优先，固定高频)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[2]%b schedutil      (调度器驱动，推荐)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[3]%b interactive    (交互响应快)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[4]%b ondemand       (按需调频)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[5]%b powersave      (省电，固定低频)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[6]%b userspace      (用户手动)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[7]%b 调整 schedutil rate_limit (当前 %dμs)\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${menu_schedutil_rate}"
        printf '%b║%b  %b[8]%b %b立即应用到系统%b\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BGREEN}${C_BOLD}" "${C_RESET}"
        printf '%b║%b  %b[0]%b 返回主菜单\n' "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b╚══════════════════════════════════════════════════════════════╝%b\n' "${C_BCYAN}" "${C_RESET}"

        menu_read "请选择 [0-8]: "
        case "${MENU_INPUT}" in
            1) menu_cpu_governor="performance"; printf '%b✓ 调速器 = performance%b\n' "${C_BRED}" "${C_RESET}"; menu_pause ;;
            2) menu_cpu_governor="schedutil"; printf '%b✓ 调速器 = schedutil%b\n' "${C_BCYAN}" "${C_RESET}"; menu_pause ;;
            3) menu_cpu_governor="interactive"; printf '%b✓ 调速器 = interactive%b\n' "${C_BYELLOW}" "${C_RESET}"; menu_pause ;;
            4) menu_cpu_governor="ondemand"; printf '%b✓ 调速器 = ondemand%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            5) menu_cpu_governor="powersave"; printf '%b✓ 调速器 = powersave%b\n' "${C_BGREEN}" "${C_RESET}"; menu_pause ;;
            6) menu_cpu_governor="userspace"; printf '%b✓ 调速器 = userspace%b\n' "${C_GRAY}" "${C_RESET}"; menu_pause ;;
            7)
                menu_read "请输入 rate_limit (μs, 500-50000): "
                if [ "${MENU_INPUT}" -ge 500 ] 2>/dev/null && [ "${MENU_INPUT}" -le 50000 ] 2>/dev/null; then
                    menu_schedutil_rate="${MENU_INPUT}"
                    printf '%b✓ rate_limit = %dμs%b\n' "${C_BGREEN}" "${menu_schedutil_rate}" "${C_RESET}"
                else
                    printf '%b✗ 无效输入%b\n' "${C_BRED}" "${C_RESET}"
                fi
                menu_pause
                ;;
            8)
                CPU_GOVERNOR="${menu_cpu_governor}"
                SCHEDUTIL_RATE_LIMIT_US="${menu_schedutil_rate}"
                printf '%b正在应用调速器设置...%b\n' "${C_CYAN}" "${C_RESET}"
                set_governor
                printf '%b✓ 调速器设置已应用%b\n' "${C_BGREEN}" "${C_RESET}"
                menu_pause
                ;;
            0|q|Q) return 0 ;;
            "") ;;
            *) printf '%b✗ 无效选择%b\n' "${C_BRED}" "${C_RESET}"; menu_pause ;;
        esac
    done
}

# ============================================================================
# 子菜单 6：一键预设档位
# ============================================================================
menu_profiles() {
    while true; do
        menu_clear
        printf '%b╔══════════════════════════════════════════════════════════════╗%b\n' "${C_BGREEN}" "${C_RESET}"
        printf '%b║%b  %b一键预设档位%b                                              %b║%b\n' \
            "${C_BGREEN}" "${C_RESET}" "${C_BOLD}${C_BGREEN}" "${C_RESET}" "${C_BGREEN}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BGREEN}" "${C_RESET}"

        printf '%b║%b  %b[1]%b %bperformance%b  性能模式\n' "${C_BGREEN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BRED}" "${C_RESET}"
        printf '%b║%b      全核高频 · 240Hz 采样 · 120Hz 刷新 · 阈值 85°C\n' "${C_BGREEN}" "${C_RESET}"
        printf '%b║%b\n' "${C_BGREEN}" "${C_RESET}"

        printf '%b║%b  %b[2]%b %bbalance%b      均衡模式（推荐）\n' "${C_BGREEN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b      schedutil · 160Hz 采样 · 90Hz 刷新 · 阈值 75°C\n' "${C_BGREEN}" "${C_RESET}"
        printf '%b║%b\n' "${C_BGREEN}" "${C_RESET}"

        printf '%b║%b  %b[3]%b %bpowersave%b    省电模式\n' "${C_BGREEN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BGREEN}" "${C_RESET}"
        printf '%b║%b      降频 · 部分大核离线 · 120Hz · 60Hz · 阈值 65°C\n' "${C_BGREEN}" "${C_RESET}"
        printf '%b║%b\n' "${C_BGREEN}" "${C_RESET}"

        printf '%b║%b  %b[4]%b %bgame%b         游戏模式\n' "${C_BGREEN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BMAGENTA}" "${C_RESET}"
        printf '%b║%b      性能优先 · 240Hz 采样 · 120Hz · 阈值 80°C\n' "${C_BGREEN}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BGREEN}" "${C_RESET}"

        printf '%b║%b  %b[0]%b 返回主菜单\n' "${C_BGREEN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b╚══════════════════════════════════════════════════════════════╝%b\n' "${C_BGREEN}" "${C_RESET}"

        menu_read "请选择档位 [0-4]: "
        case "${MENU_INPUT}" in
            1)
                printf '%b正在应用 performance 档位...%b\n' "${C_BRED}" "${C_RESET}"
                USER_TARGET_PROFILE="performance"
                backup_settings
                apply_profile "performance"
                # 同步菜单变量
                menu_cpu_min_pct=70; menu_cpu_max_pct=100; menu_cpu_online_all=1
                menu_gpu_min_pct=80; menu_gpu_max_pct=100; menu_gpu_governor="performance"
                menu_thermal_limit=85; menu_thermal_throttle=1
                menu_screen_sampling=240; menu_screen_refresh=120
                menu_cpu_governor="performance"; menu_schedutil_rate=1000
                printf '%b✓ 已应用 performance 档位%b\n' "${C_BGREEN}" "${C_RESET}"
                menu_pause
                return 0
                ;;
            2)
                printf '%b正在应用 balance 档位...%b\n' "${C_BBLUE}" "${C_RESET}"
                USER_TARGET_PROFILE="balance"
                backup_settings
                apply_profile "balance"
                menu_cpu_min_pct=30; menu_cpu_max_pct=100; menu_cpu_online_all=1
                menu_gpu_min_pct=20; menu_gpu_max_pct=90; menu_gpu_governor="msm-adreno-tz"
                menu_thermal_limit=75; menu_thermal_throttle=1
                menu_screen_sampling=160; menu_screen_refresh=90
                menu_cpu_governor="schedutil"; menu_schedutil_rate=5000
                printf '%b✓ 已应用 balance 档位%b\n' "${C_BGREEN}" "${C_RESET}"
                menu_pause
                return 0
                ;;
            3)
                printf '%b正在应用 powersave 档位...%b\n' "${C_BGREEN}" "${C_RESET}"
                USER_TARGET_PROFILE="powersave"
                backup_settings
                apply_profile "powersave"
                menu_cpu_min_pct=0; menu_cpu_max_pct=60; menu_cpu_online_all=0
                menu_gpu_min_pct=0; menu_gpu_max_pct=50; menu_gpu_governor="powersave"
                menu_thermal_limit=65; menu_thermal_throttle=1
                menu_screen_sampling=120; menu_screen_refresh=60
                menu_cpu_governor="powersave"; menu_schedutil_rate=10000
                printf '%b✓ 已应用 powersave 档位%b\n' "${C_BGREEN}" "${C_RESET}"
                menu_pause
                return 0
                ;;
            4)
                printf '%b正在应用 game 档位...%b\n' "${C_BMAGENTA}" "${C_RESET}"
                USER_TARGET_PROFILE="game"
                backup_settings
                apply_profile "game"
                menu_cpu_min_pct=60; menu_cpu_max_pct=100; menu_cpu_online_all=1
                menu_gpu_min_pct=70; menu_gpu_max_pct=100; menu_gpu_governor="performance"
                menu_thermal_limit=80; menu_thermal_throttle=1
                menu_screen_sampling=240; menu_screen_refresh=120
                menu_cpu_governor="performance"; menu_schedutil_rate=1000
                printf '%b✓ 已应用 game 档位%b\n' "${C_BGREEN}" "${C_RESET}"
                menu_pause
                return 0
                ;;
            0|q|Q) return 0 ;;
            "") ;;
            *) printf '%b✗ 无效选择%b\n' "${C_BRED}" "${C_RESET}"; menu_pause ;;
        esac
    done
}

# ============================================================================
# 子菜单 7：保存当前设置为配置文件
# ============================================================================
menu_save_config() {
    menu_clear
    printf '%b╔══════════════════════════════════════════════════════════════╗%b\n' "${C_BYELLOW}" "${C_RESET}"
    printf '%b║%b  %b保存当前设置为配置文件%b                                    %b║%b\n' \
        "${C_BYELLOW}" "${C_RESET}" "${C_BOLD}${C_BYELLOW}" "${C_RESET}" "${C_BYELLOW}" "${C_RESET}"
    printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BYELLOW}" "${C_RESET}"

    printf '%b║%b %b即将保存的当前参数:%b\n' "${C_BYELLOW}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    printf '%b║%b   CPU: min=%d%% max=%d%% online_all=%s gov=%s\n' "${C_BYELLOW}" "${C_RESET}" \
        "${menu_cpu_min_pct}" "${menu_cpu_max_pct}" "${menu_cpu_online_all}" "${menu_cpu_governor}"
    printf '%b║%b   GPU: min=%d%% max=%d%% gov=%s\n' "${C_BYELLOW}" "${C_RESET}" \
        "${menu_gpu_min_pct}" "${menu_gpu_max_pct}" "${menu_gpu_governor}"
    printf '%b║%b   温控: 阈值=%d°C 降频=%s\n' "${C_BYELLOW}" "${C_RESET}" \
        "${menu_thermal_limit}" "${menu_thermal_throttle}"
    printf '%b║%b   屏幕: 采样=%dHz 刷新=%dHz\n' "${C_BYELLOW}" "${C_RESET}" \
        "${menu_screen_sampling}" "${menu_screen_refresh}"
    if [ "${menu_cpu_governor}" = "schedutil" ]; then
        printf '%b║%b   schedutil rate_limit: %dμs\n' "${C_BYELLOW}" "${C_RESET}" "${menu_schedutil_rate}"
    fi
    printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BYELLOW}" "${C_RESET}"

    _default_path="${SCRIPT_DIR}/my-tuner.conf"
    menu_read "请输入保存路径 [回车=默认 ${_default_path}]: "
    _save_path="${MENU_INPUT:-${_default_path}}"

    if [ -f "${_save_path}" ]; then
        menu_read "文件已存在，覆盖？ [y/N]: "
        case "${MENU_INPUT}" in
            y|Y) ;;
            *) printf '%b已取消%b\n' "${C_YELLOW}" "${C_RESET}"; menu_pause; return 1 ;;
        esac
    fi

    # 生成配置文件
    {
        echo "# ============================================================"
        echo "#  my-tuner.conf — 由交互菜单生成 $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# ============================================================"
        echo ""
        echo "ENABLE_CPU=1"
        echo "ENABLE_GPU=1"
        echo "ENABLE_THERMAL=1"
        echo "ENABLE_SCREEN=1"
        echo "ENABLE_GOVERNOR=1"
        echo "ENABLE_DYNAMIC=1"
        echo ""
        echo "SCHEDULE_INTERVAL=5"
        echo "LOG_LEVEL=3"
        echo ""
        echo "PROFILE_CUSTOM=\""
        echo "CPU_GOVERNOR=${menu_cpu_governor}"
        echo "CPU_MIN_FREQ_PCT=${menu_cpu_min_pct}"
        echo "CPU_MAX_FREQ_PCT=${menu_cpu_max_pct}"
        echo "CPU_ONLINE_ALL=${menu_cpu_online_all}"
        echo "GPU_GOVERNOR=${menu_gpu_governor}"
        echo "GPU_MIN_FREQ_PCT=${menu_gpu_min_pct}"
        echo "GPU_MAX_FREQ_PCT=${menu_gpu_max_pct}"
        echo "THERMAL_TEMP_LIMIT=${menu_thermal_limit}"
        echo "THERMAL_THROTTLE_ENABLE=${menu_thermal_throttle}"
        echo "SCREEN_SAMPLING_RATE=${menu_screen_sampling}"
        echo "SCREEN_REFRESH_RATE=${menu_screen_refresh}"
        echo "SCHEDUTIL_RATE_LIMIT_US=${menu_schedutil_rate}"
        echo "\""
    } > "${_save_path}" 2>/dev/null

    if [ -f "${_save_path}" ]; then
        printf '%b✓ 配置已保存到: %s%b\n' "${C_BGREEN}" "${_save_path}" "${C_RESET}"
        printf '%b  使用方法: ./performance-tuner.sh apply custom%b\n' "${C_DIM}" "${C_RESET}"
    else
        printf '%b✗ 保存失败（权限不足？）%b\n' "${C_BRED}" "${C_RESET}"
    fi
    menu_pause
}

# ============================================================================
# 主菜单
# ============================================================================
menu_main() {
    # 进入菜单强制启用颜色
    FORCE_COLOR=1
    init_colors

    # 捕捉 Ctrl+C 优雅退出菜单
    trap 'printf "\n%b退出菜单%b\n" "${C_YELLOW}" "${C_RESET}"; tput cnorm 2>/dev/null; exit 0' INT TERM

    while true; do
        menu_clear
        printf '%b╔══════════════════════════════════════════════════════════════╗%b\n' "${C_BCYAN}" "${C_RESET}"
        printf '%b║%b  %bPerformance Tuner v%s  交互式调度菜单%b              %b║%b\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BOLD}${C_WHITE}" "${VERSION}" "${C_RESET}" "${C_BCYAN}" "${C_RESET}"
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"
        menu_status_bar
        printf '%b╠══════════════════════════════════════════════════════════════╣%b\n' "${C_BCYAN}" "${C_RESET}"

        printf '%b║%b  %b[1]%b %bCPU 频率设置%b        min=%d%% max=%d%%\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BOLD}${C_BGREEN}" "${C_RESET}" "${menu_cpu_min_pct}" "${menu_cpu_max_pct}"
        printf '%b║%b  %b[2]%b %bGPU 频率设置%b        min=%d%% max=%d%%\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BOLD}${C_BMAGENTA}" "${C_RESET}" "${menu_gpu_min_pct}" "${menu_gpu_max_pct}"
        printf '%b║%b  %b[3]%b %b温控设置%b            阈值=%d°C 降频=%s\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BOLD}${C_BYELLOW}" "${C_RESET}" "${menu_thermal_limit}" \
            "$([ "${menu_thermal_throttle}" = "1" ] && echo '开' || echo '关')"
        printf '%b║%b  %b[4]%b %b屏幕采样率设置%b      采样=%dHz 刷新=%dHz\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BOLD}${C_BBLUE}" "${C_RESET}" "${menu_screen_sampling}" "${menu_screen_refresh}"
        printf '%b║%b  %b[5]%b %b调速器设置%b          governor=%s\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BOLD}${C_BCYAN}" "${C_RESET}" "${menu_cpu_governor}"
        printf '%b║%b\n' "${C_BCYAN}" "${C_RESET}"
        printf '%b║%b  %b[6]%b %b一键预设档位%b        (performance/balance/powersave/game)\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BOLD}${C_BGREEN}" "${C_RESET}"
        printf '%b║%b  %b[7]%b 实时监控              (彩色 + 进度条)\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[8]%b 查看当前完整状态\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[9]%b %b保存当前设置为配置文件%b\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_BOLD}${C_BYELLOW}" "${C_RESET}"
        printf '%b║%b  %b[s]%b 一键应用当前所有设置到系统\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b║%b  %b[0]%b 退出菜单\n' \
            "${C_BCYAN}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}"
        printf '%b╚══════════════════════════════════════════════════════════════╝%b\n' "${C_BCYAN}" "${C_RESET}"
        printf '\n'
        menu_read "请选择 [0-9/s]: "

        case "${MENU_INPUT}" in
            1) menu_cpu_freq ;;
            2) menu_gpu_freq ;;
            3) menu_thermal ;;
            4) menu_screen ;;
            5) menu_governor ;;
            6) menu_profiles ;;
            7) monitor_mode ;;
            8) show_status; menu_pause ;;
            9) menu_save_config ;;
            s|S)
                printf '%b正在应用所有设置到系统...%b\n' "${C_CYAN}" "${C_RESET}"
                CPU_GOVERNOR="${menu_cpu_governor}"
                CPU_MIN_FREQ_PCT="${menu_cpu_min_pct}"
                CPU_MAX_FREQ_PCT="${menu_cpu_max_pct}"
                CPU_ONLINE_ALL="${menu_cpu_online_all}"
                GPU_GOVERNOR="${menu_gpu_governor}"
                GPU_MIN_FREQ_PCT="${menu_gpu_min_pct}"
                GPU_MAX_FREQ_PCT="${menu_gpu_max_pct}"
                THERMAL_TEMP_LIMIT="${menu_thermal_limit}"
                THERMAL_THROTTLE_ENABLE="${menu_thermal_throttle}"
                SCREEN_SAMPLING_RATE="${menu_screen_sampling}"
                SCREEN_REFRESH_RATE="${menu_screen_refresh}"
                SCHEDUTIL_RATE_LIMIT_US="${menu_schedutil_rate}"

                backup_settings
                [ "${ENABLE_GOVERNOR}" = "1" ] && set_governor
                [ "${ENABLE_CPU}"      = "1" ] && set_cpu_frequency
                [ "${ENABLE_GPU}"      = "1" ] && set_gpu_frequency
                [ "${ENABLE_SCREEN}"   = "1" ] && set_screen_sampling
                [ "${ENABLE_THERMAL}"  = "1" ] && set_thermal_control
                printf '%b✓ 所有设置已应用到系统%b\n' "${C_BGREEN}${C_BOLD}" "${C_RESET}"
                menu_pause
                ;;
            0|q|Q|exit)
                printf '%b再见！%b\n' "${C_BCYAN}" "${C_RESET}"
                break
                ;;
            "")
                ;;
            *)
                printf '%b✗ 无效选择，请重新输入%b\n' "${C_BRED}" "${C_RESET}"
                menu_pause
                ;;
        esac
    done

    # 恢复终端
    tput cnorm 2>/dev/null
    trap - INT TERM
}

# ============================================================================
# 主入口
# ============================================================================

main() {
    # 初始化颜色系统（最先执行，使后续日志/输出带色）
    init_colors

    # 探测硬件拓扑（debug 级日志，默认不输出）
    detect_cpu_topology
    detect_gpu_path

    # 预初始化路径（处理默认 LOG_FILE 的可写性）
    init_paths

    # 加载配置（可能覆盖 LOG_FILE/PID_FILE 等路径）
    load_config

    # 再次初始化路径（处理配置覆盖后的最终路径）
    init_paths

    # 权限检查
    if [ "$(id -u)" != "0" ]; then
        log_warn "建议以 root 权限运行（当前用户: $(id -un)）"
    fi

    _cmd="${1:-menu}"
    shift 2>/dev/null || true

    case "${_cmd}" in
        menu|interactive|tui)
            menu_main
            ;;
        start)
            USER_TARGET_PROFILE="${1:-balance}"
            start_daemon
            ;;
        stop)
            stop_daemon
            ;;
        restart)
            stop_daemon
            sleep 1
            USER_TARGET_PROFILE="${1:-balance}"
            start_daemon
            ;;
        apply)
            _profile="${1:-balance}"
            USER_TARGET_PROFILE="${_profile}"
            backup_settings
            apply_profile "${_profile}"
            ;;
        status)
            show_status
            ;;
        monitor)
            monitor_mode
            ;;
        reload)
            stop_daemon
            load_config
            USER_TARGET_PROFILE="${1:-balance}"
            start_daemon
            ;;
        backup)
            backup_settings
            ;;
        restore)
            restore_settings
            ;;
        _daemon_internal)
            _daemon_internal "$1"
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            log_error "未知命令: ${_cmd}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
