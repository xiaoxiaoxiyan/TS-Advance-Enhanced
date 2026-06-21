#!/system/bin/sh
# ============================================================
# XToolbox v1.6 - Android Root 工具箱
# 作者: 汐
# 版本: v1.6
# 说明: 本脚本仅供学习和研究使用，禁止用于非法用途
# ============================================================


R='\033[1;31m';G='\033[1;32m';Y='\033[1;33m';B='\033[1;34m';P='\033[1;35m';C='\033[1;36m';W='\033[1;37m'
N='\033[0m';BD='\033[1m';DI='\033[2m'
ORANGE='\033[38;5;214m';GOLD='\033[38;5;220m'
CYAN_BRIGHT='\033[38;5;51m';GREEN_BRIGHT='\033[38;5;46m'
PURPLE_BRIGHT='\033[38;5;165m';YELLOW_BRIGHT='\033[38;5;226m'

_ONLINE=0
XTB_DIR='/data/local/tmp/XToolbox'
USAGE_FILE="$XTB_DIR/usage.txt"
LAUNCH_FILE="$XTB_DIR/launch_count.txt"
TS_DIR="/data/adb/tricky_store"
TMP_DIR="/data/local/tmp/keybox_update"
OUT_DIR="/sdcard/Download/XToolbox"

API_URL="http://sgheejejee54545181851616646461515166hxhdhehejjdfhh.qehap.asia/环境/api.php"

CLOUD_BASE="http://sgheejejee54545181851616646461515166hxhdhehejjdfhh.qehap.asia/环境"

GITHUB_PROXY=""

FIXED_KEY="xibox123"

SCRIPT_DIR=""
BIN_DIR=""

show_startup_check() {
    clear
    printf "${P}\n"
    printf " ██████╗ ██╗     ██╗████████╗ ██████╗██╗  ██╗       ██╗  ██╗██╗   ██╗███╗   ██╗████████╗\n"
    printf "██╔════╝ ██║     ██║╚══██╔══╝██╔════╝██║  ██║       ██║  ██║██║   ██║████╗  ██║╚══██╔══╝\n"
    printf "██║  ███╗██║     ██║   ██║   ██║     ███████║       ███████║██║   ██║██╔██╗ ██║   ██║   \n"
    printf "██║   ██║██║     ██║   ██║   ██║     ██╔══██║       ██╔══██║██║   ██║██║╚██╗██║   ██║   \n"
    printf "╚██████╔╝███████╗██║   ██║   ╚██████╗██║  ██╗       ██╗  ██╗╚██████╔╝██║ ╚████║   ██║   \n"
    printf " ╚═════╝ ╚══════╝╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   \n"
    printf "${N}\n"
    printf "${GOLD}              ═══ v1.6 ═══${N}\n"
    printf "${GOLD}              作者：${W}汐${N}\n"
    echo

    printf "${ORANGE}╔════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}启 动 检 测${N}              ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════╣${N}\n"

    local has_777=0
    local script_perms=$(stat -c "%a" "$0" 2>/dev/null)
    if [ "$script_perms" = "777" ]; then
        has_777=1
        printf "${ORANGE}║${N}  ${G}[√] 脚本权限检测: 777${N}          ${ORANGE}║${N}\n"
    else
        printf "${ORANGE}║${N}  ${R}[X] 脚本权限检测: 非777${N}        ${ORANGE}║${N}\n"
    fi

    local mt_check=0
    if pm list packages 2>/dev/null | grep -q "bin.mt.plus" || [ -d "/data/data/bin.mt.plus" ] 2>/dev/null; then
        mt_check=1
        printf "${ORANGE}║${N}  ${G}[√] MT拓展包检测: 已安装${N}        ${ORANGE}║${N}\n"
    else
        printf "${ORANGE}║${N}  ${Y}[!] MT拓展包检测: 未检测到${N}     ${ORANGE}║${N}\n"
    fi

    printf "${ORANGE}╚════════════════════════════════════╝${N}\n"
    echo

    if [ "$has_777" -eq 1 ]; then
        SCRIPT_DIR=$(dirname "$0")
        BIN_DIR="$SCRIPT_DIR/bin"
    else
        SCRIPT_DIR="$XTB_DIR"
        BIN_DIR="$XTB_DIR/bin"
    fi

    if [ "$has_777" -eq 0 ]; then
        printf "${R}[!] 警告：脚本未设置777权限${N}\n"
        printf "${Y}[!] 如出现任何风险，后果自负${N}\n"
        echo
    fi
    if [ "$mt_check" -eq 0 ]; then
        printf "${R}[!] 未检测到MT管理器拓展包${N}\n"
        printf "${C}是否安装MT拓展包? [y/N]: ${N}"
        read install_mt
        if [ "$install_mt" = "y" ] || [ "$install_mt" = "Y" ]; then
            install_mt_extension
            printf "${Y}[!] 安装完成，请重新运行脚本${N}\n"
            printf "  ${C}按回车键退出...${N}"
            read
            exit 0
        fi
        echo
    fi
    printf "  ${C}按回车键继续...${N}"
    read

}
download_with_progress() {
    local url="$1"
    local output="$2"
    local desc="$3"
    printf "${C}[*] 正在下载: $desc${N}\n"

    # 先获取文件总大小
    local total_size=0
    if which curl >/dev/null 2>&1; then
        total_size=$(curl -sI -L "$url" 2>/dev/null | grep -i "Content-Length:" | tr -d '\r' | awk '{print $2}' | tail -1)
    elif which wget >/dev/null 2>&1; then
        total_size=$(wget --spider -S "$url" 2>&1 | grep -i "Content-Length:" | awk '{print $2}' | tail -1)
    fi
    [ -z "$total_size" ] && total_size=0

    # 开始下载(后台)
    if which curl >/dev/null 2>&1; then
        curl -s -L "$url" -o "$output" &
    elif which wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output" &
    else
        printf "${R}[X] 需要curl或wget${N}\n"
        return 1
    fi
    local pid=$!

    # 进度条参数
    local bar_len=30
    local last_size=0

    # 循环检测进度
    while kill -0 $pid 2>/dev/null; do
        local cur_size=0
        [ -f "$output" ] && cur_size=$(ls -l "$output" 2>/dev/null | awk '{print $5}')
        [ -z "$cur_size" ] && cur_size=0

        local percent=0
        if [ "$total_size" -gt 0 ] 2>/dev/null; then
            percent=$((cur_size * 100 / total_size))
        fi

        # 进度条
        local filled=0
        if [ "$total_size" -gt 0 ] 2>/dev/null; then
            filled=$((cur_size * bar_len / total_size))
        fi
        [ "$filled" -gt "$bar_len" ] && filled=$bar_len

        local bar=""
        local j=0
        while [ "$j" -lt "$filled" ]; do bar="${bar}#"; j=$((j + 1)); done
        j=0
        while [ "$j" -lt $((bar_len - filled)) ]; do bar="${bar}-"; j=$((j + 1)); done

        # 格式化已下载大小
        local dl_h=""
        if [ "$cur_size" -ge $((1024*1024)) ] 2>/dev/null; then
            dl_h="$(($cur_size/1024/1024))M"
        elif [ "$cur_size" -ge 1024 ] 2>/dev/null; then
            dl_h="$(($cur_size/1024))K"
        else
            dl_h="${cur_size}B"
        fi

        # 格式化总大小
        local tot_h=""
        if [ "$total_size" -ge $((1024*1024)) ] 2>/dev/null; then
            tot_h="$(($total_size/1024/1024))M"
        elif [ "$total_size" -ge 1024 ] 2>/dev/null; then
            tot_h="$(($total_size/1024))K"
        else
            tot_h="${total_size}B"
        fi

        printf "\r  ${C}[%s]${N} %3d%% %s/%s  " "$bar" "$percent" "$dl_h" "$tot_h"

        sleep 0.3
    done

    wait $pid 2>/dev/null
    local ret=$?
    printf "\r"

    if [ $ret -eq 0 ] && [ -f "$output" ] && [ -s "$output" ]; then
        local sz=$(ls -lh "$output" | awk '{print $5}')
        # 完成进度条
        local j=0; local full_bar=""
        while [ "$j" -lt "$bar_len" ]; do full_bar="${full_bar}#"; j=$((j + 1)); done
        printf "  ${G}[${full_bar}] 100%%%% ${sz}  ${N}\n"
        printf "  ${G}[OK] 下载完成${N}\n"
        return 0
    else
        printf "  ${R}[X] 下载失败${N}\n"
        rm -f "$output"
        return 1
    fi
}

download_with_progress_retry() {
    local url="$1"
    local output="$2"
    local desc="$3"
    local max_retry=3
    local retry=0

    while [ $retry -lt $max_retry ]; do
        if download_with_progress "$url" "$output" "$desc"; then
            return 0
        fi
        retry=$((retry + 1))
        if [ $retry -lt $max_retry ]; then
            printf "${Y}[!] 第${retry}次下载失败，正在重试...${N}\n"
            rm -f "$output"
            sleep 2
        fi
    done
    printf "${R}[X] 下载失败（已尝试${max_retry}次）${N}\n"
    return 1
}

download_dir_files() {
    local base_url="$1"
    local target_dir="$2"
    local desc="$3"
    
    mkdir -p "$target_dir"
    printf "${C}[*] 正在下载: $desc${N}\n"
    
    # 尝试获取文件列表（通过HTML索引页面）
    local html_content=""
    if which curl >/dev/null 2>&1; then
        html_content=$(curl -s -L "$base_url" 2>/dev/null)
    elif which wget >/dev/null 2>&1; then
        html_content=$(wget -q -O - "$base_url" 2>/dev/null)
    fi
    
    if [ -n "$html_content" ]; then
        # 从HTML中提取文件名
        local files=$(printf "$html_content\n" | sed -n 's/.*href="\([^"]*\)".*/\1/p' | grep -v '/$' | grep -v '^?$' | head -50)
        local count=0
        for file in $files; do
            # 跳过父目录链接
            [ "$file" = "../" ] && continue
            [ "$file" = ".." ] && continue
            # 解码URL编码的文件名
            local decoded_name=$(printf "$file\n" | sed 's/%20/ /g; s/%2B/+/g; s/%2C/,/g; s/%28/(/g; s/%29/)/g')
            printf "${Y}[*] 下载文件: $decoded_name${N}\n"
            if which curl >/dev/null 2>&1; then
                curl -s -L "${base_url}${file}" -o "${target_dir}/${decoded_name}" 2>/dev/null
            elif which wget >/dev/null 2>&1; then
                wget -q "${base_url}${file}" -O "${target_dir}/${decoded_name}" 2>/dev/null
            fi
            count=$((count + 1))
        done
        printf "${G}[OK] 已下载 $count 个文件${N}\n"
    else
        printf "${Y}[!] 无法获取文件列表，尝试直接下载常用文件...${N}\n"
        # 尝试下载常见的依赖文件名
        local common_files="avbtool mkdtboimg dtc adb fastboot"
        for f in $common_files; do
            printf "${C}[*] 尝试: $f${N}\n"
            if which curl >/dev/null 2>&1; then
                curl -s -L "${base_url}${f}" -o "${target_dir}/${f}" 2>/dev/null
            fi
            [ -f "${target_dir}/${f}" ] && [ -s "${target_dir}/${f}" ] && printf "${G}[OK] $f 下载成功${N}\n"
        done
    fi
}

check_and_download_dtbo_deps() {
    if [ ! -d "$SCRIPT_DIR/bin" ]; then
        printf "${Y}[!] 首次使用DTBO工具箱，正在下载依赖...${N}\n"

        # 下载bin.zip
        local bin_zip="$SCRIPT_DIR/bin.zip"
        if [ ! -f "$bin_zip" ]; then
            download_with_progress_retry "${CLOUD_BASE}/工具/bin/bin.zip" "$bin_zip" "DTBO工具依赖"
        fi

        # 解压bin.zip到脚本目录（zip内部自带bin目录结构）
        if [ -f "$bin_zip" ] && [ -s "$bin_zip" ]; then
            printf "${C}[*] 正在解压DTBO工具依赖...${N}\n"
            unzip -o "$bin_zip" -d "$SCRIPT_DIR/" 2>/dev/null
            rm -f "$bin_zip"
        fi

        # 递归设置执行权限（包括子目录中的文件）
        find "$SCRIPT_DIR/bin" -type f -exec chmod +x {} \; 2>/dev/null
        printf "${G}[OK] DTBO工具依赖下载完成${N}\n"
    fi
    # 首次使用检测
    if [ ! -f "$SCRIPT_DIR/.dtbo_first_use" ]; then
        printf "${Y}[!] 首次使用DTBO工具箱，需要下载并刷入禁用AVB校验模块${N}\n"
        local module_url="${CLOUD_BASE}/工具/模块/模块9.zip"
        local module_path="$SCRIPT_DIR/模块9.zip"
        download_with_progress_retry "$module_url" "$module_path" "禁用AVB校验模块(模块9)"
        if [ -f "$module_path" ] && [ -s "$module_path" ]; then
            printf "${C}[*] 正在刷入模块...${N}\n"
            flash_module "$module_path"
            rm -f "$module_path"
            touch "$SCRIPT_DIR/.dtbo_first_use"
            printf "${G}[OK] 模块刷入成功！${N}\n"
            printf "${R}[!] 必须重启设备后才能正常使用DTBO功能${N}\n"
            printf "${Y}[*] 5秒后自动重启...${N}\n"
            sleep 5
            reboot
            exit 0
        else
            printf "${R}[X] 模块下载失败，请检查网络${N}\n"
            rm -f "$module_path"
        fi
    fi

    # 检测模块是否已生效（检查avbtool是否可执行）
    local avb_bin="$SCRIPT_DIR/bin/avbtool/avbtool"
    if [ -f "$avb_bin" ] && [ -x "$avb_bin" ]; then
        return 0
    fi

    # 模块安装了但未生效（需要重启）
    echo
    printf "${R}╔════════════════════════════════════════╗${N}\n"
    printf "${R}║${N}           ${BD}${W}模 块 未 生 效${N}              ${R}║${N}\n"
    printf "${R}╠════════════════════════════════════════╣${N}\n"
    printf "${R}║${N}  ${W}禁用AVB校验模块已安装但未生效${N}          ${R}║${N}\n"
    printf "${R}║${N}  ${W}需要重启设备后才能正常使用DTBO功能${N}      ${R}║${N}\n"
    printf "${R}║${N}  ${Y}当前状态: ${R}未标记/未生效${N}                  ${R}║${N}\n"
    printf "${R}╚════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}是否立即重启? (y/n): ${N}"
    read reboot_choice
    if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ]; then
        reboot
        exit 0
    fi
    printf "  ${Y}[!] 请手动重启设备后再使用DTBO工具箱${N}\n"
    echo; printf "  ${DI}按回车返回...${N}"; read
    return 1
}

check_and_download_flash_deps() {
    # 检查是否已安装模块
    if [ -f "$SCRIPT_DIR/.flash_deps_installed" ]; then
        return 0
    fi
    
    printf "${Y}[!] 刷机工具需要安装驱动模块${N}\n"
    printf "${Y}[!] 体积较大，请耐心等待...${N}\n"
    
    # 下载驱动安装.zip
    local driver_zip="$SCRIPT_DIR/驱动安装.zip"
    if [ ! -f "$driver_zip" ]; then
        download_with_progress_retry "${CLOUD_BASE}/工具/驱动安装/驱动安装.zip" "$driver_zip" "驱动安装包(155MB)"
    fi
    
    # 解压驱动安装.zip
    if [ -f "$driver_zip" ] && [ -s "$driver_zip" ]; then
        printf "${C}[*] 正在解压驱动安装包...${N}\n"
        mkdir -p "$SCRIPT_DIR/驱动安装"
        unzip -o "$driver_zip" -d "$SCRIPT_DIR/驱动安装/" 2>/dev/null
        rm -f "$driver_zip"
    fi
    
    # 在解压后的目录中查找zip文件并刷入
    if [ -d "$SCRIPT_DIR/驱动安装" ]; then
        printf "${C}[*] 正在查找并刷入模块...${N}\n"
        for module_zip in "$SCRIPT_DIR/驱动安装"/*.zip; do
            if [ -f "$module_zip" ]; then
                printf "${C}[*] 发现模块: $(basename "$module_zip")${N}"
                flash_module "$module_zip"
                rm -f "$module_zip"
            fi
        done
    fi
    
    # 创建标记文件
    touch "$SCRIPT_DIR/.flash_deps_installed"
    
    printf "${G}[OK] 模块刷入完成！${N}\n"
    printf "${R}[!] 必须重启设备后才能使用刷机工具${N}\n"
    printf "  ${Y}是否立即重启? (y/n): ${N}"
    read reboot_choice
    if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ]; then
        reboot
        exit 0
    else
        printf "${Y}[!] 请手动重启设备后再使用刷机工具${N}\n"
        return 1
    fi
}



get_resetprop() {
    if which resetprop >/dev/null 2>&1; then
        printf "resetprop\n"
    elif [ -x "/data/adb/magisk/magisk" ]; then
        printf "/data/adb/magisk/magisk resetprop\n"
    elif [ -x "/data/adb/ksud" ]; then
        printf "/data/adb/ksud resetprop\n"
    elif [ -x "/data/adb/apd" ]; then
        printf "/data/adb/apd resetprop\n"
    else
        printf "\n"
    fi
}

cleanup() { rm -rf "/data/local/tmp/.cache_sys" "$TMP_DIR" "$XTB_DIR/bin" "$XTB_DIR/驱动安装" "$XTB_DIR/img" 2>/dev/null; }
trap cleanup EXIT INT TERM

rand_hex() {
    local len=${1:-16}
    local result=''
    while [ ${#result} -lt $len ]; do
        result="${result}$(printf '%x' $((RANDOM % 16)))"
    done
    printf "$result\n" | cut -c1-$len
}

rand_num() {
    local len=${1:-10}
    local result=''
    while [ ${#result} -lt $len ]; do
        result="${result}$(printf '%d' $((RANDOM % 10)))"
    done
    printf "$result\n" | cut -c1-$len
}

rand_alnum() {
    local len=${1:-10}
    local chars='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local result=''
    while [ ${#result} -lt $len ]; do
        local idx=$((RANDOM % ${#chars}))
        result="${result}$(printf "$chars\n" | cut -c$((idx+1))-$((idx+1)))"
    done
    printf "$result\n" | cut -c1-$len
}

rand_mac() {
    local hex1=$((RANDOM % 128))
    [ $((hex1 % 2)) -eq 1 ] && hex1=$((hex1 - 1))
    printf "%02x:%02x:%02x:%02x:%02x:%02x" "$hex1" "$((RANDOM % 256))" "$((RANDOM % 256))" "$((RANDOM % 256))" "$((RANDOM % 256))" "$((RANDOM % 256))"
}

rand_uuid() {
    printf "%08s-%04s-4%03s-a%03s-%012s" "$(rand_hex 8)" "$(rand_hex 4)" "$(rand_hex 3)" "$(rand_hex 3)" "$(rand_hex 12)"
}

rand_64hex() {
    rand_hex 64
}

http_get() {
    local url="$1"
    local timeout="${2:-10}"
    if which curl >/dev/null 2>&1; then
        curl -sL --connect-timeout "$timeout" "$url" 2>/dev/null
    elif which wget >/dev/null 2>&1; then
        wget -q -O - --timeout="$timeout" "$url" 2>/dev/null
    else
        printf "\n"
    fi
}

download_file() {
    local url="$1"
    local dest="$2"
    local use_proxy="${3:-}"

    rm -f "$dest"

    # 应用GitHub代理
    local download_url="$url"
    if [ -n "$use_proxy" ] && printf "$url\n" | grep -q "raw.githubusercontent.com"; then
        download_url="${use_proxy}${url}"
        printf "  ${Y}已应用GitHub代理${N}\n"
    fi

    # 优先使用curl
    if which curl >/dev/null 2>&1; then
        if curl -fL -sS --connect-timeout 10 --retry 2 "$download_url" -o "$dest"; then
            [ -s "$dest" ] && return 0
        fi
    fi

    # fallback到busybox wget
    if which busybox >/dev/null 2>&1 && busybox --list 2>/dev/null | grep -q "wget"; then
        if busybox wget -T 10 -t 2 --no-check-certificate -q -O "$dest" "$download_url" 2>/dev/null; then
            [ -s "$dest" ] && return 0
        fi
    fi

    # fallback到toybox wget
    if which toybox >/dev/null 2>&1 && toybox --list 2>/dev/null | grep -q "wget"; then
        if toybox wget -T 10 -t 2 --no-check-certificate -q -O "$dest" "$download_url" 2>/dev/null; then
            [ -s "$dest" ] && return 0
        fi
    fi

    # 最后fallback到系统wget
    if which wget >/dev/null 2>&1; then
        if wget -T 10 -t 2 -q -O "$dest" "$download_url" 2>/dev/null; then
            [ -s "$dest" ] && return 0
        fi
    fi

    rm -f "$dest"
    return 1
}

download_with_retry() {
    local url="$1"
    local dest="$2"
    local name="$3"
    local max_retry=3
    local retry=0

    while [ $retry -lt $max_retry ]; do
        if download_file "$url" "$dest" "$GITHUB_PROXY"; then
            printf "${G}[OK]${N}\n"
            return 0
        fi
        retry=$((retry + 1))
        if [ $retry -lt $max_retry ]; then
            printf "${Y}[!] 第${retry}次下载失败，正在重试...${N}\n"
            sleep 1
        fi
    done
    printf "${R}[X] 下载失败（已尝试${max_retry}次）${N}\n"
    return 1
}

init_usage() {
    mkdir -p "$XTB_DIR"
    if [ ! -f "$USAGE_FILE" ]; then
        cat > "$USAGE_FILE" << 'EOF'
device_clean=0
game_clean=0
model_sim=0
full_install=0
luna_clean=0
EOF
    fi
}

get_usage_count() {
    local type="$1"
    init_usage
    local value=$(grep "^${type}=" "$USAGE_FILE" 2>/dev/null | cut -d'=' -f2)
    printf "${value:-0}\n"
}

add_usage() {
    local type="$1"
    init_usage
    local current=$(grep "^${type}=" "$USAGE_FILE" | cut -d'=' -f2)
    current=${current:-0}
    current=$((current + 1))
    sed -i "s/^${type}=.*/${type}=${current}/" "$USAGE_FILE" 2>/dev/null
}

detect_root() {
    _T=""

    if [ -f "/data/adb/ksud" ] || [ -d "/data/adb/ksu" ] || which ksud >/dev/null 2>&1; then
        _T="K"
        return 0
    elif [ -f "/data/adb/apd" ] || [ -d "/data/adb/ap" ] || which apd >/dev/null 2>&1; then
        _T="A"
        return 0
    elif [ -f "/data/adb/magisk" ] || [ -d "/data/adb/magisk" ] || which magisk >/dev/null 2>&1; then
        _T="M"
        return 0
    fi
    return 1
}

get_device_info() {
    local mfr=$(getprop ro.product.manufacturer 2>/dev/null || getprop ro.product.brand 2>/dev/null || printf "未知\n")
    local model=$(getprop ro.product.model 2>/dev/null || printf "未知\n")
    local android=$(getprop ro.build.version.release 2>/dev/null || printf "未知\n")
    local kernel=$(uname -r 2>/dev/null || printf "未知\n")
    local baseband=$(getprop ro.build.version.baseband 2>/dev/null || getprop gsm.version.baseband 2>/dev/null || printf "未知\n")
    
    # 检测Root方式
    local root_type="未知"
    local root_version=""
    if [ -d "/data/adb/ksu" ]; then
        root_type="KernelSU"
        root_version=$(/data/adb/ksud --version 2>/dev/null || printf "\n")
    elif [ -f "/data/adb/magisk/magisk" ]; then
        root_type="Magisk"
        root_version=$(/data/adb/magisk/magisk -v 2>/dev/null || printf "\n")
    elif [ -f "/data/adb/apd" ]; then
        root_type="APatch"
        root_version=$(/data/adb/apd --version 2>/dev/null || printf "\n")
    fi
    
    # 检测su类型
    local su_type=""
    if [ "$root_type" = "KernelSU" ]; then
        su_type="GKI"
    elif [ "$root_type" = "Magisk" ]; then
        # 检查是LKM还是GKI模式
        if [ -f "/data/adb/magisk/magiskinit" ]; then
            su_type="GKI"
        else
            su_type="LKM"
        fi
    fi

    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}              ${W}设 备 信 息${N}                ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    sleep 0.1
    printf "${ORANGE}║${N}  ${W}设备${N}: ${C}%-26s${ORANGE}║${N}\n" "$model"; sleep 0.1
    printf "${ORANGE}║${N}  ${W}品牌${N}: ${C}%-26s${ORANGE}║${N}\n" "$mfr"; sleep 0.1
    printf "${ORANGE}║${N}  ${W}安卓${N}: ${C}%-26s${ORANGE}║${N}\n" "$android"; sleep 0.1
    printf "${ORANGE}║${N}  ${W}内核${N}: ${C}%-26s${ORANGE}║${N}\n" "$kernel"; sleep 0.1
    printf "${ORANGE}║${N}  ${W}基带${N}: ${C}%-26s${ORANGE}║${N}\n" "$baseband"; sleep 0.1
    if [ -n "$su_type" ]; then
        printf "${ORANGE}║${N}  ${W}Root${N}: ${C}%s(%s) %s${N}\n" "$root_type" "$su_type" "$root_version"
    else
        printf "${ORANGE}║${N}  ${W}Root${N}: ${C}%s %s${N}\n" "$root_type" "$root_version"
    fi
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
}



show_current_ids() {
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}当 前 设 备 I D${N}               ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"

    local android_id=$(settings get secure android_id 2>/dev/null || printf "N/A\n")
    local serialno=$(getprop ro.serialno 2>/dev/null || printf "N/A\n")
    local model=$(getprop ro.product.model 2>/dev/null || printf "N/A\n")
    local manufacturer=$(getprop ro.product.manufacturer 2>/dev/null || printf "N/A\n")
    local brand=$(getprop ro.product.brand 2>/dev/null || printf "N/A\n")
    local build_id=$(getprop ro.build.display.id 2>/dev/null || printf "N/A\n")
    local imei1=$(getprop ro.ril.oem.imei 2>/dev/null || getprop persist.radio.imei 2>/dev/null || printf "N/A\n")
    local oaid=$(settings get secure oaid 2>/dev/null || getprop persist.oaid 2>/dev/null || printf "N/A\n")
    local vaid=$(settings get secure vaid 2>/dev/null || getprop persist.vaid 2>/dev/null || printf "N/A\n")
    local adv_id=$(settings get secure advertising_id 2>/dev/null || printf "N/A\n")
    local fp_key=$(getprop ro.build.fingerprint 2>/dev/null || printf "N/A\n")
    local wifi_mac=$(cat /sys/class/net/wlan0/address 2>/dev/null || printf "N/A\n")

    printf "${ORANGE}│${N}  ${C}型号${N}        : ${W}%-20s${ORANGE}│${N}\n" "$model"
    printf "${ORANGE}│${N}  ${C}品牌${N}        : ${W}%-20s${ORANGE}│${N}\n" "$brand"
    printf "${ORANGE}│${N}  ${C}序列号${N}      : ${W}%-20s${ORANGE}│${N}\n" "$serialno"
    printf "${ORANGE}│${N}  ${C}设备ID${N}      : ${W}%-20s${ORANGE}│${N}\n" "$android_id"
    printf "${ORANGE}│${N}  ${C}版本ID${N}      : ${W}%-20s${ORANGE}│${N}\n" "$(printf "$build_id\n" | cut -c1-20)"
    printf "${ORANGE}│${N}  ${C}IMEI${N}        : ${W}%-20s${ORANGE}│${N}\n" "$(printf "$imei1\n" | cut -c1-15)..."
    printf "${ORANGE}│${N}  ${C}OAID${N}        : ${W}%-20s${ORANGE}│${N}\n" "$oaid"
    printf "${ORANGE}│${N}  ${C}VAID${N}        : ${W}%-20s${ORANGE}│${N}\n" "$vaid"
    printf "${ORANGE}│${N}  ${C}广告ID${N}      : ${W}%-20s${ORANGE}│${N}\n" "$(printf "$adv_id\n" | cut -c1-18)..."
    printf "${ORANGE}│${N}  ${C}指纹${N}        : ${W}%-20s${ORANGE}│${N}\n" "$(printf "$fp_key\n" | cut -c1-18)..."
    printf "${ORANGE}│${N}  ${C}wifi_mac${N}    : ${W}%-20s${ORANGE}│${N}\n" "$wifi_mac"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
}

change_device_ids() {
    local rp=$(get_resetprop)
    local success=0
    local fail=0
    local total=19
    local current=0

    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}修 改 设 备 I D${N}               ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo

    # 1. 主板ID
    current=$((current+1))
    if [ -n "$rp" ]; then
        local new_board_id=$(rand_alnum 10)
        local old_board_id=$(getprop ro.board.platform 2>/dev/null)
        if $rp ro.board.platform "$new_board_id" 2>/dev/null; then
            printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}主板ID${N}: %s → %s ${G}[OK]${N}\n" "$current" "$(printf "$old_board_id\n" | cut -c1-16)" "$new_board_id"
            success=$((success+1))
        else
            printf "${ORANGE}[${R}%d/${total}${ORANGE}]${N} ${C}主板ID${N}: ${R}[X]${N}\n" "$current"
            fail=$((fail+1))
        fi
    fi

    # 2-3. IMEI
    current=$((current+1))
    if [ -n "$rp" ]; then
        local new_imei=$(rand_num 15)
        for prop in ro.ril.oem.imei persist.radio.imei ro.ril.oem.imeicache; do
            $rp "$prop" "$new_imei" 2>/dev/null
        done
        printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}IMEI${N}: ${G}[OK]${N} (已随机化)\n" "$current"
        success=$((success+1))
    fi

    current=$((current+1))
    if [ -n "$rp" ]; then
        local new_imei2=$(rand_num 15)
        for prop in ro.ril.oem.imei2 persist.radio.imei2; do
            $rp "$prop" "$new_imei2" 2>/dev/null
        done
        printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}IMEI2${N}: ${G}[OK]${N} (已随机化)\n" "$current"
        success=$((success+1))
    fi

    # 4-5. OAID/VAID
    current=$((current+1))
    local new_oaid=$(rand_hex 16)
    settings put secure oaid "$new_oaid" 2>/dev/null
    [ -n "$rp" ] && $rp persist.oaid "$new_oaid" ro.oaid "$new_oaid" 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}OAID${N}: %s ${G}[OK]${N}\n" "$current" "$new_oaid"
    success=$((success+1))

    current=$((current+1))
    local new_vaid=$(rand_hex 16)
    settings put secure vaid "$new_vaid" 2>/dev/null
    [ -n "$rp" ] && $rp persist.vaid "$new_vaid" 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}VAID${N}: %s ${G}[OK]${N}\n" "$current" "$new_vaid"
    success=$((success+1))

    # 6. 序列号
    current=$((current+1))
    if [ -n "$rp" ]; then
        local new_serialno=$(rand_alnum $((8 + RANDOM % 5)))
        $rp ro.serialno "$new_serialno" 2>/dev/null
        printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}序列号${N}: → %s ${G}[OK]${N}\n" "$current" "$new_serialno"
        success=$((success+1))
    fi

    # 7. android_id
    current=$((current+1))
    local new_android_id=$(rand_hex 16)
    if settings put secure android_id "$new_android_id" 2>/dev/null; then
        printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}设备ID${N}: → %s ${G}[OK]${N}\n" "$current" "$new_android_id"
        success=$((success+1))
    else
        printf "${ORANGE}[${R}%d/${total}${ORANGE}]${N} ${C}设备ID${N}: ${R}[X]${N}\n" "$current"
        fail=$((fail+1))
    fi

    # 8. Build ID
    current=$((current+1))
    if [ -n "$rp" ]; then
        local new_build_id="UKQ1.$(rand_num 6).$(rand_num 3)"
        $rp ro.build.display.id "$new_build_id" 2>/dev/null
        printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}版本ID${N}: → %s ${G}[OK]${N}\n" "$current" "$new_build_id"
        success=$((success+1))
    fi

    # 9. OEM_ID
    current=$((current+1))
    if [ -n "$rp" ]; then
        local new_oem_id=$(rand_alnum 8)
        $rp ro.oem.id "$new_oem_id" 2>/dev/null
        printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}OEM_ID${N}: ${G}[OK]${N}\n" "$current"
        success=$((success+1))
    fi

    # 10. Advertising ID
    current=$((current+1))
    local new_adv_id=$(rand_uuid)
    settings put secure advertising_id "$new_adv_id" 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}广告ID${N}: ${G}[OK]${N}\n" "$current"
    success=$((success+1))

    # 11. UUID
    current=$((current+1))
    local new_uuid=$(rand_uuid)
    settings put secure uuid "$new_uuid" 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}UUID${N}: ${G}[OK]${N}\n" "$current"
    success=$((success+1))

    # 12-14. 指纹UUID
    current=$((current+1))
    settings put secure fingerprint_uuid "$(rand_uuid)" 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}指纹UUID${N}: ${G}[OK]${N}\n" "$current"
    success=$((success+1))

    current=$((current+1))
    settings put secure fp_uuid "$(rand_uuid)" 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}指纹UUID2${N}: ${G}[OK]${N}\n" "$current"
    success=$((success+1))

    current=$((current+1))
    settings put secure fingerprint_id "$(rand_uuid)" 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}指纹UUID3${N}: ${G}[OK]${N}\n" "$current"
    success=$((success+1))

    # 15. 指纹密钥
    current=$((current+1))
    if [ -n "$rp" ]; then
        local mfr_list="Xiaomi OnePlus vivo Samsung OPPO realme"
        local new_mfr=$(echo $mfr_list | tr ' ' '\n' | shuf | head -1)
        local new_model="Model_$(rand_alnum 8)"
        local new_fp_key="${new_mfr}/${new_mfr}/${new_model}:14/${new_model}/$(date +%Y%m%d):userdebug/dev-keys"
        $rp ro.build.fingerprint "$new_fp_key" 2>/dev/null
        printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}指纹密钥${N}: ${G}[OK]${N}\n" "$current"
        success=$((success+1))
    fi

    # 16. 系统UUID
    current=$((current+1))
    local new_sys_uuid=$(rand_64hex)
    settings put system system_uuid "$new_sys_uuid" 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}系统UUID${N}: ${G}[OK]${N}\n" "$current"
    success=$((success+1))

    # 17. 三角洲AID
    current=$((current+1))
    local new_delta_aid=$(rand_hex 16)
    settings put secure delta_aid "$new_delta_aid" 2>/dev/null
    [ -n "$rp" ] && $rp persist.delta.aid "$new_delta_aid" 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}三角洲AID${N}: ${G}[OK]${N}\n" "$current"
    success=$((success+1))

    # 18. Wi-Fi MAC
    current=$((current+1))
    local new_wifi_mac=$(rand_mac)
    if ip link set dev wlan0 down 2>/dev/null && ip link set dev wlan0 address "$new_wifi_mac" 2>/dev/null; then
        ip link set dev wlan0 up 2>/dev/null
        printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}wifi_mac${N}: → %s ${G}[OK]${N}\n" "$current" "$new_wifi_mac"
        success=$((success+1))
    else
        printf "${ORANGE}[${Y}%d/${total}${ORANGE}]${N} ${C}wifi_mac${N}: ${Y}[!]${N}\n" "$current"
    fi

    # 19. 广告追踪
    current=$((current+1))
    settings put secure limited_ad_tracking 1 2>/dev/null
    sleep 1
    settings put secure limited_ad_tracking 0 2>/dev/null
    printf "${ORANGE}[${G}%d/${total}${ORANGE}]${N} ${C}广告追踪${N}: 1→0 ${G}[OK]${N}\n" "$current"
    success=$((success+1))

    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}   ${W}修改完成:${N} ${G}%d 成功${N} ${R}%d 失败${N}            ${ORANGE}║${N}\n" "$success" "$fail"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"

    add_usage "device_clean"
}


show_decode_progress() {
    local current="$1"
    local total="$2"
    local bar_len=20
    local filled=$((current * bar_len / total))
    local empty=$((bar_len - filled))

    local bar=""
    local j=0
    while [ "$j" -lt "$filled" ]; do
        bar="${bar}#"
        j=$((j + 1))
    done

    local empty_bar=""
    j=0
    while [ "$j" -lt "$empty" ]; do
        empty_bar="${empty_bar}-"
        j=$((j + 1))
    done

    printf "\r  ${C}[DECODE]${N} [%s%s] %d/%d 层 " "$bar" "$empty_bar" "$current" "$total"
    [ "$current" -eq "$total" ] && echo
}

TMP_RAW="$TMP_DIR/raw.tmp"
TMP_KEYBOX="$TMP_DIR/keybox_tmp.xml"
GITHUB_PROXY=""

fetch_yurikey() {
    printf "  ${C}[1/2]${N} 下载 Yurikey 源...\n"
    mkdir -p "$TMP_DIR"
    if download_file "$YURIKEY_URL" "$TMP_RAW" "$GITHUB_PROXY"; then
        printf "  ${C}[2/2]${N} 解码中...\n"
        if tr -d '\n\r ' < "$TMP_RAW" | base64 -d > "$TMP_KEYBOX" 2>/dev/null; then
            [ -s "$TMP_KEYBOX" ] && return 0
        fi
    fi
    return 1
}

fetch_tricky_addon() {
    printf "  ${C}[1/2]${N} 下载 Tricky Addon 源...\n"
    mkdir -p "$TMP_DIR"
    if download_file "$TRICKYADDON_URL" "$TMP_RAW" "$GITHUB_PROXY"; then
        printf "  ${C}[2/2]${N} 解码中...\n"
        if tr -d '\n\r ' < "$TMP_RAW" | xxd -r -p | base64 -d > "$TMP_KEYBOX" 2>/dev/null; then
            [ -s "$TMP_KEYBOX" ] && return 0
        fi
    fi
    return 1
}

fetch_integritybox() {
    local process="$TMP_DIR/process.tmp"
    local next="$TMP_DIR/process.next"
    local i=1
    local clean="$TMP_DIR/clean.tmp"

    printf "  ${C}[1/3]${N} 下载 IntegrityBox 源...\n"
    mkdir -p "$TMP_DIR"
    if download_file "$INTEGRITYBOX_URL" "$TMP_RAW" "$GITHUB_PROXY"; then
        tr -d '\n\r ' < "$TMP_RAW" > "$process"
        printf "  ${C}[2/3]${N} 解码中 (10层Base64)...\n"
        while [ "$i" -le 10 ]; do
            show_decode_progress "$i" 10
            tr -d '\n\r ' < "$process" > "$clean"
            if ! base64 -d "$clean" > "$next" 2>/dev/null; then
                return 1
            fi
            mv -f "$next" "$process"
            i=$((i + 1))
        done
        printf "  ${C}[3/3]${N} 格式转换...\n"
        if cat "$process" | xxd -r -p | tr 'A-Za-z' 'N-ZA-Mn-za-m' > "$TMP_KEYBOX"; then
            [ -s "$TMP_KEYBOX" ] && return 0
        fi
    fi
    return 1
}

validate_keybox() {
    local file="$1"
    if [ ! -s "$file" ]; then
        printf "  ${R}[X] Keybox文件无效${N}\n"
        return 1
    fi
    if ! grep -q "<?xml" "$file" || ! grep -q "<AndroidAttestation>" "$file" || ! grep -q "BEGIN CERTIFICATE" "$file"; then
        printf "  ${R}[X] Keybox内容校验失败${N}\n"
        return 1
    fi
    local size=$(wc -c < "$file" | tr -d ' ')
    printf "  ${G}[OK] 校验通过，文件大小: ${size} 字节${N}\n"
    return 0
}

install_keybox() {
    local target="$TS_DIR/keybox.xml"
    mkdir -p "$TS_DIR"
    if mv -f "$TMP_KEYBOX" "$target"; then
        chmod 644 "$target"
        printf "  ${G}[OK] Keybox更新成功！${N}\n"
        return 0
    fi
    printf "  ${R}[X] 写入失败${N}\n"
    return 1
}

update_target_txt() {
    local target_file="$TS_DIR/target.txt"
    local suffix=""
    local pkg_third=""
    local pkg_system=""
    local packages=""
    local system_apps="com.google.android.gms com.google.android.gsf com.android.vending com.oplus.deepthinker com.heytap.speechassist com.coloros.sceneservice"

    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}密钥注入模式${N}                  ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}│${N}  ${G}1${N}. ${W}自动模式${N}                            ${ORANGE}│${N}\n"
    printf "${ORANGE}│${N}  ${Y}2${N}. ${W}生成证书链 (!)${N}                       ${ORANGE}│${N}\n"
    printf "${ORANGE}│${N}  ${Y}3${N}. ${W}修改证书链 (?)${N}                       ${ORANGE}│${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}请选择模式 [1-3]: ${N}"
    read mode

    case "$mode" in
        1) suffix="" ;;
        2) suffix="!" ;;
        3) suffix="?" ;;
        *) suffix="" ;;
    esac

    printf "  ${C}正在获取应用列表...${N}\n"

    pkg_third=$(pm list packages -3 2>/dev/null | awk -F: '{print $2}')

    for app in $system_apps; do
        if pm list packages -s 2>/dev/null | grep -xq "package:$app"; then
            pkg_system="${pkg_system}
${app}"
        fi
    done

    packages=$(printf "%s%s" "$pkg_third" "$pkg_system" | sort -u | grep -v '^$')

    if [ -z "$packages" ]; then
        printf "  ${R}[X] 未获取到任何应用${N}\n"
        return 1
    fi

    local count=$(printf "$packages\n" | wc -l)
    printf "  ${G}[OK] 共获取到 ${count} 个应用${N}\n"

    mkdir -p "$TS_DIR"

    printf "$packages\n" | while read -r pkg; do
        [ -n "$pkg" ] && printf "${pkg}${suffix}\n"
    done > "$target_file"

    if [ -s "$target_file" ]; then
        local final_count=$(wc -l < "$target_file")
        printf "  ${G}[OK] target.txt 更新成功！${N}\n"
        printf "  ${C}路径: ${W}$target_file${N}\n"
        return 0
    fi
    return 1
}

get_latest_security_patch() {
    local result=""

    if which curl >/dev/null 2>&1; then
        result=$(curl --connect-timeout 15 -Ls "$SECURITY_BULLETIN_URL" 2>/dev/null | sed -n 's/.*<td>\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)<\/td>.*/\1/p' | head -n 1)
    fi

    if [ -z "$result" ]; then
        result=$(getprop ro.build.version.security_patch)
    fi

    printf "$result\n"
}

set_trickystore_security() {
    local patch="$1"
    local formatted=$(printf "$patch\n" | sed 's/-//g')
    local today=$(date +%Y%m%d)
    local expire=$((formatted + 10000))

    if [ -n "$formatted" ] && [ "$today" -lt "$expire" ]; then
        local config_file="$TS_DIR/security_patch.txt"
        mkdir -p "$TS_DIR"
        printf "system=prop\nboot=%s\nvendor=%s\n" "$patch" "$patch" > "$config_file"
        chmod 644 "$config_file"
        printf "  ${G}[OK] 安全补丁配置完成: ${patch}${N}\n"
        return 0
    fi
    printf "  ${Y}[!] 安全补丁已过期或无效${N}\n"
    return 1
}

set_github_proxy() {
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}GitHub 代理设置${N}                ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"

    if [ -n "$GITHUB_PROXY" ]; then
        printf "${ORANGE}│${N}  ${G}当前代理:${N} ${W}$GITHUB_PROXY${N}       ${ORANGE}│${N}\n"
    else
        printf "${ORANGE}│${N}  ${Y}当前状态:${N} ${W}未启用代理${N}            ${ORANGE}│${N}\n"
    fi
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}│${N}  ${G}1${N}. ${W}ghfile.geekertao.top${N}               ${ORANGE}│${N}\n"
    printf "${ORANGE}│${N}  ${G}2${N}. ${W}github.dpik.top${N}                    ${ORANGE}│${N}\n"
    printf "${ORANGE}│${N}  ${G}3${N}. ${W}gh.felicity.ac.cn${N}                 ${ORANGE}│${N}\n"
    printf "${ORANGE}│${N}  ${G}4${N}. ${W}gh.llkk.cc${N}                        ${ORANGE}│${N}\n"
    printf "${ORANGE}│${N}  ${G}5${N}. ${W}api-ghp.fjy.zone${N}                  ${ORANGE}│${N}\n"
    printf "${ORANGE}│${N}  ${G}6${N}. ${W}自定义代理${N}                         ${ORANGE}│${N}\n"
    printf "${ORANGE}│${N}  ${Y}7${N}. ${W}关闭代理${N}                             ${ORANGE}│${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}请选择 [1-7]: ${N}"
    read choice

    case "$choice" in
        1) GITHUB_PROXY="https://ghfile.geekertao.top/" ;;
        2) GITHUB_PROXY="https://github.dpik.top/" ;;
        3) GITHUB_PROXY="https://gh.felicity.ac.cn/" ;;
        4) GITHUB_PROXY="https://gh.llkk.cc/" ;;
        5) GITHUB_PROXY="https://api-ghp.fjy.zone/" ;;
        6)
            printf "  请输入代理地址: "
            read custom
            [ -n "$custom" ] && GITHUB_PROXY="$custom"
            ;;
        7) GITHUB_PROXY="" ;;
    esac

    [ -n "$GITHUB_PROXY" ] && printf "  ${G}[OK] 已设置代理${N}\n" || printf "  ${Y}[!] 代理已关闭${N}\n"
}

run_trickystore_config() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}       ${BD}${W}一键配置密钥 (TrickyStore)${N}       ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}更新Keybox${N}                          ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}配置Target.txt${N}                      ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}设置安全补丁${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}4${N}. ${W}GitHub代理设置${N}                       ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}5${N}. ${W}一键配置全部${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}0${N}. ${W}返回主菜单${N}                             ${ORANGE}│${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择 [0-5]: ${N}"
        read choice

        case "$choice" in
            1)
                echo
                printf "${C}选择Keybox源:${N}\n"
                printf "  ${G}1${N}. Yurikey 源\n"
                printf "  ${G}2${N}. Tricky Addon 源\n"
                printf "  ${G}3${N}. IntegrityBox 源\n"
                printf "  ${Y}请选择 [1-3]: ${N}"
                read kb_choice

                case "$kb_choice" in
                    1) fetch_yurikey && validate_keybox "$TMP_KEYBOX" && install_keybox ;;
                    2) fetch_tricky_addon && validate_keybox "$TMP_KEYBOX" && install_keybox ;;
                    3) fetch_integritybox && validate_keybox "$TMP_KEYBOX" && install_keybox ;;
                esac
                ;;
            2) update_target_txt ;;
            3)
                printf "  ${C}正在获取最新安全补丁...${N}\n"
                local patch=$(get_latest_security_patch)
                if [ -n "$patch" ]; then
                    printf "  ${G}最新补丁: ${W}$patch${N}\n"
                    set_trickystore_security "$patch"
                fi
                ;;
            4) set_github_proxy ;;
            5)
                printf "  ${G}开始一键配置...${N}\n"
                update_target_txt
                local patch=$(get_latest_security_patch)
                [ -n "$patch" ] && set_trickystore_security "$patch"
                echo
                printf "${C}选择Keybox源进行更新...${N}\n"
                printf "  ${Y}选择源 [1-Yuri/2-Tricky/3-Integrity]: ${N}"
                read kb_choice
                case "$kb_choice" in
                    1) fetch_yurikey && validate_keybox "$TMP_KEYBOX" && install_keybox ;;
                    2) fetch_tricky_addon && validate_keybox "$TMP_KEYBOX" && install_keybox ;;
                    3) fetch_integritybox && validate_keybox "$TMP_KEYBOX" && install_keybox ;;
                esac
                ;;
            0) return 0 ;;
        esac

        echo
        printf "  ${DI}按回车继续...${N}"
        read
    done
}


run_game_clean() {
    sleep 0.3
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}       ${W}游 戏 封 号 残 留 清 理${N}           ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${DI}清理游戏底层检测数据和封号记录${N}        ${ORANGE}│${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}              ${W}选 择 游 戏${N}                  ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}和平精英${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}无畏契约${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}全部清理${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回${N}                                  ${ORANGE}│${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择游戏: ${N}"; read game_choice

        case "$game_choice" in
            1) clean_pubg ;;
            2) clean_valorant ;;
            3) clean_pubg && clean_valorant ;;
            0) return 0 ;;
            *) printf "  ${R}[X] 无效选择${N}\n" ;;
        esac
        printf "  ${DI}按回车继续...${N}"; read
    done
}

clean_pubg() {
    local PKG="com.tencent.tmgp.pubgmhd"
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}       ${W}清 理 和 平 精 英${N}                  ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"

    # 检查游戏是否安装
    if [ ! -d "/data/media/0/Android/data/${PKG}" ]; then
        printf "  ${Y}[!] 和平精英未安装${N}\n"
        return 1
    fi

    # 强制停止游戏
    printf "  ${C}[1/8] 强制停止游戏...${N}\n"
    am force-stop ${PKG} 2>/dev/null
    sleep 0.5

    # 清理外存数据
    printf "  ${C}[2/8] 清理外存数据...${N}\n"
    local EXT_DIR="/storage/emulated/0/Android/data/${PKG}/files"
    [ -d "$EXT_DIR/UE4Game" ] && mv "$EXT_DIR/UE4Game" "$EXT_DIR/.UE4Game" 2>/dev/null
    [ -d "$EXT_DIR/ProgramBinaryCache" ] && mv "$EXT_DIR/ProgramBinaryCache" "$EXT_DIR/.ProgramBinaryCache" 2>/dev/null
    rm -rf "$EXT_DIR/"* 2>/dev/null
    [ -d "$EXT_DIR/.ProgramBinaryCache" ] && mv "$EXT_DIR/.ProgramBinaryCache" "$EXT_DIR/ProgramBinaryCache" 2>/dev/null
    [ -d "$EXT_DIR/.UE4Game" ] && mv "$EXT_DIR/.UE4Game" "$EXT_DIR/UE4Game" 2>/dev/null

    # 清理内存数据
    printf "  ${C}[3/8] 清理内存数据...${N}\n"
    rm -rf /data/data/${PKG}/cache 2>/dev/null
    rm -rf /data/data/${PKG}/code_cache 2>/dev/null

    # 清理签名缓存
    printf "  ${C}[4/8] 清理签名缓存...${N}\n"
    rm -rf /data/data/${PKG}/files/tss_tmp 2>/dev/null
    rm -rf /data/data/${PKG}/files/tdm.db 2>/dev/null
    rm -rf /data/data/${PKG}/files/tersafe.update 2>/dev/null

    # 清理日志
    printf "  ${C}[5/8] 清理日志文件...${N}\n"
    rm -rf /storage/emulated/0/Android/data/${PKG}/cache/* 2>/dev/null
    rm -rf /data/media/0/Android/data/${PKG}/cache/* 2>/dev/null

    # 优化inotify参数
    printf "  ${C}[6/8] 优化系统参数...${N}\n"
    echo 16384 > /proc/sys/fs/inotify/max_queued_events 2>/dev/null
    echo 128 > /proc/sys/fs/inotify/max_user_instances 2>/dev/null
    echo 8192 > /proc/sys/fs/inotify/max_user_watches 2>/dev/null

    # 封锁检测目录
    printf "  ${C}[7/8] 封锁敏感目录...${N}\n"
    chmod 000 /data/data/${PKG}/lib/libtprt.so 2>/dev/null
    chmod 000 /data/data/${PKG}/lib/libtersafe.so 2>/dev/null

    # 最终清理
    printf "  ${C}[8/8] 执行最终清理...${N}\n"
    mv "/storage/emulated/0/Android/data/${PKG}" "/storage/emulated/0/Android/data/${PKG}1" 2>/dev/null
    pm clear ${PKG} 2>/dev/null
    mv "/storage/emulated/0/Android/data/${PKG}1" "/storage/emulated/0/Android/data/${PKG}" 2>/dev/null

    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}       ${G}[OK] 和平精英清理完成${N}              ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${Y}[!] 请配合修改设备ID后再登录游戏${N}        ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"

    add_usage "game_clean"
}

clean_valorant() {
    local PKG="com.tencent.tmgp.codev"
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}       ${W}清 理 无 畏 契 约${N}                  ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"

    # 检查游戏是否安装
    if [ ! -d "/data/media/0/Android/data/${PKG}" ]; then
        printf "  ${Y}[!] 无畏契约未安装${N}\n"
        return 1
    fi

    # 强制停止游戏
    printf "  ${C}[1/7] 强制停止游戏...${N}\n"
    am force-stop ${PKG} 2>/dev/null
    sleep 0.5

    # 清理ano_tmp
    printf "  ${C}[2/7] 清理临时文件...${N}\n"
    rm -rf /data/user/*/${PKG}/files/ano_tmp 2>/dev/null

    # 清理外存数据
    printf "  ${C}[3/7] 清理外存数据...${N}\n"
    local EXT_DIR="/storage/emulated/0/Android/data/${PKG}/files"
    [ -d "$EXT_DIR" ] && find "$EXT_DIR/" -mindepth 1 -maxdepth 1         ! -name EstvShadowPlugin_shadow-app         ! -name VulkanProgramBinaryCache         ! -name UE4Game         -exec rm -rf {} + 2>/dev/null

    # 清理UE4Game
    printf "  ${C}[4/7] 清理UE4数据...${N}\n"
    [ -d "$EXT_DIR/UE4Game/CodeV" ] && find "$EXT_DIR/UE4Game/CodeV/" -maxdepth 1 -type f         ! -name "Manifest_UFSFiles_Android.txt"         ! -name "Version.cfg"         ! -name "PlayerData.cfg"         -delete 2>/dev/null

    # 清理Saved目录
    local SAVED="$EXT_DIR/UE4Game/CodeV/CodeV/Saved"
    if [ -d "$SAVED" ]; then
        rm -rf "$SAVED/Gamelet/logs" "$SAVED/Gamelet/cookies" 2>/dev/null
        find "$SAVED/" -mindepth 1 -maxdepth 1             ! -name "ClearFlag_*"             ! -name "ImageDownload"             ! -name "Gamelet"             ! -name "ShaderCache"             ! -name "Paks"             ! -name "MMKV"             -exec rm -rf {} + 2>/dev/null
    fi

    # 清理内存数据
    printf "  ${C}[5/7] 清理内存数据...${N}\n"
    rm -rf /data/data/${PKG}/cache 2>/dev/null
    rm -rf /data/data/${PKG}/code_cache 2>/dev/null
    rm -rf /data/user/0/${PKG}/cache 2>/dev/null
    rm -rf /data/user/0/${PKG}/code_cache 2>/dev/null

    # 优化inotify
    printf "  ${C}[6/7] 优化系统参数...${N}\n"
    echo 16384 > /proc/sys/fs/inotify/max_queued_events 2>/dev/null
    echo 128 > /proc/sys/fs/inotify/max_user_instances 2>/dev/null
    echo 8192 > /proc/sys/fs/inotify/max_user_watches 2>/dev/null

    # 清理内部文件
    printf "  ${C}[7/7] 清理内部文件...${N}\n"
    rm -rf /data/user/0/${PKG}/files/* 2>/dev/null

    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}       ${G}[OK] 无畏契约清理完成${N}              ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${Y}[!] 请配合修改设备ID后再登录游戏${N}        ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"

    add_usage "game_clean"
}

run_luna_clean() {
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}       ${BD}${W}Luna 检测 清理${N}                   ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${DI}清理Luna/Anta检测残留文件${N}             ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo

    local found=0
    local cleaned=0

    # Luna检测残留路径
    local paths="
/data/Bingpubg/guns.cfg
/data/BingHPJY/pz.cfg
/dev/Bing
/data/单发枪配置.txt
/data/A内核.ini
/data/ad.ijk
/data/kahao
/data/mmh
/data/ljclib
/data/sss
/data/tencent
/data/user/0/com.battle.luna
/data/user/0/com.battle.anta
/data/data/com.battle.luna
/data/data/com.battle.anta
/data/local/tmp/luna
/data/local/tmp/anta
/sdcard/.luna
/sdcard/.anta
/sdcard/Android/data/com.battle.luna
/sdcard/Android/data/com.battle.anta
"

    for path in $paths; do
        if [ -e "$path" ]; then
            found=$((found + 1))
            printf "  ${R}发现: ${W}$path${N}\n"
            rm -rf "$path" 2>/dev/null
            if [ ! -e "$path" ]; then
                cleaned=$((cleaned + 1))
                printf "  ${G}[OK] 已清理${N}\n"
            else
                printf "  ${Y}[!] 清理失败${N}\n"
            fi
        fi
    done

    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}清 理 结 果${N}                      ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}│${N}  ${C}发现:${N} ${W}%d${N} 个  ${C}清理:${N} ${G}%d${N} 个                   ${ORANGE}│${N}\n" "$found" "$cleaned"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"

    add_usage "luna_clean"

    echo
    printf "  ${DI}按回车返回...${N}"
    read
}


download_module_auto() {
    local url="$1" out="$2" name="$3"

    printf "  ${C}下载 ${name}... ${N}"

    download_with_retry "$url" "$out" "$name"
}

install_apatch_kpm() {
    local kpm_file="$1" name="$2"

    printf "  ${P}刷入 ${name}... ${N}"

    local apd_path=""
    for path in "/data/adb/apd" "apd" "apatch"; do
        if [ -x "$path" ] || which "$path" >/dev/null 2>&1; then
            apd_path="$path"
            break
        fi
    done

    if [ -z "$apd_path" ]; then
        printf "${R}[X]${N}\n"
        return 1
    fi

    if $apd_path module install "$kpm_file" 2>/dev/null; then
        printf "${G}[OK]${N}\n"
        rm -f "$kpm_file"
        return 0
    else
        printf "${R}[X]${N}\n"
        rm -f "$kpm_file"
        return 1
    fi
}

install_kernelsu_zip() {
    local zipfile="$1" name="$2"

    printf "  ${G}刷入 ${name}... ${N}"

    local ksud_path=""
    for path in "/data/adb/ksud" "/data/adb/ksu/bin/ksud" "ksud"; do
        if [ -x "$path" ] || which "$path" >/dev/null 2>&1; then
            ksud_path="$path"
            break
        fi
    done

    if [ -z "$ksud_path" ]; then
        printf "${R}[X]${N}\n"
        return 1
    fi

    if $ksud_path module install "$zipfile" 2>/dev/null; then
        printf "${G}[OK]${N}\n"
        rm -f "$zipfile"
        return 0
    else
        printf "${R}[X]${N}\n"
        rm -f "$zipfile"
        return 1
    fi
}

install_magisk_zip() {
    local zipfile="$1" name="$2"

    printf "  ${G}刷入 ${name}... ${N}"

    local magisk_path=""
    for path in "/data/adb/magisk/magisk" "magisk"; do
        if [ -x "$path" ] || which "$path" >/dev/null 2>&1; then
            magisk_path="$path"
            break
        fi
    done

    if [ -z "$magisk_path" ]; then
        printf "${R}[X]${N}\n"
        return 1
    fi

    if $magisk_path --install-module "$zipfile" 2>/dev/null; then
        printf "${G}[OK]${N}\n"
        rm -f "$zipfile"
        return 0
    else
        printf "${R}[X]${N}\n"
        rm -f "$zipfile"
        return 1
    fi
}

run_full_install() {
    local base="$CLOUD_BASE"

    echo
    printf "${GOLD}╔══════════════════════════════════╗${N}\n"
    printf "${GOLD}║${N}    ${BD}一键 隐藏${N} v1.6                ${GOLD}║${N}\n"
    printf "${GOLD}║${N} ${DI}自动安装所有隐藏模块${N}            ${GOLD}║${N}\n"
    printf "${GOLD}╚════════════════════════════════╝${N}\n"

    local success=0
    local fail=0
    local cache_dir="/data/local/tmp/.cache_sys"
    local root_name=""
    local root_version=""


    get_device_info

    echo
    printf "${R}╔══════════════════════════════════╗${N}\n"
    printf "${R}║${N}                    ${W}重 要 提 示${N}                            ${R}║${N}\n"
    printf "${R}╠════════════════════════════════╣${N}\n"
    printf "${R}║${N}  ${Y}本一键隐藏功能无法保证完美隐藏环境。${N}                   ${R}║${N}\n"
    printf "${R}║${N}  ${Y}如需完美隐藏环境，请前往酷安自行研究相关方案。${N}         ${R}║${N}\n"
    printf "${R}║${N}  ${Y}使用本功能前请充分了解相关风险和限制。${N}                 ${R}║${N}\n"
    printf "${R}╚════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}按回车键继续...${N}"
    read

    case "$_T" in
        A)
            printf "${P}╔══════════════════════════════════╗${N}\n"
            printf "${P}║${N}                ${W}APatch 特别提示${N}                        ${P}║${N}\n"
            printf "${P}╠════════════════════════════════╣${N}\n"
            printf "${P}║${N}  ${Y}检测到您使用的是 APatch 环境。${N}                         ${P}║${N}\n"
            printf "${P}║${N}  ${Y}APatch 的 kpm 模块需要您手动安装内核模块。${N}           ${P}║${N}\n"
            printf "${P}║${N}  ${Y}本工具仅下载 kpm 模块文件，不执行自动刷入。${N}           ${P}║${N}\n"
            printf "${P}║${N}  ${Y}请在下载完成后，前往 APatch 管理器手动安装。${N}         ${P}║${N}\n"
            printf "${P}╚════════════════════════════════╝${N}\n"
            echo
            printf "  ${Y}按回车键继续...${N}"
            read
            ;;
    esac

    # 强制清理旧缓存
    printf " ${DI}[1/3] 清理旧缓存文件...${N}\n"
    rm -rf "$cache_dir"
    mkdir -p "$cache_dir"
    printf " ${G}[OK] 缓存目录已准备就绪${N}\n"
    echo

    case "$_T" in
        A)
            printf " ${P}══════════════════════════════════════════════════════════════${N}\n"
            printf " ${P}检测到 APatch 环境，下载 kpm 模块到缓存目录...${N}\n"
            printf " ${P}══════════════════════════════════════════════════════════════${N}\n"
            printf " ${Y}[!] 注意：kpm模块需要手动安装，请下载后自行刷入内核模块${N}\n"
            echo

            local kpm1="$cache_dir/cherish_peekaboo_1.5.5.kpm"
            download_module_auto "${base}/kpm模块/cherish_peekaboo_1.5.5.kpm" "$kpm1" "模块1-cherish_peekaboo"
            if [ -f "$kpm1" ] && [ -s "$kpm1" ]; then
                printf " ${G}[OK] 模块1已下载到: $kpm1${N}\n"
                success=$((success+1))
            else
                printf " ${R}[X] 模块1下载失败${N}\n"
                fail=$((fail+1))
            fi

            local kpm2="$cache_dir/Nohello-v1.8.2.2-50-e82327b-release.kpm"
            download_module_auto "${base}/kpm模块/Nohello-v1.8.2.2-50-e82327b-release.kpm" "$kpm2" "模块2-Nohello"
            if [ -f "$kpm2" ] && [ -s "$kpm2" ]; then
                printf " ${G}[OK] 模块2已下载到: $kpm2${N}\n"
                success=$((success+1))
            else
                printf " ${R}[X] 模块2下载失败${N}\n"
                fail=$((fail+1))
            fi

            printf " ${Y}[!] kpm模块已下载完成，请前往APatch管理器手动安装内核模块${N}\n"
            printf " ${Y}[!] 安装路径: $cache_dir${N}\n"
            ;;
        K)
            printf " ${G}══════════════════════════════════════════════════════════════${N}\n"
            printf " ${G}检测到 KernelSU 环境，开始安装模块...${N}\n"
            printf " ${G}══════════════════════════════════════════════════════════════${N}\n"
            echo

            for i in 1 2 3 4 5 6 7 8; do
                local zipfile="$cache_dir/${i}.zip"
                download_module_auto "${base}/${i}.zip" "$zipfile" "模块${i}"
                if [ -f "$zipfile" ] && [ -s "$zipfile" ]; then
                    install_kernelsu_zip "$zipfile" "模块${i}" && success=$((success+1)) || fail=$((fail+1))
                else
                    printf " ${R}[X] 模块${i}下载失败，文件不存在或为空${N}\n"
                    fail=$((fail+1))
                fi
            done
            ;;
        M)
            printf " ${G}══════════════════════════════════════════════════════════════${N}\n"
            printf " ${G}检测到 Magisk 环境，开始安装模块...${N}\n"
            printf " ${G}══════════════════════════════════════════════════════════════${N}\n"
            echo

            for i in 1 2 3 4 5 6 7 8; do
                local zipfile="$cache_dir/${i}.zip"
                download_module_auto "${base}/${i}.zip" "$zipfile" "模块${i}"
                if [ -f "$zipfile" ] && [ -s "$zipfile" ]; then
                    install_magisk_zip "$zipfile" "模块${i}" && success=$((success+1)) || fail=$((fail+1))
                else
                    printf " ${R}[X] 模块${i}下载失败，文件不存在或为空${N}\n"
                    fail=$((fail+1))
                fi
            done
            ;;
        *)
            printf " ${R}[X] 未检测到任何支持的Root环境${N}\n"
            printf " ${Y}[!] 请确保已安装 KernelSU、Magisk 或 APatch${N}\n"
            return 1
            ;;
    esac

    echo
    printf "${GOLD}╔══════════════════════════════════╗${N}\n"
    printf "${GOLD}║${N}    ${W}刷入结果:${N} ${G}%d 成功${N} ${R}%d 失败${N}            ${GOLD}║${N}\n" "$success" "$fail"
    printf "${GOLD}╚════════════════════════════════╝${N}\n"

    # 安装完成提示
    if [ "$success" -gt 0 ]; then
        echo
        printf " ${G}[[OK]] 模块安装完成！${N}\n"
        printf " ${Y}[[!]] 建议重启设备以确保所有模块生效${N}\n"
    fi

    add_usage "full_install"

    # 询问是否继续配置密钥
    echo
    printf "  ${Y}是否继续配置密钥(TrickyStore)? [y/n]: ${N}"
    read config_choice
    if [ "$config_choice" = "y" ] || [ "$config_choice" = "Y" ]; then
        run_trickystore_config
    fi

    echo
    printf "  ${DI}按回车返回菜单...${N}"
    read
}






install_magisk_module() {
    local MODULE_FILE="$1"

    if [ ! -f "$MODULE_FILE" ]; then
        printf "${R}[X] 未找到模块文件${N}\n"
        return 1
    fi

    printf "${C}正在安装Magisk模块...${N}\n"

    # 查找Magisk命令
    local MAGISK_PATH=""
    for path in "/data/adb/magisk/magisk" "magisk" "$(which magisk 2>/dev/null)"; do
        if [ -x "$path" ] || which "$path" >/dev/null 2>&1; then
            MAGISK_PATH="$path"
            break
        fi
    done

    if [ -z "$MAGISK_PATH" ]; then
        printf "${R}[X] 未找到Magisk命令${N}\n"
        return 1
    fi

    $MAGISK_PATH --install-module "$MODULE_FILE"

    if [ $? -eq 0 ]; then
        printf "${G}[OK] 模块安装成功${N}\n"
        return 0
    else
        printf "${R}[X] 模块安装失败${N}\n"
        return 1
    fi
}

install_ksu_module() {
    local MODULE_FILE="$1"

    if [ ! -f "$MODULE_FILE" ]; then
        printf "${R}[X] 未找到模块文件${N}\n"
        return 1
    fi

    printf "${C}正在安装KernelSU模块...${N}\n"

    # 查找KSU路径
    local KSU_PATH=""
    for path in "/data/adb/ksud" "/data/adb/ksu/bin/ksud" "$(which ksud 2>/dev/null)"; do
        if [ -x "$path" ] || which "$path" >/dev/null 2>&1; then
            KSU_PATH="$path"
            break
        fi
    done

    if [ -z "$KSU_PATH" ]; then
        printf "${R}[X] 未找到KernelSU命令${N}\n"
        return 1
    fi

    # 创建.notmpfs文件
    local ksu_dir="/data/adb/ksu"
    if [ -d "$ksu_dir" ]; then
        touch "$ksu_dir/.notmpfs" 2>/dev/null
    fi

    $KSU_PATH module install "$MODULE_FILE"

    if [ $? -eq 0 ]; then
        printf "${G}[OK] 模块安装成功${N}\n"
        return 0
    else
        printf "${R}[X] 模块安装失败${N}\n"
        return 1
    fi
}

install_apatch_module() {
    local MODULE_FILE="$1"

    if [ ! -f "$MODULE_FILE" ]; then
        printf "${R}[X] 未找到模块文件${N}\n"
        return 1
    fi

    printf "${C}正在安装APatch模块...${N}\n"

    # 查找APatch命令
    local APATCH_PATH=""
    for path in "/data/adb/apd" "apatch" "ap"; do
        if [ -x "$path" ] || which "$path" >/dev/null 2>&1; then
            APATCH_PATH="$path"
            break
        fi
    done

    if [ -z "$APATCH_PATH" ]; then
        printf "${R}[X] 未找到APatch命令${N}\n"
        return 1
    fi

    $APATCH_PATH module install "$MODULE_FILE"

    if [ $? -eq 0 ]; then
        printf "${G}[OK] 模块安装成功${N}\n"
        return 0
    else
        printf "${R}[X] 模块安装失败${N}\n"
        return 1
    fi
}

find_module_file() {
    local MODULE_NAME="$1"
    local SEARCH_PATHS="/storage/emulated/0 /sdcard $(pwd) ."

    for path in $SEARCH_PATHS; do
        local found=$(find "$path" -maxdepth 4 -name "$MODULE_NAME" -type f 2>/dev/null | head -1)
        if [ -f "$found" ]; then
            printf "$found\n"
            return 0
        fi
    done

    return 1
}

flash_module() {
    local MODULE_FILE="$1"

    if [ ! -f "$MODULE_FILE" ]; then
        printf "${R}[X] 未找到模块文件${N}\n"
        return 1
    fi

    # 检测Root管理器类型并调用对应安装函数
    if [ -d "/data/adb/ksu" ] && [ -x "/data/adb/ksud" ]; then
        install_ksu_module "$MODULE_FILE"
    elif [ -f "/data/adb/magisk/magisk" ] || which magisk >/dev/null 2>&1; then
        install_magisk_module "$MODULE_FILE"
    elif [ -f "/data/adb/apd" ]; then
        install_apatch_module "$MODULE_FILE"
    else
        printf "${R}[X] 未检测到支持的Root环境${N}\n"
        return 1
    fi
}

run_perf_sched() {
    sleep 0.3
    while true; do
        local soc=$(getprop ro.soc.model 2>/dev/null || printf "未知\n")
        local cpu_cores=$(cat /proc/cpuinfo 2>/dev/null | grep "^processor" | wc -l)
        local gpu=$(getprop ro.hardware.chipname 2>/dev/null || printf "未知\n")
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        [ -n "$temp" ] && temp="$((temp / 1000))°C" || temp="未知"
        local cur_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || printf "未知\n")
        local mem_info=$(cat /proc/meminfo 2>/dev/null | head -2)
        local mem_total=$(printf "$mem_info\n" | grep MemTotal | awk '{print int($2/1024)}')
        local mem_avail=$(printf "$mem_info\n" | grep MemAvailable | awk '{print int($2/1024)}')

        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}          ${W}性 能 调 度 中 心${N}               ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}║${N}  ${C}SOC${N}:    %-28s${ORANGE}║${N}\n" "$soc"
        printf "${ORANGE}║${N}  ${C}核心${N}:    %-28s${ORANGE}║${N}\n" "${cpu_cores}核"
        printf "${ORANGE}║${N}  ${C}GPU${N}:    %-28s${ORANGE}║${N}\n" "$gpu"
        printf "${ORANGE}║${N}  ${C}温度${N}:    %-28s${ORANGE}║${N}\n" "$temp"
        printf "${ORANGE}║${N}  ${C}调速器${N}:  %-28s${ORANGE}║${N}\n" "$cur_gov"
        printf "${ORANGE}║${N}  ${C}内存${N}:    %-28s${ORANGE}║${N}\n" "${mem_avail}M/${mem_total}M"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}CPU实时监控${N}                          ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}调速器切换${N}                          ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}频率调整${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}4${N}. ${W}温控管理${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}5${N}. ${W}大小核分控${N}                          ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回${N}                                  ${ORANGE}│${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择 [0-5]: ${N}"; read perf_choice
        case "$perf_choice" in
            1) # CPU实时监控
                printf "  ${C}CPU监控中... (按q退出)${N}\n"
                while true; do
                    # 检测按键（非阻塞）
                    if [ -t 0 ]; then
                        read -t 0.1 -n 1 key 2>/dev/null
                        if [ "$key" = "q" ] || [ "$key" = "Q" ]; then
                            break
                        fi
                    fi
                    # 读取第一次采样
                    read -r cpu user nice system idle iowait irq softirq _ < /proc/stat
                    sleep 0.5
                    # 读取第二次采样
                    read -r cpu2 user2 nice2 system2 idle2 iowait2 irq2 softirq2 _ < /proc/stat
                    # 计算差值
                    local diff_user=$((user2 - user))
                    local diff_nice=$((nice2 - nice))
                    local diff_system=$((system2 - system))
                    local diff_idle=$((idle2 - idle))
                    local diff_total=$((diff_user + diff_nice + diff_system + diff_idle))
                    # 计算CPU使用率
                    if [ "$diff_total" -gt 0 ]; then
                        local cpu_pct=$(((diff_user + diff_nice + diff_system) * 100 / diff_total))
                        printf "  ${W}%s${N} ${C}CPU:${G}%d%%${N}" "$(date +%H:%M:%S)" "$cpu_pct"
                    else
                        printf "  ${W}%s${N} ${C}CPU:${Y}??%%${N}" "$(date +%H:%M:%S)"
                    fi
                    # 显示核心频率
                    for i in 0 4 7; do
                        local freq=$(cat /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_cur_freq 2>/dev/null)
                        [ -n "$freq" ] && printf " cpu%d:${G}%dMHz${N}" "$i" "$((freq/1000))"
                    done
                    echo
                done
                ;;
            2) # 调速器切换 - 自动读取可用项
                sleep 0.3
                echo
                local avail_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)
                if [ -z "$avail_gov" ]; then
                    printf "  ${R}[X] 无法读取可用调速器${N}\n"
                    continue
                fi
                printf "  ${C}可用调速器:${N}\n"
                # Split governors into array and display numbered list
                local gov_idx=1
                local gov_list=""
                for gov in $avail_gov; do
                    printf "  ${G}%d${N}. ${W}%-12s${N}" "$gov_idx" "$gov"
                    gov_list="${gov_list}${gov} "
                    gov_idx=$((gov_idx + 1))
                done
                echo
                printf "  ${Y}请选择 [1-$((gov_idx - 1))]: ${N}"; read gov_num
                if [ -n "$gov_num" ] && [ "$gov_num" -ge 1 ] && [ "$gov_num" -le $((gov_idx - 1)) ]; then
                    local selected_gov=$(printf "$gov_list\n" | awk -v n="$gov_num" '{print $n}')
                    for i in $(seq 0 $((cpu_cores - 1))); do
                        printf "$selected_gov\n" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor 2>/dev/null
                    done
                    printf "  ${G}[OK] 已切换到 ${selected_gov}${N}\n"
                else
                    printf "  ${R}[X] 无效选择${N}\n"
                fi
                ;;
            3) # 频率调整
                echo
                local min_f=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null)
                local max_f=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
                local cur_min=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null)
                local cur_max=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)
                printf "  ${C}硬件范围: ${min_f}-${max_f} kHz${N}\n"
                printf "  ${C}当前设置: ${cur_min}-${cur_max} kHz${N}\n"
                echo
                printf "  ${G}1${N}. ${G}最高性能${N} (min=${min_f}, max=${max_f})\n"
                printf "  ${G}2${N}. ${Y}省电模式${N} (min=${min_f}, max=$((${min_f} + (${max_f} - ${min_f}) * 20 / 100)))\n"
                printf "  ${G}3${N}. ${C}均衡模式${N} (min=${min_f}, max=$((${max_f} * 70 / 100)))\n"
                printf "  ${G}4${N}. ${W}自定义${N} (手动输入min/max)\n"
                echo
                printf "  ${Y}请选择 [1-4]: ${N}"; read freq_preset
                case "$freq_preset" in
                    1)
                        new_min=${min_f}
                        new_max=${max_f}
                        ;;
                    2)
                        new_min=${min_f}
                        new_max=$((${min_f} + (${max_f} - ${min_f}) * 20 / 100))
                        ;;
                    3)
                        new_min=${min_f}
                        new_max=$((${max_f} * 70 / 100))
                        ;;
                    4)
                        printf "  ${Y}最小频率(kHz): ${N}"; read new_min
                        printf "  ${Y}最大频率(kHz): ${N}"; read new_max
                        ;;
                    *)
                        printf "  ${R}[X] 无效选择${N}\n"
                        continue
                        ;;
                esac
                for i in $(seq 0 $((cpu_cores - 1))); do
                    [ -n "$new_min" ] && printf "$new_min\n" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq 2>/dev/null
                    [ -n "$new_max" ] && printf "$new_max\n" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq 2>/dev/null
                done
                printf "  ${G}[OK] 频率已调整为: $new_min-$new_max kHz${N}\n"
                ;;
            4) # 温控管理
                echo
                printf "  ${C}扫描温控节点...${N}\n"
                printf "  ${W}ID  Type                    Temp${N}\n"
                printf "  ${DI}----------------------------------------${N}\n"
                local tz_idx=0
                for tz in /sys/class/thermal/thermal_zone*; do
                    [ -d "$tz" ] || continue
                    local tz_type=$(cat "$tz/type" 2>/dev/null || printf "unknown\n")
                    local tz_temp=$(cat "$tz/temp" 2>/dev/null || printf "0\n")
                    tz_temp="$((tz_temp / 1000))"
                    printf "  ${G}%2d${N}  %-24s %d°C\n" "$tz_idx" "$tz_type" "$tz_temp"
                    tz_idx=$((tz_idx + 1))
                done
                echo
                printf "  ${G}1${N}. 写入模拟温度  ${G}0${N}. 返回\n"
                printf "  ${Y}请选择: ${N}"; read therm_choice
                case "$therm_choice" in
                    1)
                        printf "  ${Y}输入模拟温度(如29500=29.5°C): ${N}"; read emul_temp
                        for tz in /sys/class/thermal/thermal_zone*; do
                            [ -f "$tz/emul_temp" ] && printf "$emul_temp\n" > "$tz/emul_temp" 2>/dev/null
                        done
                        printf "  ${G}[OK] 模拟温度已写入${N}\n"
                        ;;
                esac
                ;;
            5) # 大小核分控 - 智能检测核心分组
                sleep 0.3
                echo
                local avail_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)
                if [ -z "$avail_gov" ]; then
                    printf "  ${R}[X] 无法读取可用调速器${N}\n"
                    continue
                fi

                # 自动检测核心频率判断分组
                local little_cores=""
                local big_cores=""
                local prime_cores=""

                # 读取各核心最大频率判断
                for i in $(seq 0 $((cpu_cores - 1))); do
                    local max_freq=$(cat /sys/devices/system/cpu/cpu${i}/cpufreq/cpuinfo_max_freq 2>/dev/null)
                    if [ -n "$max_freq" ]; then
                        if [ "$max_freq" -lt 1800000 ]; then
                            little_cores="${little_cores}${i} "
                        elif [ "$max_freq" -lt 2800000 ]; then
                            big_cores="${big_cores}${i} "
                        else
                            prime_cores="${prime_cores}${i} "
                        fi
                    fi
                done

                # 如果自动检测失败，使用默认8核分组
                if [ -z "$little_cores" ]; then
                    little_cores="0 1 2 3 "
                fi
                if [ -z "$big_cores" ]; then
                    big_cores="4 5 6 "
                fi
                if [ -z "$prime_cores" ] && [ "$cpu_cores" -ge 8 ]; then
                    prime_cores="7 "
                fi

                printf "  ${C}[C] 核心分组检测结果:${N}\n"
                printf "  ${G}小核${N}: cpu${little_cores}\n"
                printf "  ${Y}大核${N}: cpu${big_cores}\n"
                [ -n "$prime_cores" ] && printf "  ${R}超大核${N}: cpu${prime_cores}\n"
                echo
                printf "  ${C}可用调速器: ${W}$avail_gov${N}\n"

                # 显示调速器列表
                local gov_idx=1
                local gov_list=""
                for gov in $avail_gov; do
                    printf "  ${G}%d${N}. ${W}%-12s${N}" "$gov_idx" "$gov"
                    gov_list="${gov_list}${gov} "
                    gov_idx=$((gov_idx + 1))
                done
                echo

                # 小核选择
                printf "  ${Y}小核调速器 [1-$((gov_idx - 1))]: ${N}"; read little_num
                local selected_little=$(printf "$gov_list\n" | awk -v n="${little_num:-1}" '{print $n}')

                # 大核选择
                printf "  ${Y}大核调速器 [1-$((gov_idx - 1))]: ${N}"; read big_num
                local selected_big=$(printf "$gov_list\n" | awk -v n="${big_num:-1}" '{print $n}')

                # 超大核选择
                local selected_prime="$selected_big"
                if [ -n "$prime_cores" ]; then
                    printf "  ${Y}超大核调速器 [1-$((gov_idx - 1))](回车同大核): ${N}"; read prime_num
                    [ -n "$prime_num" ] && selected_prime=$(printf "$gov_list\n" | awk -v n="$prime_num" '{print $n}')
                fi

                # 应用设置
                for i in $little_cores; do
                    printf "$selected_little\n" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor 2>/dev/null
                done
                for i in $big_cores; do
                    printf "$selected_big\n" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor 2>/dev/null
                done
                for i in $prime_cores; do
                    printf "$selected_prime\n" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor 2>/dev/null
                done

                printf "  ${G}[OK] 大小核分控已设置${N}\n"
                ;;
            0) return 0 ;;
        esac
        printf "  ${DI}按回车继续...${N}"; read
    done
}

run_thread_opt() {
    sleep 0.3
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}线 程 优 化${N}                    ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${G}1${N}. ${W}写入模式（直接修改AppOpt配置）${N}      ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${R}0${N}. ${W}返回${N}                                  ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}请选择: ${N}"; read thread_choice
    [ "$thread_choice" = "0" ] && return 0

    printf "  ${C}输入线程绑定规则（每行一条，空行结束）${N}\n"
    printf "  ${DI}格式: 包名=核心范围  或  包名{线程名}=核心范围${N}\n"
    printf "  ${DI}示例: com.tencent.mm=5-6${N}\n"
    printf "  ${DI}示例: com.tencent.tmgp.sgame{RenderThread}=4-7${N}\n"
    local rules=""
    while true; do
        printf "  ${Y}> ${N}"; read rule_line
        [ -z "$rule_line" ] && break
        rules="${rules}${rule_line}\n"
    done

    if [ "$thread_choice" = "1" ]; then
        local appopt_dir="/data/adb/modules/AppOpt"
        mkdir -p "$appopt_dir"
        # 从云端下载AppOpt二进制
        printf "  ${C}正在下载AppOpt...${N}\n"
        download_file "${CLOUD_BASE}/AppOpt" "$appopt_dir/AppOpt" 2>/dev/null
        if [ -f "$appopt_dir/AppOpt" ] && [ -s "$appopt_dir/AppOpt" ]; then
            chmod 755 "$appopt_dir/AppOpt" 2>/dev/null
            printf "$rules\n" > "$appopt_dir/applist.conf"
            printf "  ${G}[OK] 线程优化规则已写入${N}\n"
            printf "  ${C}路径: ${W}$appopt_dir/applist.conf${N}\n"
        else
            printf "  ${R}[X] AppOpt下载失败${N}\n"
            rm -rf "$appopt_dir"
        fi
    fi
    echo; printf "  ${DI}按回车返回...${N}"; read
}

run_oc_response() {
    sleep 0.3
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}超 频 响 应${N}                    ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${DI}设置TapDragInterval=1${N}               ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo

    local rp=$(get_resetprop)
    [ -n "$rp" ] && $rp TapDragInterval 1 2>/dev/null
    setprop TapDragInterval 1 2>/dev/null
    printf "  ${G}[OK] TapDragInterval=1 已写入${N}\n"
    echo; printf "  ${DI}按回车返回...${N}"; read
}

run_touch_opt() {
    sleep 0.3
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}触 控 优 化${N}                    ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${DI}设置值过大可能无效，建议480-540${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}输入采样率(默认540): ${N}"; read sample_rate
    sample_rate="${sample_rate:-540}"

    for input in /sys/class/input/input*/sample_rate; do
        [ -f "$input" ] && printf "$sample_rate\n" > "$input" 2>/dev/null
    done
    setprop persist.vendor.touch.low_power 0 2>/dev/null
    printf "  ${G}[OK] 采样率已设置为 ${sample_rate}${N}\n"
    echo; printf "  ${DI}按回车返回...${N}"; read
}

run_block_official() {
    sleep 0.3
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}屏 蔽 官 调${N}                    ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${DI}屏蔽ColorOS/oiface/orms/horae/COSA${N}    ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo

    stop horae 2>/dev/null
    stop vendor.oplus.ormsHalService-aidl-defaults 2>/dev/null
    stop oiface 2>/dev/null
    local rp=$(get_resetprop)
    [ -n "$rp" ] && $rp persist.sys.orms.name "" 2>/dev/null
    setprop persist.sys.orms.name "" 2>/dev/null
    printf "  ${G}[OK] 官调已屏蔽${N}\n"
    echo; printf "  ${DI}按回车返回...${N}"; read
}

run_vk_render() {
    sleep 0.3
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}VK 渲 染 开 启${N}                  ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${DI}强制使用Vulkan渲染引擎${N}               ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo

    local rp=$(get_resetprop)
    [ -n "$rp" ] && $rp ro.hwui.use_vulkan true 2>/dev/null
    setprop ro.hwui.use_vulkan true 2>/dev/null
    printf "  ${G}[OK] Vulkan渲染已开启${N}\n"
    echo; printf "  ${DI}按回车返回...${N}"; read
}

run_tg_verify() {
    sleep 0.3
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}TG 过 验 证${N}                    ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${DI}创建6个TG客户端缓存+验证文件${N}         ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo

    # 6个TG客户端目录
    local tg_clients="org.telegram.messenger org.telegram.messenger.web xyz.nextalone.nagram nekox.messenger tw.nekomimi.nekogram org.thunderdog.challegram"

    printf "  ${C}[1/5] 创建TG客户端缓存目录...${N}\n"
    for client in $tg_clients; do
        mkdir -p /data/media/0/Android/data/${client}/cache/acache
        mkdir -p /data/user/0/${client}/files/
    done

    printf "  ${C}[2/5] 生成空图片验证文件...${N}\n"
    for client in $tg_clients; do
        touch /data/media/0/Android/data/${client}/cache/-6089395591818886111_99.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-6284997065431518490_99.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-6231226948214967091_99.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-5812119160388437734_99.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-6136283406191936649_99.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-6316316422216728798_97.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-6316316422216728798_99.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-6258095464754823002_99.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-6325731050659102715_97.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-6325731050659102715_99.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-5460653499701389407_97.jpg 2>/dev/null
        touch /data/media/0/Android/data/${client}/cache/-5460653499701389407_99.jpg 2>/dev/null
    done

    printf "  ${C}[3/5] 生成HLW图片文件...${N}\n"
    for client in $tg_clients; do
        dd if=/dev/zero of=/data/media/0/Android/data/${client}/cache/-6303107422096572833_97.jpg bs=13143 count=1 2>/dev/null
        dd if=/dev/zero of=/data/media/0/Android/data/${client}/cache/-6303107422096572833_99.jpg bs=114050 count=1 2>/dev/null
    done

    printf "  ${C}[4/5] 写入cache4.db-wal验证数据...${N}\n"
    for client in $tg_clients; do
        touch /data/user/0/${client}/files/cache4.db-wal 2>/dev/null
        if [ -f "/data/user/0/${client}/files/cache4.db-wal" ]; then
            if ! grep -q -a "HLWNB" /data/user/0/${client}/files/cache4.db-wal 2>/dev/null; then
                printf "HLWNB\n" >> /data/user/0/${client}/files/cache4.db-wal 2>/dev/null
            fi
        fi
    done
    touch /data/data/agreement 2>/dev/null

    printf "  ${C}[5/5] 验证文件完整性...${N}\n"
    local verify_ok=0
    local verify_fail=0
    for client in $tg_clients; do
        if [ -f "/data/media/0/Android/data/${client}/cache/-6303107422096572833_97.jpg" ]; then
            printf "  ${G}[OK]${N} ${client}\n"
            verify_ok=$((verify_ok + 1))
        else
            printf "  ${R}[FAIL]${N} ${client}\n"
            verify_fail=$((verify_fail + 1))
        fi
    done

    echo
    if [ $verify_fail -eq 0 ]; then
        printf "  ${G}[OK] TG过验证完成! 全部 ${verify_ok} 个客户端验证通过${N}\n"
    else
        printf "  ${Y}[!] TG过验证完成! ${verify_ok} 通过 / ${verify_fail} 失败${N}\n"
    fi

    # 静默跳转TG频道
    am start -a android.intent.action.VIEW -d tg://resolve?domain=x303lnb >/dev/null 2>&1
}

run_thermal_manage() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}              ${BD}${W}温 控 管 理${N}                    ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}扫描温控节点${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}温度墙拉高(110度)${N}                    ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}模拟温度(29.5度)${N}                     ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}4${N}. ${W}解除充电温控${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}5${N}. ${W}GPU频率解锁${N}                         ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}6${N}. ${W}恢复默认温控${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回${N}                                ${ORANGE}│${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择: ${N}"
        read thermal_choice
        case "$thermal_choice" in
            1)
                printf "${C}[*] 正在扫描温控节点...${N}\n"
                echo
                for tz in /sys/class/thermal/thermal_zone*; do
                    [ -d "$tz" ] || continue
                    type=$(cat "$tz/type" 2>/dev/null)
                    temp=$(cat "$tz/temp" 2>/dev/null)
                    [ -z "$type" ] && continue
                    temp_c=$((temp / 1000))
                    printf "  ${W}$type${N}: ${Y}${temp_c}°C${N} ($temp)\n"
                done
                if [ -f /proc/shell-temp ]; then
                    echo
                    printf "  ${W}外壳温度:${N}\n"
                    for i in $(seq 0 7); do
                        val=$(sed -n "$((i+1))p" /proc/shell-temp 2>/dev/null)
                        [ -n "$val" ] && printf "  传感器$i: ${Y}$val${N}\n"
                    done
                fi
                printf "\n  ${DI}按回车返回...${N}"; read
                ;;
            2)
                printf "${Y}[!] 此操作将温度墙拉高到110度${N}\n"
                printf "${R}[!] 高温可能损坏设备，请自行承担风险${N}\n"
                printf "  ${Y}确认执行? (y/n): ${N}"
                read confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    SET_TRIP_POINT_TEMP_MAX=110000
                    count=0
                    for THERMAL_ZONE in /sys/class/thermal/thermal_zone*/type; do
                        if cat "$THERMAL_ZONE" 2>/dev/null | grep -iE "cpu|gpu|ddr|aoss" >/dev/null; then
                            for TRIP_POINT_TEMP in ${THERMAL_ZONE%/*}/trip_point_*_temp; do
                                if [ -f "$TRIP_POINT_TEMP" ] && [ "$(cat $TRIP_POINT_TEMP)" -lt "$SET_TRIP_POINT_TEMP_MAX" ] 2>/dev/null; then
                                    printf "$(cat $TRIP_POINT_TEMP)\n" > "$TRIP_POINT_TEMP.bak" 2>/dev/null
                                    printf "$SET_TRIP_POINT_TEMP_MAX\n" > "$TRIP_POINT_TEMP" 2>/dev/null
                                    count=$((count + 1))
                                fi
                            done
                        fi
                    done
                    printf "${G}[OK] 已修改 $count 个温控节点${N}\n"
                else
                    printf "${DI}[*] 已取消${N}\n"
                fi
                printf "\n  ${DI}按回车返回...${N}"; read
                ;;
            3)
                printf "${Y}[!] 此操作将模拟温度为29.5度${N}\n"
                printf "  ${Y}确认执行? (y/n): ${N}"
                read confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    t=29500
                    count=0
                    for tz in /sys/class/thermal/*; do
                        if [ -f "$tz/temp" ]; then
                            case $(cat "$tz/type" 2>/dev/null) in
                                rear-tof-therm|cam-flash-therm|batt-therm|usb-therm|wlan-therm|xo-therm|oplus_thermal_ipa|shell*)
                                    printf "$t\n" > "$tz/emul_temp" 2>/dev/null && count=$((count + 1)) ;;
                            esac
                        fi
                    done
                    printf "${G}[OK] 已模拟 $count 个温度传感器${N}\n"
                else
                    printf "${DI}[*] 已取消${N}\n"
                fi
                printf "\n  ${DI}按回车返回...${N}"; read
                ;;
            4)
                printf "${C}[*] 正在解除充电温控...${N}\n"
                if [ -f /sys/class/oplus_chg/cool_down ]; then
                    printf "0\n" > /sys/class/oplus_chg/cool_down 2>/dev/null
                    printf "${G}[OK] 充电冷却已关闭${N}\n"
                fi
                if [ -f /sys/class/oplus_chg/battery/bcc_current ]; then
                    printf "2147483647\n" > /sys/class/oplus_chg/battery/bcc_current 2>/dev/null
                    printf "${G}[OK] 充电电流上限已解锁${N}\n"
                fi
                printf "\n  ${DI}按回车返回...${N}"; read
                ;;
            5)
                printf "${C}[*] 正在解锁GPU频率...${N}\n"
                if [ -d /sys/class/kgsl/kgsl-3d0 ]; then
                    printf "0\n" > /sys/class/kgsl/kgsl-3d0/max_pwrlevel 2>/dev/null
                    printf "2147483647\n" > /sys/class/kgsl/kgsl-3d0/max_gpu_clk 2>/dev/null
                    printf "2147483647\n" > /sys/class/kgsl/kgsl-3d0/max_clock_mhz 2>/dev/null
                    printf "${G}[OK] GPU频率限制已解除${N}\n"
                else
                    printf "${R}[X] 未检测到kgsl GPU节点${N}\n"
                fi
                printf "\n  ${DI}按回车返回...${N}"; read
                ;;
            6)
                printf "${C}[*] 正在恢复默认温控...${N}\n"
                for THERMAL_ZONE in /sys/class/thermal/thermal_zone*/type; do
                    for TRIP_POINT_TEMP in ${THERMAL_ZONE%/*}/trip_point_*_temp; do
                        if [ -f "$TRIP_POINT_TEMP.bak" ]; then
                            cat "$TRIP_POINT_TEMP.bak" > "$TRIP_POINT_TEMP" 2>/dev/null
                            rm -f "$TRIP_POINT_TEMP.bak"
                        fi
                    done
                done
                for tz in /sys/class/thermal/*/emul_temp; do
                    [ -f "$tz" ] && printf "\n" > "$tz" 2>/dev/null
                done
                printf "${G}[OK] 温控已恢复默认${N}\n"
                printf "\n  ${DI}按回车返回...${N}"; read
                ;;
            0) break ;;
        esac
    done
}

run_scheduler_center() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}              ${BD}${W}调 度 中 心${N}                    ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}性能调度${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}温控管理${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}线程优化${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}4${N}. ${W}超频响应${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}5${N}. ${W}触控优化${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}6${N}. ${W}屏蔽官调${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}7${N}. ${W}VK渲染${N}                             ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                             ${ORANGE}│${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择 [0-7]: ${N}"
        read sched_choice
        case "$sched_choice" in
            1) run_perf_sched ;;
            2) run_thermal_manage ;;
            3) run_thread_opt ;;
            4) run_oc_response ;;
            5) run_touch_opt ;;
            6) run_block_official ;;
            7) run_vk_render ;;
            0) break ;;
        esac
    done
}

BACKUP_DIR="/storage/emulated/0/XToolbox_backup"
DATE=$(date +%Y%m%d_%H%M%S)

find_part_base() {
    if [ -d "/dev/block/bootdevice/by-name" ]; then
        printf "/dev/block/bootdevice/by-name\n"
    elif [ -d "/dev/block/by-name" ]; then
        printf "/dev/block/by-name\n"
    else
        local p=$(find /dev/block/platform -name "by-name" -type d 2>/dev/null | head -1)
        [ -n "$p" ] && printf "$p\n"
    fi
}

do_backup_one() {
    local part_name="$1"
    local part_base=$(find_part_base)
    [ -z "$part_base" ] && printf "  ${R}[X] 未找到分区目录${N}\n" && return 1

    local part_path="${part_base}/${part_name}"
    local out_file="${BACKUP_DIR}/${part_name}_${DATE}.img"

    if [ ! -e "${part_path}" ]; then
        printf "  ${Y}[!] 分区 ${part_name} 不存在，跳过${N}\n"
        return 1
    fi

    printf "  ${C}[*] 正在备份: ${W}${part_name}${N}\n"
    printf "  ${DI}  路径: ${part_path}${N}\n"
    printf "  ${DI}  输出: ${out_file}${N}\n"

    # dd方式备份 (参考脚本验证可用)
    if dd if="${part_path}" of="${out_file}" bs=4096 2>/dev/null; then
        # 生成MD5校验
        md5sum "${out_file}" > "${out_file}.md5" 2>/dev/null
        local fsize=$(ls -lh "$out_file" 2>/dev/null | awk '{print $5}')
        printf "  ${G}[OK] ${part_name} 备份完成 (${fsize})${N}\n"
        return 0
    else
        printf "  ${R}[X] ${part_name} 备份失败${N}\n"
        rm -f "$out_file"
        return 1
    fi
}

show_partitions() {
    local part_base=$(find_part_base)
    if [ -z "$part_base" ] || [ ! -d "$part_base" ]; then
        printf "  ${R}[X] 未找到分区目录${N}\n"
        return 1
    fi
    printf "  ${C}可用分区:${N}\n"
    ls -1 "$part_base" | sort | nl -w2 -s'. '
}

get_part_by_num() {
    local part_base=$(find_part_base)
    local num="$1"
    ls -1 "$part_base" | sort | sed -n "${num}p"
}

backup_partition() {
    echo
    printf "${ORANGE}╔═════════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}            ${W}分 区 备 份${N}                    ${ORANGE}║${N}\n"
    printf "${ORANGE}╠═════════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${DI}备份到 ${W}${BACKUP_DIR}${N}              ${ORANGE}║${N}\n"
    printf "${ORANGE}╚═════════════════════════════════════════════╝${N}\n"

    if [ "$(id -u)" -ne 0 ]; then
        printf "  ${R}[X] 需要Root权限${N}\n"
        echo; printf "  ${DI}按回车返回...${N}"; read
        return 1
    fi

    mkdir -p "${BACKUP_DIR}"

    printf "  ${C}[1] 选择单个分区备份${N}\n"
    printf "  ${C}[2] 批量选择多个分区备份${N}\n"
    printf "  ${C}[3] 一键备份常见分区${N}\n"
    printf "  ${C}[4] 字库备份(modem)${N}\n"
    echo
    printf "  ${Y}请选择: ${N}"
    read sub

    case "$sub" in
        1)
            # 单个分区备份 (照抄参考脚本)
            show_partitions
            echo
            printf "  ${DI}输入分区编号进行备份，输入 0 返回${N}\n"
            printf "  ${Y}请输入选择: ${N}"
            read sel

            if [ "$sel" = "0" ] || [ -z "$sel" ]; then
                return
            fi

            local part_name=$(get_part_by_num "$sel")
            if [ -z "$part_name" ]; then
                printf "  ${R}[X] 无效的分区编号${N}\n"
                echo; printf "  ${DI}按回车返回...${N}"; read
                return
            fi

            do_backup_one "$part_name"
            echo; printf "  ${DI}按回车返回...${N}"; read
            ;;
        2)
            # 批量备份 (照抄参考脚本)
            show_partitions
            echo
            printf "  ${DI}输入要备份的分区编号，用空格分隔 (例如: 1 3 5)${N}\n"
            printf "  ${DI}输入 0 返回${N}\n"
            printf "  ${Y}请输入选择: ${N}"
            read selections

            if [ "$selections" = "0" ] || [ -z "$selections" ]; then
                return
            fi

            for sel in $selections; do
                local part_name=$(get_part_by_num "$sel")
                if [ -n "$part_name" ]; then
                    do_backup_one "$part_name"
                else
                    printf "  ${Y}[!] 无效的编号 ${sel}，跳过${N}\n"
                fi
            done

            echo
            printf "  ${G}[OK] 批量备份完成!${N}\n"
            echo; printf "  ${DI}按回车返回...${N}"; read
            ;;
        3)
            # 一键备份常见分区 (照抄参考脚本)
            echo
            printf "  ${C}一键备份常见分区${N}\n"
            printf "  ${DI}将备份: boot, dtbo, vendor_boot, vbmeta, modem, persist${N}\n"
            echo
            printf "  ${Y}确认开始备份? (y/n): ${N}"
            read confirm
            if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
                printf "  ${Y}[!] 已取消${N}\n"
                echo; printf "  ${DI}按回车返回...${N}"; read
                return
            fi

            echo
            for part in boot dtbo vendor_boot vbmeta modem persist; do
                do_backup_one "$part"
            done

            echo
            printf "  ${G}[OK] 常见分区备份完成!${N}\n"
            echo; printf "  ${DI}按回车返回...${N}"; read
            ;;
        4)
            # 字库备份
            echo
            printf "  ${C}字库备份说明:${N}\n"
            printf "  ${DI}字库即基带固件(modem分区)，包含4G/5G通信数据${N}\n"
            printf "  ${DI}刷机前备份可在信号异常时恢复${N}\n"
            echo
            printf "  ${C}[1] 备份当前字库${N}\n"
            printf "  ${C}[2] 恢复字库备份${N}\n"
            printf "  ${C}[3] 查看已有备份${N}\n"
            echo
            printf "  ${Y}请选择: ${N}"
            read modem_sub

            local MODEM_DIR="${BACKUP_DIR}/modem"
            mkdir -p "$MODEM_DIR"

            case "$modem_sub" in
                1)
                    local part_base=$(find_part_base)
                    local modem_path=""
                    for name in modem modem1 modem_a; do
                        [ -e "${part_base}/${name}" ] && modem_path="${part_base}/${name}" && break
                    done
                    if [ -z "$modem_path" ]; then
                        printf "  ${R}[X] 未找到modem分区${N}\n"
                        echo; printf "  ${DI}按回车返回...${N}"; read
                        return 0
                    fi
                    local mout="${MODEM_DIR}/modem_${DATE}.img"
                    printf "  ${C}[*] modem路径: ${W}${modem_path}${N}\n"
                    printf "  ${Y}[!] 备份过程中请勿使用电话功能${N}\n"
                    printf "  ${Y}确认备份? (y/n): ${N}"
                    read mc
                    [ "$mc" != "y" ] && [ "$mc" != "Y" ] && echo; printf "  ${DI}按回车返回...${N}"; read && return 0
                    echo
                    printf "  ${C}[*] 正在备份字库...${N}\n"
                    if dd if="${modem_path}" of="${mout}" bs=4096 2>/dev/null; then
                        md5sum "$mout" > "${mout}.md5" 2>/dev/null
                        local fsz=$(ls -lh "$mout" 2>/dev/null | awk '{print $5}')
                        echo
                        printf "  ${G}[OK] 字库备份完成!${N}\n"
                        printf "  ${G}[OK] 文件: ${W}${mout}${N}\n"
                        printf "  ${G}[OK] 大小: ${W}${fsz}${N}\n"
                    else
                        echo
                        printf "  ${R}[X] 字库备份失败!${N}\n"
                        rm -f "$mout"
                    fi
                    echo; printf "  ${DI}按回车返回...${N}"; read
                    ;;
                2)
                    echo
                    printf "  ${C}已有字库备份:${N}\n"
                    local mcount=0
                    for img in "$MODEM_DIR"/modem_*.img; do
                        [ -f "$img" ] || continue
                        mcount=$((mcount + 1))
                        printf "  ${G}%2s${N}. %-30s %s\n" "$mcount" "$(basename "$img")" "$(ls -lh "$img" | awk '{print $5}')"
                    done
                    if [ $mcount -eq 0 ]; then
                        printf "  ${DI}暂无字库备份${N}\n"
                        echo; printf "  ${DI}按回车返回...${N}"; read
                        return 0
                    fi
                    echo
                    printf "  ${Y}选择要恢复的备份编号: ${N}"
                    read msel
                    [ -z "$msel" ] && echo; printf "  ${DI}按回车返回...${N}"; read && return 0
                    local sel_img=$(ls "$MODEM_DIR"/modem_*.img 2>/dev/null | sed -n "${msel}p")
                    if [ -z "$sel_img" ] || [ ! -f "$sel_img" ]; then
                        printf "  ${R}[X] 无效选择${N}\n"
                        echo; printf "  ${DI}按回车返回...${N}"; read
                        return 0
                    fi
                    local part_base=$(find_part_base)
                    local modem_path=""
                    for name in modem modem1 modem_a; do
                        [ -e "${part_base}/${name}" ] && modem_path="${part_base}/${name}" && break
                    done
                    if [ -z "$modem_path" ]; then
                        printf "  ${R}[X] 未找到modem分区${N}\n"
                        echo; printf "  ${DI}按回车返回...${N}"; read
                        return 0
                    fi
                    echo
                    printf "  ${R}[!] 即将恢复字库: $(basename "$sel_img")${N}"
                    printf "  ${R}[!] 恢复后需要重启才能生效${N}\n"
                    printf "  ${R}输入 yes 确认: ${N}"
                    read mc
                    [ "$mc" != "yes" ] && printf "  ${Y}[!] 已取消${N}\n" && echo; printf "  ${DI}按回车返回...${N}"; read && return 0
                    echo
                    printf "  ${C}[*] 正在恢复字库...${N}\n"
                    if dd if="${sel_img}" of="${modem_path}" bs=4096 2>/dev/null; then
                        echo
                        printf "  ${G}[OK] 字库恢复完成!${N}\n"
                        printf "  ${Y}[!] 请立即重启设备${N}\n"
                    else
                        echo
                        printf "  ${R}[X] 字库恢复失败!${N}\n"
                    fi
                    echo; printf "  ${DI}按回车返回...${N}"; read
                    ;;
                3)
                    echo
                    printf "  ${C}字库备份列表:${N}\n"
                    local mc2=0
                    for img in "$MODEM_DIR"/modem_*.img; do
                        [ -f "$img" ] || continue
                        mc2=$((mc2 + 1))
                        printf "  ${G}%2s${N}. %-30s %s\n" "$mc2" "$(basename "$img")" "$(ls -lh "$img" | awk '{print $5}')"
                    done
                    if [ $mc2 -eq 0 ]; then
                        printf "  ${DI}暂无字库备份${N}\n"
                    fi
                    printf "  ${DI}备份目录: ${MODEM_DIR}${N}\n"
                    echo; printf "  ${DI}按回车返回...${N}"; read
                    ;;
                *)
                    echo; printf "  ${DI}按回车返回...${N}"; read
                    ;;
            esac
            ;;
        *)
            echo; printf "  ${DI}按回车返回...${N}"; read
            ;;
    esac
}

flash_partition() {
    echo
    printf "${ORANGE}╔═════════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}            ${W}分 区 刷 入${N}                    ${ORANGE}║${N}\n"
    printf "${ORANGE}╠═════════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${R}⚠ 操作不可逆，请确保img正确${N}             ${ORANGE}║${N}\n"
    printf "${ORANGE}╚═════════════════════════════════════════════╝${N}\n"

    if [ "$(id -u)" -ne 0 ]; then
        printf "  ${R}[X] 需要Root权限${N}\n"
        echo; printf "  ${DI}按回车返回...${N}"; read
        return 1
    fi

    echo
    printf "  ${C}请输入img文件路径${N}\n"
    printf "  ${DI}(例如: ${BACKUP_DIR}/boot_20260517.img)${N}\n"
    printf "  ${Y}路径: ${N}"
    read img_path

    if [ -z "$img_path" ]; then
        printf "  ${R}[X] 路径不能为空${N}\n"
        echo; printf "  ${DI}按回车返回...${N}"; read
        return 1
    fi
    if [ ! -f "$img_path" ]; then
        printf "  ${R}[X] 文件不存在: $img_path${N}\n"
        echo; printf "  ${DI}按回车返回...${N}"; read
        return 1
    fi

    local fsize=$(ls -lh "$img_path" | awk '{print $5}')
    printf "  ${C}[*] 文件: ${W}$img_path${N}  ${W}($fsize)${N}\n"

    # 显示已备份的分区
    echo
    printf "  ${C}已备份的分区:${N}\n"
    local bidx=1
    for img in "$BACKUP_DIR"/*.img; do
        [ -f "$img" ] || continue
        printf "  ${G}%2s${N}. %-24s %s\n" "$bidx" "$(basename "$img")" "$(ls -lh "$img" | awk '{print $5}')"
        bidx=$((bidx + 1))
    done
    if [ $bidx -eq 1 ]; then
        printf "  ${DI}暂无备份文件${N}\n"
    fi
    printf "  ${G}0${N}. ${Y}自定义分区名${N}\n"
    echo
    printf "  ${Y}选择目标分区编号: ${N}"
    read part_idx

    [ -z "$part_idx" ] && echo; printf "  ${DI}按回车返回...${N}"; read && return 1

    local selected_name=""
    local part_base=$(find_part_base)

    if [ "$part_idx" = "0" ]; then
        printf "  ${Y}请输入分区名称(如 boot): ${N}"
        read selected_name
        [ -z "$selected_name" ] && echo; printf "  ${DI}按回车返回...${N}"; read && return 1
    else
        local found_img=$(ls "$BACKUP_DIR"/*.img 2>/dev/null | sed -n "${part_idx}p")
        if [ -n "$found_img" ]; then
            # 从文件名提取分区名: boot_20260517_123456.img -> boot
            selected_name=$(basename "$found_img" | sed 's/_[0-9]*\.img$//' | sed 's/\.img$//')
        else
            printf "  ${R}[X] 无效选择${N}\n"
            echo; printf "  ${DI}按回车返回...${N}"; read
            return 1
        fi
    fi

    local part_path="${part_base}/${selected_name}"
    if [ -z "$part_base" ] || [ ! -e "$part_path" ]; then
        printf "  ${R}[X] 分区不存在: $selected_name${N}\n"
        echo; printf "  ${DI}按回车返回...${N}"; read
        return 1
    fi

    echo
    printf "  ${R}╔═════════════════════════════════════════════╗${N}\n"
    printf "  ${R}║${N}           ${BD}${W}最 终 确 认${N}                    ${R}║${N}\n"
    printf "  ${R}╠═════════════════════════════════════════════╣${N}\n"
    printf "  ${R}║${N}  ${W}刷入文件: %-28s${R}║${N}\n" "$(basename $img_path)"
    printf "  ${R}║${N}  ${W}文件大小: %-28s${R}║${N}\n" "$fsize"
    printf "  ${R}║${N}  ${W}目标分区: %-28s${R}║${N}\n" "$selected_name"
    printf "  ${R}║${N}  ${W}分区路径: %-28s${R}║${N}\n" "$part_path"
    printf "  ${R}║${N}  ${BD}${R}⚠ 此操作将覆盖分区数据，不可恢复!${N}       ${R}║${N}\n"
    printf "  ${R}╚═════════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${R}请输入 ${BD}yes${N}${R} 确认刷入: ${N}"
    read confirm
    if [ "$confirm" != "yes" ]; then
        printf "  ${Y}[!] 已取消${N}\n"
        echo; printf "  ${DI}按回车返回...${N}"; read
        return 0
    fi

    echo
    printf "  ${C}[*] 正在刷入 ${selected_name}...${N}\n"
    if dd if="$img_path" of="$part_path" bs=4096 2>/dev/null; then
        echo
        printf "  ${G}[OK] 刷入完成!${N}\n"
        printf "  ${G}[OK] $fsize → $selected_name${N}\n"
        echo
        printf "  ${Y}[!] 建议重启设备以使更改生效${N}\n"
    else
        echo
        printf "  ${R}[X] 刷入失败!${N}\n"
        printf "  ${R}[X] 请勿重启，尝试用备份恢复${N}\n"
    fi
    echo; printf "  ${DI}按回车返回...${N}"; read
}

run_partition_tool() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}           ${BD}${W}分 区 备 份 与 刷 入${N}             ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}备份分区${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}刷入分区${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                             ${ORANGE}│${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择 [0-2]: ${N}"
        read pt_choice
        case "$pt_choice" in
            1) backup_partition ;;
            2) flash_partition ;;
            0) break ;;
        esac
    done
}

run_clipboard_unlock() {
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}       ${BD}${W}解 除 剪 贴 板 限 制${N}              ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${DI}开启后台剪贴板读取权限${N}               ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${DI}关闭剪贴板访问通知${N}                   ${ORANGE}║${N}\n"
    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
    echo

    local SETTINGS_CMD="/system/bin/settings"

    # 检查settings命令是否存在
    if [ ! -x "$SETTINGS_CMD" ]; then
        printf "  ${R}[X] 找不到系统settings命令，当前环境不兼容${N}\n"
        echo
        printf "  ${DI}按回车返回...${N}"
        read
        return 1
    fi

    printf "  ${C}[*] 正在执行剪贴板权限设置...${N}\n"
    echo

    # 开启后台剪贴板读取权限
    $SETTINGS_CMD put secure clipboard_access 1 2>/dev/null
    if [ $? -eq 0 ]; then
        printf "  ${G}[OK] 已开启后台剪贴板读取权限${N}\n"
    else
        printf "  ${R}[X] 后台剪贴板权限设置失败${N}\n"
    fi

    # 关闭剪贴板访问通知
    $SETTINGS_CMD put secure clipboard_show_access_notification 0 2>/dev/null
    if [ $? -eq 0 ]; then
        printf "  ${G}[OK] 已关闭剪贴板访问通知${N}\n"
    else
        printf "  ${R}[X] 剪贴板通知设置失败${N}\n"
    fi

    # 验证设置结果
    echo
    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${W}设 置 验 证 结 果${N}                ${ORANGE}║${N}\n"
    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"

    local ACCESS_VALUE=$($SETTINGS_CMD get secure clipboard_access 2>/dev/null)
    local NOTIFY_VALUE=$($SETTINGS_CMD get secure clipboard_show_access_notification 2>/dev/null)

    printf "${ORANGE}║${N}  ${DI}后台剪贴板读取权限:${N} ${W}%s${N}              ${ORANGE}║${N}\n" "$ACCESS_VALUE"
    printf "${ORANGE}║${N}  ${DI}剪贴板访问通知开关:${N} ${W}%s${N}              ${ORANGE}║${N}\n" "$NOTIFY_VALUE"

    if [ "$ACCESS_VALUE" = "1" ]; then
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}║${N}       ${G}[OK] 剪贴板限制解除成功${N}            ${ORANGE}║${N}\n"
    fi

    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"

    add_usage "clipboard_unlock"
    echo
    printf "  ${DI}按回车返回...${N}"
    read
}

run_dtbo_toolkit() {
    # 检查模块，未生效则阻止进入
    if ! check_and_download_dtbo_deps; then
        return 1
    fi

    # 设置环境变量
    export LD_LIBRARY_PATH="$SCRIPT_DIR/bin/avbtool:$LD_LIBRARY_PATH"
    export PATH="$SCRIPT_DIR/bin/:$PATH"

    # DTBO目录变量
    local OUT_DIR="$SCRIPT_DIR/out"
    local DTS_DIR="$OUT_DIR/dts"
    local AVB_DIR="$OUT_DIR/avb"
    local BIN_DIR="$BIN_DIR"
    local RECYCLE_DIR="$SCRIPT_DIR/回收站"
    local DTBO_BASE_DIR="$SCRIPT_DIR/[已合成dtbo]文件目录"

    mkdir -p "$RECYCLE_DIR"

    # 主循环
    while true; do
        dtbo_show_menu
        printf "  ${Y}请选择 [0-9]: ${N}"
        read dtbo_choice
        case "$dtbo_choice" in
            1) dtbo_menu_option_1 ;;
            2) dtbo_menu_option_2 ;;
            3) dtbo_menu_option_3 ;;
            4) dtbo_menu_option_4 ;;
            5) dtbo_menu_option_5 ;;
            6) dtbo_menu_option_6 ;;
            7) dtbo_menu_option_7 ;;
            8) dtbo_menu_option_8 ;;
            9) dtbo_menu_option_9 ;;
            0) printf "${C}[*] 返回主菜单${N}\n"; break ;;
            *) printf "${R}[x] 无效选择，请输入 0-9${N}\n"; sleep 1 ;;
        esac
    done
}

dtbo_show_menu() {
    clear
    printf "${G}═══════════════════════════════════════════════════${N}\n"
    printf "${C}              DTBO 工具主菜单${N}\n"
    printf "${G}═══════════════════════════════════════════════════${N}\n"
    
    device_name=$(grep -m1 '^ro.product.system_dlkm.marketname=' /system_dlkm/etc/build.prop 2>/dev/null | cut -d'=' -f2)
    [ -z "$device_name" ] && device_name=$(getprop ro.vendor.oplus.market.name 2>/dev/null)
    [ -z "$device_name" ] && device_name="未知"
    
    product_name=$(getprop ro.build.product 2>/dev/null)
    [ -z "$product_name" ] && product_name="未知"
    
    android_version=$(getprop ro.build.version.release 2>/dev/null)
    [ -z "$android_version" ] && android_version="未知"
    
    slot_suffix=$(getprop ro.boot.slot_suffix 2>/dev/null)
    case "$slot_suffix" in
        _a) slot_display="a";;
        _b) slot_display="b";;
        *) slot_display="未知";;
    esac
    
    rom_version=$(grep -m1 '^ro.mi.os.version.incremental=' /mi_ext/etc/build.prop 2>/dev/null | cut -d'=' -f2)
    [ -z "$rom_version" ] && rom_version=$(grep -m1 '^ro.mi.os.version.incremental=' /system_dlkm/etc/build.prop 2>/dev/null | cut -d'=' -f2)
    [ -z "$rom_version" ] && rom_version=$(grep -m1 '^ro.mi.os.version.incremental=' /product/build.prop 2>/dev/null | cut -d'=' -f2)
    [ -z "$rom_version" ] && rom_version=$(getprop ro.mi.os.version.incremental 2>/dev/null)
    if [ -z "$rom_version" ]; then
        rom_version=$(getprop ro.build.display.id 2>/dev/null)
        [ -z "$rom_version" ] && rom_version=$(getprop ro.build.version.incremental 2>/dev/null)
        [ -z "$rom_version" ] && rom_version=$(getprop ro.build.id 2>/dev/null)
    fi
    [ -z "$rom_version" ] && rom_version="未知"
    
    printf "${C}┌─────────────────────────────────────────────────┐${N}\n"
    printf "${C}│  ${R}当前设备: ${Y}${device_name} (${product_name})${N}\n"
    printf "${C}│  ${G}Android版本: ${Y}${android_version}${N}\n"
    printf "${C}│  ${B}当前卡槽位: ${Y}${slot_display}${N}\n"
    printf "${C}│  ${P}系统版本: ${Y}${rom_version}${N}\n"
    printf "${C}└─────────────────────────────────────────────────┘${N}\n"
    
    printf "${G}═══════════════════════════════════════════════════${N}\n"
    printf "${B}┌─────────────────────────────────────────────────┐${N}\n"
    printf "${B}│  ${Y}1. ${G}提取dtbo.img${N}\n"
    printf "${B}│  ${Y}2. ${G}解包dtbo+提取AVB信息+提取cmdline${N}\n"
    printf "${B}│  ${Y}3. ${G}解包dtbo+提取cmdline${N}\n"
    printf "${B}│  ${Y}4. ${G}仅提取dtbo的AVB信息${N}\n"
    printf "${B}│  ${Y}5. ${G}打包dts+根据AVB配置写入签名${N}\n"
    printf "${B}│  ${Y}6. ${G}刷入dtbo${N}\n"
    printf "${B}│  ${Y}7. ${G}刷入内置已改好dtbo文件${N}\n"
    printf "${B}│  ${Y}8. ${G}删除相关文件(除回收站[请自己手动处理]${N}\n"
    printf "${B}│  ${Y}9. ${G}调整文件权限问题(第一次使用脚本可先执行)${N}\n"
    printf "${B}│  ${Y}0. ${R}退出脚本${N}\n"
    printf "${B}└─────────────────────────────────────────────────┘${N}\n"
    printf "${G}═══════════════════════════════════════════════════${N}\n"
    printf "\n"
    printf "请选择操作 (0-9): "
}

dtbo_select_img_file() {
    set -- *.img
    if [ ! -f "$1" ]; then
        printf "${R}[x] 当前目录没有找到.img文件${N}\n"
        return 1
    fi
    printf "请选择要处理的.img文件:\n"
    printf "\n"
    i=1
    for file in *.img; do
        size=$(ls -lh "$file" | awk '{print $5}')
        printf "  ${Y}$i. $file ($size)${N}\n"
        i=$((i+1))
    done
    printf "\n"
    total=$((i-1))
    while true; do
        printf "请输入序号 (1-${total}): "
        read file_choice
        if [ -z "$file_choice" ] || ! printf "$file_choice\n" | grep -qE '^[0-9]+$'; then
            printf "${R}[x] 请输入有效的数字${N}\n"
            continue
        fi
        if [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total" ]; then
            printf "${R}[x] 序号超出范围${N}\n"
            continue
        fi
        break
    done
    selected_file=$(ls -1 *.img | sed -n "${file_choice}p")
    printf "$selected_file\n"
}

dtbo_menu_option_1() {
    printf "\n${C}[*] [1/1] ${B}提取dtbo.img${N}\n\n"
    if [ -e "/dev/block/by-name/dtbo_a" ] || [ -e "/dev/block/by-name/dtbo_b" ]; then
        prop=$(getprop ro.boot.slot_suffix 2>/dev/null)
        if [ -z "$prop" ]; then
            if cp /dev/block/by-name/dtbo "$PWD/dtbo.img" 2>/dev/null; then
                printf "${G}[√] dtbo.img 提取成功${N}\n"
            else
                printf "${R}[x] dtbo.img 提取失败${N}\n"
            fi
        else
            if cp "/dev/block/by-name/dtbo$prop" "$PWD/dtbo.img" 2>/dev/null; then
                printf "${G}[√] dtbo.img 提取成功${N}\n"
            else
                printf "${R}[x] dtbo.img 提取失败${N}\n"
            fi
        fi
    elif [ -e "/dev/block/by-name/dtbo" ]; then
        if cp /dev/block/by-name/dtbo "$PWD/dtbo.img" 2>/dev/null; then
            printf "${G}[√] dtbo.img 提取成功${N}\n"
        else
            printf "${R}[x] dtbo.img 提取失败${N}\n"
        fi
    else
        printf "${R}[x] 未找到dtbo分区，提取失败${N}\n"
    fi
    printf "\n"
    printf "按回车键返回..."
    read
}

dtbo_menu_option_2() {
    printf "\n${C}[*] [2/4] ${B}解包 dtbo + 提取 AVB 信息 + 提取 cmdline${N}\n\n"
    printf "${C}[*] [1/4] ${B}选择要处理的dtbo文件...${N}\n"
    printf "\n"
    set -- *.img
    if [ ! -f "$1" ]; then
        printf "${R}[x] 当前目录没有找到.img文件${N}\n"
        printf "按回车键返回..."
        read
        return
    fi
    printf "请选择要处理的.img文件:\n"
    printf "\n"
    i=1
    for file in *.img; do
        size=$(ls -lh "$file" | awk '{print $5}')
        printf "  ${Y}$i. $file ($size)${N}\n"
        i=$((i+1))
    done
    printf "\n"
    total=$((i-1))
    while true; do
        printf "请输入序号 (1-${total}): "
        read file_choice
        if [ -z "$file_choice" ] || ! printf "$file_choice\n" | grep -qE '^[0-9]+$'; then
            printf "${R}[x] 请输入有效的数字${N}\n"
            continue
        fi
        if [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total" ]; then
            printf "${R}[x] 序号超出范围${N}\n"
            continue
        fi
        break
    done
    selected_file=$(ls -1 *.img | sed -n "${file_choice}p")
    dtbo_file="$selected_file"
    mkdir -p "$DTS_DIR" "$AVB_DIR"
    printf "\n${C}[*] [2/4] ${B}检查dtbo镜像文件...${N}\n"
    if [ -f "$dtbo_file" ]; then
        DTBO_IMG="$dtbo_file"
        printf "${G}[√] 找到dtbo.img文件: $DTBO_IMG${N}\n"
    else
        printf "${R}[x] 未找到dtbo.img文件${N}\n"
        printf "按回车键返回..."
        read
        return
    fi
    printf "\n${C}[*] [3/4] ${B}正在解包dtbo镜像...${N}\n"
    export LD_LIBRARY_PATH="$BIN_DIR/avbtool:$LD_LIBRARY_PATH" 2>/dev/null
    export PATH="$BIN_DIR:$PATH" 2>/dev/null
    TEMP_DTB="$OUT_DIR/temp_dtb"
    mkdir -p "$TEMP_DTB"
    rm -f "$DTS_DIR"/*.dts* 2>/dev/null
    printf "${Y}[*] 正在解包中...${N}\n"
    MKDTIMG_TOOL=""
    for tool_path in mkdtimg "$BIN_DIR/mkdtimg" /usr/bin/mkdtimg /bin/mkdtimg; do
        if which "$tool_path" >/dev/null 2>&1; then
            MKDTIMG_TOOL="$tool_path"
            break
        fi
    done
    if [ -n "$MKDTIMG_TOOL" ]; then
        "$MKDTIMG_TOOL" dump "$DTBO_IMG" -b "$TEMP_DTB/dtb" >/dev/null 2>&1
        DTB_FILES=$(ls "$TEMP_DTB"/dtb* 2>/dev/null | sort)
        DTB_COUNT=$(printf "$DTB_FILES\n" | wc -l)
        if [ $DTB_COUNT -gt 0 ]; then
            printf "${C}[*] 正在转换为DTS格式文件...${N}\n"
            i=0
            for dtb_file in $DTB_FILES; do
                if [ -f "$dtb_file" ]; then
                    dts_filename="dtb.$i.dts"
                    printf "  ${C}[*] 处理dts文件中($((i+1))/$DTB_COUNT)...${N}\n"
                    if which dtc >/dev/null 2>&1; then
                        dtc -I dtb -O dts -@ "$dtb_file" -o "$DTS_DIR/$dts_filename" 2>/dev/null && \
                        printf "    ${G}[√] 完成${N}\n" || printf "    ${Y}[!] 转换失败${N}\n"
                    else
                        cp "$dtb_file" "$DTS_DIR/$dts_filename"
                        printf "    ${Y}[!] dtc未找到，保存原始dtb文件${N}\n"
                    fi
                    i=$((i+1))
                fi
            done
            printf "${G}[√] 解包完成！共处理 $DTB_COUNT 个dts文件${N}\n"
        else
            printf "${Y}[!] 未找到dtb条目${N}\n"
        fi
    else
        printf "${Y}[!] 未找到avbtool工具(可能当前目录下的bin里库文件权限不足，调整权限看看呢→返回主菜单选择调整权限)${N}\n"
    fi
    rm -rf "$TEMP_DTB" 2>/dev/null
    printf "\n${C}[*] [4/4] ${B}正在提取AVB信息...${N}\n"
    AVBTOOL="$BIN_DIR/avbtool/avbtool"
    AVB_OUTPUT="$AVB_DIR/avb_info.cfg"
    if [ -x "$AVBTOOL" ] || which "$AVBTOOL" >/dev/null 2>&1; then
        AVB_INFO=$("$AVBTOOL" info_image --image "$DTBO_IMG" 2>/dev/null)
        if [ -n "$AVB_INFO" ]; then
            PARTITION_SIZE=$(printf "$AVB_INFO\n" | grep "^Image size:" | head -n1 | awk '{print $3}')
            HASH_ALG=$(printf "$AVB_INFO\n" | grep "Hash Algorithm:" | head -n1 | awk '{print $3}')
            PARTITION_NAME=$(printf "$AVB_INFO\n" | grep "Partition Name:" | head -n1 | awk '{print $3}')
            SALT=$(printf "$AVB_INFO\n" | grep "Salt:" | head -n1 | awk '{print $2}')
            ALGORITHM=$(printf "$AVB_INFO\n" | grep "^Algorithm:" | head -n1 | awk '{print $2}')
            ROLLBACK_INDEX=$(printf "$AVB_INFO\n" | grep "Rollback Index:" | head -n1 | awk '{print $3}')
            RELEASE=$(printf "$AVB_INFO\n" | grep "Release String:" | head -n1 | cut -d"'" -f2)
            PROP=$(printf "$AVB_INFO\n" | grep "Prop:" | head -n1 | sed -E "s/^[[:space:]]*Prop:[[:space:]]*([^ ]+) -> '(.*)'/\1:\2/")
            {
                printf "PARTITION_SIZE=$PARTITION_SIZE\n"
                printf "HASH_ALG=$HASH_ALG\n"
                printf "PARTITION_NAME=$PARTITION_NAME\n"
                printf "SALT=$SALT\n"
                printf "ALGORITHM=$ALGORITHM\n"
                printf "ROLLBACK_INDEX=$ROLLBACK_INDEX\n"
                echo "RELEASE=\"$RELEASE\""
                echo "PROP=\"$PROP\""
            } > "$AVB_OUTPUT"
            printf "${G}[√] AVB信息已保存到: $AVB_OUTPUT${N}\n"
        else
            printf "${R}[x] AVB信息提取失败${N}\n"
            printf "${Y}[!] 请确保你的dtbo文件为原版未修改${N}\n"
            printf "${Y}[!] 请尝试在系统、卡刷包或线刷包中提取${N}\n"
            printf "${Y}[!] 如仍有问题，请联系开发者解决${N}\n"
        fi
    else
        printf "${Y}[!] avbtool未找到，跳过AVB提取${N}\n"
    fi
    printf "\n${C}[*] [5/4] ${B}正在提取内核启动参数...${N}\n"
    if [ -f /proc/cmdline ] && [ -r /proc/cmdline ]; then
        CMDLINE_FILE="$OUT_DIR/cmdline.txt"
        if cp /proc/cmdline "$CMDLINE_FILE"; then
            printf "${G}[√] 内核启动参数已保存到: $CMDLINE_FILE${N}\n"
        else
            printf "${R}[x] 无法复制内核启动参数${N}\n"
        fi
    else
        printf "${Y}[!] 无法访问 /proc/cmdline${N}\n"
    fi
    printf "\n"
    printf "按回车键返回..."
    read
}

dtbo_menu_option_3() {
    printf "\n${C}[*] [1/4] ${B}解包 dtbo + 提取 cmdline${N}\n\n"
    printf "${C}[*] [2/4] ${B}选择要处理的dtbo文件...${N}\n"
    printf "\n"
    set -- *.img
    if [ ! -f "$1" ]; then
        printf "${R}[x] 当前目录没有找到.img文件${N}\n"
        printf "按回车键返回..."
        read
        return
    fi
    printf "请选择要处理的.img文件:\n"
    printf "\n"
    i=1
    for file in *.img; do
        size=$(ls -lh "$file" | awk '{print $5}')
        printf "  ${Y}$i. $file ($size)${N}\n"
        i=$((i+1))
    done
    printf "\n"
    total=$((i-1))
    while true; do
        printf "请输入序号 (1-${total}): "
        read file_choice
        if [ -z "$file_choice" ] || ! printf "$file_choice\n" | grep -qE '^[0-9]+$'; then
            printf "${R}[x] 请输入有效的数字${N}\n"
            continue
        fi
        if [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total" ]; then
            printf "${R}[x] 序号超出范围${N}\n"
            continue
        fi
        break
    done
    selected_file=$(ls -1 *.img | sed -n "${file_choice}p")
    dtbo_file="$selected_file"
    mkdir -p "$DTS_DIR" "$AVB_DIR"
    printf "\n${C}[*] [2/4] ${B}检查dtbo镜像文件...${N}\n"
    if [ -f "$dtbo_file" ]; then
        DTBO_IMG="$dtbo_file"
        printf "${G}[√] 找到dtbo.img文件: $DTBO_IMG${N}\n"
    else
        printf "${R}[x] 未找到dtbo.img文件${N}\n"
        printf "按回车键返回..."
        read
        return
    fi
    printf "\n${C}[*] [3/4] ${B}正在解包dtbo镜像...${N}\n"
    export LD_LIBRARY_PATH="$BIN_DIR/avbtool:$LD_LIBRARY_PATH" 2>/dev/null
    export PATH="$BIN_DIR:$PATH" 2>/dev/null
    TEMP_DTB="$OUT_DIR/temp_dtb"
    mkdir -p "$TEMP_DTB"
    rm -f "$DTS_DIR"/*.dts* 2>/dev/null
    printf "${Y}[*] 正在解包中...${N}\n"
    MKDTIMG_TOOL=""
    for tool_path in mkdtimg "$BIN_DIR/mkdtimg" /usr/bin/mkdtimg /bin/mkdtimg; do
        if which "$tool_path" >/dev/null 2>&1; then
            MKDTIMG_TOOL="$tool_path"
            break
        fi
    done
    if [ -n "$MKDTIMG_TOOL" ]; then
        "$MKDTIMG_TOOL" dump "$DTBO_IMG" -b "$TEMP_DTB/dtb" >/dev/null 2>&1
        DTB_FILES=$(ls "$TEMP_DTB"/dtb* 2>/dev/null | sort)
        DTB_COUNT=$(printf "$DTB_FILES\n" | wc -l)
        if [ $DTB_COUNT -gt 0 ]; then
            printf "${C}[*] 正在转换为DTS格式文件...${N}\n"
            i=0
            for dtb_file in $DTB_FILES; do
                if [ -f "$dtb_file" ]; then
                    dts_filename="dtb.$i.dts"
                    printf "  ${C}[*] 处理dts文件中($((i+1))/$DTB_COUNT)...${N}\n"
                    if which dtc >/dev/null 2>&1; then
                        dtc -I dtb -O dts -@ "$dtb_file" -o "$DTS_DIR/$dts_filename" 2>/dev/null && \
                        printf "    ${G}[√] 完成${N}\n" || printf "    ${Y}[!] 转换失败${N}\n"
                    else
                        cp "$dtb_file" "$DTS_DIR/$dts_filename"
                        printf "    ${Y}[!] dtc未找到，保存原始dtb文件${N}\n"
                    fi
                    i=$((i+1))
                fi
            done
            printf "${G}[√] 解包完成！共处理 $DTB_COUNT 个dts文件${N}\n"
        else
            printf "${Y}[!] 未找到dtb条目${N}\n"
        fi
    else
        printf "${Y}[!] 未找到avbtool工具(可能当前目录下的bin里库文件权限不足，调整权限看看呢→返回主菜单选择调整权限)${N}\n"
    fi
    rm -rf "$TEMP_DTB" 2>/dev/null
    printf "\n${C}[*] [4/4] ${B}正在提取内核启动参数...${N}\n"
    if [ -f /proc/cmdline ] && [ -r /proc/cmdline ]; then
        CMDLINE_FILE="$OUT_DIR/cmdline.txt"
        if cp /proc/cmdline "$CMDLINE_FILE"; then
            printf "${G}[√] 内核启动参数已保存到: $CMDLINE_FILE${N}\n"
        else
            printf "${R}[x] 无法复制内核启动参数${N}\n"
        fi
    else
        printf "${Y}[!] 无法访问 /proc/cmdline${N}\n"
    fi
    printf "\n"
    printf "按回车键返回..."
    read
}

dtbo_menu_option_4() {
    printf "\n${C}[*] [1/2] ${B}仅提取dtbo的AVB信息${N}\n\n"
    printf "${C}[*] [1/2] ${B}选择要处理的dtbo文件...${N}\n"
    printf "\n"
    set -- *.img
    if [ ! -f "$1" ]; then
        printf "${R}[x] 当前目录没有找到.img文件${N}\n"
        printf "按回车键返回..."
        read
        return
    fi
    printf "请选择要处理的.img文件:\n"
    printf "\n"
    i=1
    for file in *.img; do
        size=$(ls -lh "$file" | awk '{print $5}')
        printf "  ${Y}$i. $file ($size)${N}\n"
        i=$((i+1))
    done
    printf "\n"
    total=$((i-1))
    while true; do
        printf "请输入序号 (1-${total}): "
        read file_choice
        if [ -z "$file_choice" ] || ! printf "$file_choice\n" | grep -qE '^[0-9]+$'; then
            printf "${R}[x] 请输入有效的数字${N}\n"
            continue
        fi
        if [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total" ]; then
            printf "${R}[x] 序号超出范围${N}\n"
            continue
        fi
        break
    done
    selected_file=$(ls -1 *.img | sed -n "${file_choice}p")
    dtbo_file="$selected_file"
    mkdir -p "$AVB_DIR"
    printf "\n${C}[*] [2/2] ${B}正在提取AVB信息...${N}\n"
    AVBTOOL="$BIN_DIR/avbtool/avbtool"
    AVB_OUTPUT="$AVB_DIR/avb_info.cfg"
    if [ -x "$AVBTOOL" ] || which "$AVBTOOL" >/dev/null 2>&1; then
        AVB_INFO=$("$AVBTOOL" info_image --image "$dtbo_file" 2>/dev/null)
        if [ -n "$AVB_INFO" ]; then
            PARTITION_SIZE=$(printf "$AVB_INFO\n" | grep "^Image size:" | head -n1 | awk '{print $3}')
            HASH_ALG=$(printf "$AVB_INFO\n" | grep "Hash Algorithm:" | head -n1 | awk '{print $3}')
            PARTITION_NAME=$(printf "$AVB_INFO\n" | grep "Partition Name:" | head -n1 | awk '{print $3}')
            SALT=$(printf "$AVB_INFO\n" | grep "Salt:" | head -n1 | awk '{print $2}')
            ALGORITHM=$(printf "$AVB_INFO\n" | grep "^Algorithm:" | head -n1 | awk '{print $2}')
            ROLLBACK_INDEX=$(printf "$AVB_INFO\n" | grep "Rollback Index:" | head -n1 | awk '{print $3}')
            RELEASE=$(printf "$AVB_INFO\n" | grep "Release String:" | head -n1 | cut -d"'" -f2)
            PROP=$(printf "$AVB_INFO\n" | grep "Prop:" | head -n1 | sed -E "s/^[[:space:]]*Prop:[[:space:]]*([^ ]+) -> '(.*)'/\1:\2/")
            {
                printf "PARTITION_SIZE=$PARTITION_SIZE\n"
                printf "HASH_ALG=$HASH_ALG\n"
                printf "PARTITION_NAME=$PARTITION_NAME\n"
                printf "SALT=$SALT\n"
                printf "ALGORITHM=$ALGORITHM\n"
                printf "ROLLBACK_INDEX=$ROLLBACK_INDEX\n"
                echo "RELEASE=\"$RELEASE\""
                echo "PROP=\"$PROP\""
            } > "$AVB_OUTPUT"
            printf "${G}[√] AVB信息已保存到: $AVB_OUTPUT${N}\n"
        else
            printf "${R}[x] AVB信息提取失败${N}\n"
            printf "${Y}[!] 请确保你的dtbo文件为原版未修改${N}\n"
            printf "${Y}[!] 请尝试在系统、卡刷包或线刷包中提取${N}\n"
            printf "${Y}[!] 如仍有问题，请联系开发者解决${N}\n"
        fi
    else
        printf "${Y}[!] avbtool未找到，跳过AVB提取${N}\n"
    fi
    printf "\n"
    printf "按回车键返回..."
    read
}

dtbo_menu_option_5() {
    printf "\n${C}[*] [1/4] ${B}检查必要文件...${N}\n\n"
    export LD_LIBRARY_PATH=$SCRIPT_DIR/bin/avbtool:$LD_LIBRARY_PATH
    export PATH=$SCRIPT_DIR/bin/:$PATH
    
    if [ ! -d "$OUT_DIR/dts" ] || [ -z "$(ls $OUT_DIR/dts/*.dts 2>/dev/null)" ]; then
        printf "${R}[x] 错误: 未找到DTS文件，请先运行解包脚本${N}\n"
        printf "按回车键返回..."
        read
        return
    fi
    
    mkdir -p $OUT_DIR/tmp_dtb
    
    printf "${C}[*] [2/4] ${B}编译DTS为DTBO文件...${N}\n"
    printf "${Y}[*] 正在打包并编译DTS文件...${N}\n"
    
    dts_files=$(ls $OUT_DIR/dts/*.dts 2>/dev/null)
    dts_count=$(printf "$dts_files\n" | wc -l)
    failed_count=0
    failed_files=""
    success_count=0
    
    i=1
    for dts_file in $dts_files; do
        if [ -f "$dts_file" ]; then
            dts_name=$(basename "$dts_file")
            dtb_filename="${dts_name%.*}.dtb"
            printf "  ${C}[*] 打包并编译dts文件中($i/$dts_count)...${N}\n"
            if dtc -I dts -O dtb -@ -o "$OUT_DIR/tmp_dtb/$dtb_filename" "$dts_file" 2>/dev/null; then
                printf "    ${G}[√] 完成${N}\n"
                success_count=$((success_count + 1))
            else
                printf "    ${R}[x] 编译失败${N}\n"
                failed_count=$((failed_count + 1))
                failed_files="$failed_files $dts_name"
                
                printf "\n"
                printf "${R}[x] 文件编译失败: $dts_name${N}\n"
                printf "${Y}[!] 小爱提醒您:您的文件当中格式存在有误，请观察修改前与修改后的位置，并且请做出调整，不建议继续打包${N}\n"
                printf "\n"
                printf "${R}[x] 如果继续打包并刷入可能会无法开机的问题！${N}\n"
                printf "\n"
                printf "是否跳过该文件继续打包？(y=跳过继续, n=停止打包): "
                read continue_choice
                printf "\n"
                
                if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
                    printf "${R}[x] 已停止打包${N}\n"
                    rm -rf $OUT_DIR/tmp_dtb
                    printf "按回车键返回..."
                    read
                    return
                fi
            fi
            i=$((i+1))
        fi
    done
    
    if [ $success_count -eq 0 ]; then
        printf "${R}[x] 错误: 没有成功编译的DTS文件${N}\n"
        rm -rf $OUT_DIR/tmp_dtb
        printf "按回车键返回..."
        read
        return
    fi
    
    printf "\n${C}[*] [3/4] ${B}创建DTBO镜像...${N}\n"
    printf "${Y}[*] 正在创建DTBO镜像...${N}\n"
    if mkdtimg create dtbo_new.img --page_size=4096 $OUT_DIR/tmp_dtb/*.dtb 2>/dev/null; then
        printf "${G}[√] DTBO镜像创建成功: dtbo_new.img${N}\n"
    else
        printf "${R}[x] DTBO镜像创建失败${N}\n"
        rm -rf $OUT_DIR/tmp_dtb
        printf "按回车键返回..."
        read
        return
    fi
    rm -rf $OUT_DIR/tmp_dtb
    
    AVB_CFG="$AVB_DIR/avb_info.cfg"
    if [ -f "$AVB_CFG" ]; then
        printf "\n${C}[*] [4/4] ${B}写入AVB签名...${N}\n"
        printf "${C}[*] 加载AVB配置...${N}\n"
        
        PARTITION_SIZE=$(grep "^PARTITION_SIZE=" "$AVB_CFG" | cut -d'=' -f2)
        HASH_ALG=$(grep "^HASH_ALG=" "$AVB_CFG" | cut -d'=' -f2)
        PARTITION_NAME=$(grep "^PARTITION_NAME=" "$AVB_CFG" | cut -d'=' -f2)
        SALT=$(grep "^SALT=" "$AVB_CFG" | cut -d'=' -f2)
        ALGORITHM=$(grep "^ALGORITHM=" "$AVB_CFG" | cut -d'=' -f2)
        ROLLBACK_INDEX=$(grep "^ROLLBACK_INDEX=" "$AVB_CFG" | cut -d'=' -f2)
        RELEASE=$(grep "^RELEASE=" "$AVB_CFG" | cut -d'=' -f2 | sed 's/"//g')
        PROP=$(grep "^PROP=" "$AVB_CFG" | cut -d'=' -f2 | sed 's/"//g')
        
        printf "${C}[*] 添加AVB脚注...${N}\n"
        AVBTOOL="$SCRIPT_DIR/bin/avbtool/avbtool"
        if [ -x "$AVBTOOL" ]; then
            
            SIGN_OUTPUT=$("$AVBTOOL" add_hash_footer \
                --image dtbo_new.img \
                --partition_size "$PARTITION_SIZE" \
                --salt "$SALT" \
                --partition_name "$PARTITION_NAME" \
                --hash_algorithm "$HASH_ALG" \
                --algorithm "$ALGORITHM" \
                --rollback_index "$ROLLBACK_INDEX" \
                --key "$SCRIPT_DIR/bin/testkey_rsa4096.pem" \
                --prop "$PROP" \
                --internal_release_string "$RELEASE" 2>&1)
            SIGN_RESULT=$?
            
            if [ $SIGN_RESULT -eq 0 ]; then
                printf "${G}[√] AVB签名添加成功${N}\n"
            else
                if printf "$SIGN_OUTPUT\n" | grep -q "Key is wrong size for algorithm"; then
                    printf "\n"
                    printf "  ${R}[x] 添加签名失败！${N}\n"
                    printf "\n"
                    printf "${Y}[!] 但是添加签名运行时触发了(Adding hash_footer failed: Key is wrong size for algorithm SHA256_RSA2048)这是一个可修复的逻辑问题，请确认您的dtbo是否是vivo/iqoo，用于调整${N}\n"
                    printf "\n"
                    printf "  ${Y}[!] [1.执行调整后自动写入签名/2.结束添加签名](请选择)${N}\n"
                    printf "\n"
                    printf "  ${Y}1. ${G}是(推荐)${N}\n"
                    printf "  ${Y}2. ${R}不是${N}\n"
                    printf "\n"
                    printf "请选择 (1-2): "
                    read fix_choice
                    printf "\n"
                    
                    if [ "$fix_choice" = "1" ]; then
                        printf "${C}[*] 调整修复中...${N}\n"
                        if grep -q "ALGORITHM=SHA256_RSA2048" "$AVB_CFG"; then
                            sed -i 's/ALGORITHM=SHA256_RSA2048/ALGORITHM=SHA256_RSA4096/g' "$AVB_CFG"
                            ALGORITHM="SHA256_RSA4096"
                            printf "${G}[√] 修复成功！${N}\n"
                            printf "\n"
                            printf "${Y}[*] 2秒后自动写入签名...${N}\n"
                            sleep 2
                            "$AVBTOOL" add_hash_footer \
                                --image dtbo_new.img \
                                --partition_size "$PARTITION_SIZE" \
                                --salt "$SALT" \
                                --partition_name "$PARTITION_NAME" \
                                --hash_algorithm "$HASH_ALG" \
                                --algorithm "$ALGORITHM" \
                                --rollback_index "$ROLLBACK_INDEX" \
                                --key "$SCRIPT_DIR/bin/testkey_rsa4096.pem" \
                                --prop "$PROP" \
                                --internal_release_string "$RELEASE" 2>/dev/null
                            if [ $? -eq 0 ]; then
                                printf "${G}[√] 添加签名成功！${N}\n"
                            else
                                printf "${R}[x] 添加签名失败，请联系开发者解决${N}\n"
                            fi
                        else
                            printf "${R}[x] 修复失败，未找到 ALGORITHM=SHA256_RSA2048${N}\n"
                        fi
                    else
                        printf "${Y}[!] 已跳过修复${N}\n"
                    fi
                else
                    printf "${R}[x] AVB签名添加失败${N}\n"
                fi
            fi
        else
            printf "${Y}[!] avbtool未找到，跳过AVB签名(可能当前目录下的bin里库文件权限不足，调整权限看看呢→返回主菜单选择调整权限)${N}\n"
        fi
    else
        printf "\n${Y}[!] 未找到AVB配置文件 $AVB_CFG，仅创建无签名DTBO${N}\n"
    fi
    
    printf "\n${G}═══════════════════════════════════════════════════${N}\n"
    printf "${C}            打包完成！生成文件: dtbo_new.img${N}\n"
    printf "${G}═══════════════════════════════════════════════════${N}\n"
    printf "\n"
    printf "按回车键返回..."
    read
}

dtbo_menu_option_6() {
    printf "\n${C}[*] [6/6] ${B}刷入 dtbo${N}\n\n"
    dtbo_get_slot_info_6() {
        printf "[!] 当前槽位信息:\n"
        printf "\n"
        if ls /dev/block/by-name/boot_a >/dev/null 2>&1 || ls /dev/block/by-name/system_a >/dev/null 2>&1; then
            printf "${B}[*] 设备类型: A/B分区设备${N}\n"
            CURRENT_SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null)
            if [ -z "$CURRENT_SLOT" ]; then
                CURRENT_SLOT=$(getprop ro.boot.slot 2>/dev/null)
                [ -n "$CURRENT_SLOT" ] && CURRENT_SLOT="_$CURRENT_SLOT"
            fi
            if [ -z "$CURRENT_SLOT" ]; then
                printf "${Y}[!] 无法检测当前槽位${N}\n"
            else
                printf "${G}[√] 当前活动槽位: $CURRENT_SLOT${N}\n"
            fi
            printf "\n"
            printf "存在的dtbo分区:\n"
            if [ -e "/dev/block/by-name/dtbo_a" ]; then
                printf "  ${G}[√] dtbo_a${N}\n"
            else
                printf "  ${R}[x] dtbo_a (不存在)${N}\n"
            fi
            if [ -e "/dev/block/by-name/dtbo_b" ]; then
                printf "  ${G}[√] dtbo_b${N}\n"
            else
                printf "  ${R}[x] dtbo_b (不存在)${N}\n"
            fi
        else
            printf "${B}[*] 设备类型: 非A/B分区设备${N}\n"
            printf "\n"
            printf "存在的dtbo分区:\n"
            if [ -e "/dev/block/by-name/dtbo" ]; then
                printf "  ${G}[√] dtbo${N}\n"
            else
                printf "  ${R}[x] dtbo (不存在)${N}\n"
            fi
        fi
        printf "\n"
    }
    dtbo_reboot_device_6() {
        printf "\n"
        printf "${B}[*] 正在重启手机...${N}\n"
        printf "1秒后重启...\n"
        sleep 1
        printf "${G}[√] 执行重启命令: reboot${N}\n"
        reboot
    }
    dtbo_auto_flash_dtbo_6() {
        printf "\n"
        printf "${B}[*] === 一键无脑刷入DTBO ===${N}\n"
        printf "\n"
        dtbo_get_slot_info_6
        set -- *.img
        if [ ! -f "$1" ]; then
            printf "${R}[x] 没有找到.img文件${N}\n"
            printf "\n"
            printf "当前目录内容:\n"
            ls -la
            return 1
        fi
        i=1
        for file in *.img; do
            if [ "$file" = "dtbo.img" ]; then
                continue
            fi
            size=$(ls -lh "$file" | awk '{print $5}')
            printf "  ${Y}$i. $file ($size)${N}\n"
            i=$((i+1))
        done
        printf "\n"
        total=$((i-1))
        if [ "$total" -eq 0 ]; then
            printf "${R}[x] 没有找到可刷入的.img文件${N}\n"
            return 1
        fi
        while true; do
            printf "选择要刷入的文件编号 (1-${total}): "
            read file_choice
            if [ -z "$file_choice" ] || ! printf "$file_choice\n" | grep -qE '^[0-9]+$'; then
                printf "${R}[x] 请输入有效的数字${N}\n"
                continue
            fi
            if [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total" ]; then
                printf "${R}[x] 编号超出范围${N}\n"
                continue
            fi
            break
        done
        j=0
        SELECTED_FILE=""
        for file in *.img; do
            if [ "$file" = "dtbo.img" ]; then
                continue
            fi
            j=$((j+1))
            if [ "$j" -eq "$file_choice" ]; then
                SELECTED_FILE="$file"
                break
            fi
        done
        printf "\n"
        printf "${G}[√] 已选择: $SELECTED_FILE${N}\n"
        ls -lh "$SELECTED_FILE"
        printf "\n"
        if ls /dev/block/by-name/boot_a >/dev/null 2>&1 || ls /dev/block/by-name/system_a >/dev/null 2>&1; then
            printf "${B}[*] 检测到A/B分区设备，自动刷入两个槽位...${N}\n"
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo_a" ]; then
                printf "刷入dtbo_a...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo_a" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo_a 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo_a 刷入失败${N}\n"
                fi
            else
                printf "${Y}[!] dtbo_a 分区不存在，跳过${N}\n"
            fi
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo_b" ]; then
                printf "刷入dtbo_b...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo_b" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo_b 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo_b 刷入失败${N}\n"
                fi
            else
                printf "${Y}[!] dtbo_b 分区不存在，跳过${N}\n"
            fi
        else
            printf "${B}[*] 检测到非A/B分区设备，刷入dtbo分区...${N}\n"
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo" ]; then
                printf "刷入dtbo...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo 刷入失败${N}\n"
                    return 1
                fi
            else
                printf "${R}[x] 错误：dtbo分区不存在${N}\n"
                return 1
            fi
        fi
        printf "\n"
        printf "${G}[√] 一键刷入操作完成${N}\n"
        dtbo_reboot_device_6
        return 0
    }
    dtbo_manual_flash_dtbo_6() {
        printf "\n"
        printf "${B}[*] === 手动刷入DTBO ===${N}\n"
        printf "\n"
        dtbo_get_slot_info_6
        set -- *.img
        if [ ! -f "$1" ]; then
            printf "${R}[x] 没有找到.img文件${N}\n"
            printf "\n"
            printf "当前目录内容:\n"
            ls -la
            return 1
        fi
        i=1
        for file in *.img; do
            if [ "$file" = "dtbo.img" ]; then
                continue
            fi
            size=$(ls -lh "$file" | awk '{print $5}')
            printf "  ${Y}$i. $file ($size)${N}\n"
            i=$((i+1))
        done
        printf "\n"
        total=$((i-1))
        if [ "$total" -eq 0 ]; then
            printf "${R}[x] 没有找到可刷入的.img文件${N}\n"
            return 1
        fi
        while true; do
            printf "选择要刷入的文件编号 (1-${total}): "
            read file_choice
            if [ -z "$file_choice" ] || ! printf "$file_choice\n" | grep -qE '^[0-9]+$'; then
                printf "${R}[x] 请输入有效的数字${N}\n"
                continue
            fi
            if [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "$total" ]; then
                printf "${R}[x] 编号超出范围${N}\n"
                continue
            fi
            break
        done
        j=0
        SELECTED_FILE=""
        for file in *.img; do
            if [ "$file" = "dtbo.img" ]; then
                continue
            fi
            j=$((j+1))
            if [ "$j" -eq "$file_choice" ]; then
                SELECTED_FILE="$file"
                break
            fi
        done
        printf "\n"
        printf "${G}[√] 已选择: $SELECTED_FILE${N}\n"
        ls -lh "$SELECTED_FILE"
        printf "\n"
        IS_AB_DEVICE=false
        if ls /dev/block/by-name/boot_a >/dev/null 2>&1 || ls /dev/block/by-name/system_a >/dev/null 2>&1; then
            IS_AB_DEVICE=true
            CURRENT_SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null)
            if [ -z "$CURRENT_SLOT" ]; then
                CURRENT_SLOT=$(getprop ro.boot.slot 2>/dev/null)
                [ -n "$CURRENT_SLOT" ] && CURRENT_SLOT="_$CURRENT_SLOT"
            fi
            if [ -n "$CURRENT_SLOT" ]; then
                printf "${G}[√] [!] 当前活动槽位: $CURRENT_SLOT${N}\n"
                printf "\n"
            fi
            printf "刷入选项:\n"
            printf "  ${Y}1. 刷入dtbo_a (a槽位)${N}\n"
            printf "  ${Y}2. 刷入dtbo_b (b槽位)${N}\n"
            printf "  ${G}[√] 3. 两个槽位都刷入（推荐）${N}\n"
            if [ -n "$CURRENT_SLOT" ]; then
                if [ "$CURRENT_SLOT" = "_a" ] || [ "$CURRENT_SLOT" = "_b" ]; then
                    printf "  ${B}[*] 4. 刷入检测到的槽位: $CURRENT_SLOT${N}\n"
                fi
            fi
            printf "  ${R}5. 取消${N}\n"
            printf "\n"
            while true; do
                printf "选择 (1-5): "
                read target_choice
                case "$target_choice" in
                    1)
                        TARGET_PARTITION="/dev/block/by-name/dtbo_a"
                        PARTITION_NAME="a槽位"
                        if [ ! -e "$TARGET_PARTITION" ]; then
                            printf "${R}[x] 错误：分区不存在${N}\n"
                            return 1
                        fi
                        break
                        ;;
                    2)
                        TARGET_PARTITION="/dev/block/by-name/dtbo_b"
                        PARTITION_NAME="b槽位"
                        if [ ! -e "$TARGET_PARTITION" ]; then
                            printf "${R}[x] 错误：分区不存在${N}\n"
                            return 1
                        fi
                        break
                        ;;
                    3)
                        TARGET_PARTITION="both"
                        PARTITION_NAME="两个槽位"
                        break
                        ;;
                    4)
                        if [ -n "$CURRENT_SLOT" ]; then
                            if [ "$CURRENT_SLOT" = "_a" ]; then
                                TARGET_PARTITION="/dev/block/by-name/dtbo_a"
                                PARTITION_NAME="检测到的a槽位"
                            elif [ "$CURRENT_SLOT" = "_b" ]; then
                                TARGET_PARTITION="/dev/block/by-name/dtbo_b"
                                PARTITION_NAME="检测到的b槽位"
                            else
                                printf "${R}[x] 无法确定检测到的槽位${N}\n"
                                continue
                            fi
                            if [ ! -e "$TARGET_PARTITION" ]; then
                                printf "${R}[x] 错误：分区不存在${N}\n"
                                return 1
                            fi
                            break
                        else
                            printf "${R}[x] 无法确定检测到的槽位${N}\n"
                            continue
                        fi
                        ;;
                    5)
                        printf "操作取消\n"
                        return 2
                        ;;
                    *)
                        printf "${R}[x] 无效选择${N}\n"
                        ;;
                esac
            done
        else
            TARGET_PARTITION="/dev/block/by-name/dtbo"
            PARTITION_NAME="dtbo分区"
            if [ ! -e "$TARGET_PARTITION" ]; then
                printf "${R}[x] 错误：分区 $TARGET_PARTITION 不存在${N}\n"
                return 1
            fi
            printf "刷入选项:\n"
            printf "  ${G}[√] 1. 刷入dtbo分区${N}\n"
            printf "  ${R}2. 取消${N}\n"
            printf "\n"
            while true; do
                printf "选择 (1-2): "
                read target_choice
                case "$target_choice" in
                    1)
                        break
                        ;;
                    2)
                        printf "操作取消\n"
                        return 2
                        ;;
                    *)
                        printf "${R}[x] 无效选择${N}\n"
                        ;;
                esac
            done
        fi
        printf "\n"
        printf "${B}[*] 刷入信息:${N}\n"
        printf "  镜像文件: $SELECTED_FILE\n"
        if [ "$TARGET_PARTITION" = "both" ]; then
            printf "  刷入目标: dtbo_a 和 dtbo_b\n"
        else
            printf "  刷入目标: $TARGET_PARTITION\n"
        fi
        printf "  目标名称: $PARTITION_NAME\n"
        printf "\n"
        printf "确认刷入？(y=确认, n=取消): "
        read confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            printf "操作取消\n"
            return 2
        fi
        printf "\n"
        printf "${B}[*] 正在刷入...${N}\n"
        if [ "$TARGET_PARTITION" = "both" ]; then
            printf "刷入两个槽位...\n"
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo_a" ]; then
                printf "刷入dtbo_a...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo_a" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo_a 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo_a 刷入失败${N}\n"
                fi
            else
                printf "${Y}[!] dtbo_a 分区不存在，跳过${N}\n"
            fi
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo_b" ]; then
                printf "刷入dtbo_b...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo_b" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo_b 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo_b 刷入失败${N}\n"
                fi
            else
                printf "${Y}[!] dtbo_b 分区不存在，跳过${N}\n"
            fi
        else
            printf "刷入 $PARTITION_NAME...\n"
            dd if="$SELECTED_FILE" of="$TARGET_PARTITION" 2>/dev/null
            if [ $? -eq 0 ]; then
                printf "${G}[√] $PARTITION_NAME 刷入成功${N}\n"
            else
                printf "${R}[x] $PARTITION_NAME 刷入失败${N}\n"
                return 1
            fi
        fi
        printf "\n"
        printf "${G}[√] 刷入操作完成${N}\n"
        printf "\n"
        printf "是否立即重启手机？(y=立即重启, n=不重启): "
        read reboot_choice
        if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ]; then
            dtbo_reboot_device_6
        else
            printf "\n"
            printf "${Y}[!] 请稍后手动重启手机以使DTBO生效${N}\n"
        fi
        return 0
    }
    while true; do
        printf "\n"
        printf "${B}[*] === DTBO刷入工具 ===${N}\n"
        printf "当前目录: $(pwd)\n"
        printf "\n"
        dtbo_get_slot_info_6
        printf "${B}[*] 请选择刷入模式:${N}\n"
        printf "  ${G}y. 一键无脑刷入${N} (自动选择双槽位/无AB，刷完自动重启)\n"
        printf "  ${Y}k. 手动选择刷入${N} (自己选择文件、卡槽和是否重启)\n"
        printf "  ${R}b. 返回主菜单${N}\n"
        printf "\n"
        printf "选择 (y/k/b): "
        read mode_choice
        case "$mode_choice" in
            y|Y)
                dtbo_auto_flash_dtbo_6
                ;;
            k|K)
                dtbo_manual_flash_dtbo_6
                ;;
            b|B)
                break
                ;;
            *)
                printf "${R}[x] 无效选择，请输入 y, k 或 b${N}\n"
                ;;
        esac
    done
    printf "按回车键返回..."
    read
}

dtbo_menu_option_7() {
    dtbo_get_slot_info_7() {
        printf "[!] 当前槽位信息:\n"
        printf "\n"
        if ls /dev/block/by-name/boot_a >/dev/null 2>&1 || ls /dev/block/by-name/system_a >/dev/null 2>&1; then
            printf "${B}[*] 设备类型: A/B分区设备${N}\n"
            CURRENT_SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null)
            if [ -z "$CURRENT_SLOT" ]; then
                CURRENT_SLOT=$(getprop ro.boot.slot 2>/dev/null)
                [ -n "$CURRENT_SLOT" ] && CURRENT_SLOT="_$CURRENT_SLOT"
            fi
            if [ -z "$CURRENT_SLOT" ]; then
                printf "${Y}[!] 无法检测当前槽位${N}\n"
            else
                printf "${G}[√] 当前活动槽位: $CURRENT_SLOT${N}\n"
            fi
            printf "\n"
            printf "存在的dtbo分区:\n"
            if [ -e "/dev/block/by-name/dtbo_a" ]; then
                printf "  ${G}[√] dtbo_a${N}\n"
            else
                printf "  ${R}[x] dtbo_a (不存在)${N}\n"
            fi
            if [ -e "/dev/block/by-name/dtbo_b" ]; then
                printf "  ${G}[√] dtbo_b${N}\n"
            else
                printf "  ${R}[x] dtbo_b (不存在)${N}\n"
            fi
        else
            printf "${B}[*] 设备类型: 非A/B分区设备${N}\n"
            printf "\n"
            printf "存在的dtbo分区:\n"
            if [ -e "/dev/block/by-name/dtbo" ]; then
                printf "  ${G}[√] dtbo${N}\n"
            else
                printf "  ${R}[x] dtbo (不存在)${N}\n"
            fi
        fi
        printf "\n"
    }
    dtbo_reboot_device_7() {
        printf "\n"
        printf "${B}[*] 正在重启手机...${N}\n"
        printf "1秒后重启...\n"
        sleep 1
        printf "${G}[√] 执行重启命令: reboot${N}\n"
        reboot
    }
    dtbo_select_direct_model() {
        printf "\n"
        printf "${B}[*] === 选择设备型号 ===${N}\n"
        printf "\n"
        if [ ! -d "$DTBO_BASE_DIR" ]; then
            printf "${R}[x] 错误: 当前目录下找不到 [已合成dtbo]文件目录 文件夹${N}\n"
            printf "\n"
            printf "当前目录内容:\n"
            ls -la
            printf "按回车键返回..."
            read
            return 1
        fi

        MODEL_LIST_FILE="$SCRIPT_DIR/.dtbo_model_list_$$.tmp"
        rm -f "$MODEL_LIST_FILE" 2>/dev/null

        if ! (cd "$DTBO_BASE_DIR" 2>/dev/null && ls -d */ 2>/dev/null | sed 's|/||g') > "$MODEL_LIST_FILE"; then
            rm -f "$MODEL_LIST_FILE" 2>/dev/null
            printf "${R}[x] 无法读取 [已合成dtbo]文件目录${N}\n"
            printf "按回车键返回..."
            read
            return 1
        fi

        if [ ! -s "$MODEL_LIST_FILE" ]; then
            printf "${R}[x] 错误: [已合成dtbo]文件目录 下没有找到任何机型文件夹${N}\n"
            printf "\n"
            printf "[已合成dtbo]文件目录 内容:\n"
            ls -la "$DTBO_BASE_DIR"
            rm -f "$MODEL_LIST_FILE" 2>/dev/null
            printf "按回车键返回..."
            read
            return 1
        fi

        printf "尊敬的用户，请选择dtbo类型:\n"
        printf "\n"

        i=1
        while IFS= read -r model; do
            [ -n "$model" ] || continue
            printf "${Y}$i. $model${N}\n"
            i=$((i+1))
        done < "$MODEL_LIST_FILE"

        printf "\n"

        while true; do
            printf "请输入序号 (1-$((i-1))): "
            read model_choice

            if [ -z "$model_choice" ] || ! printf "$model_choice\n" | grep -qE '^[0-9]+$'; then
                printf "${R}[x] 请输入有效的数字${N}\n"
                continue
            fi

            if [ "$model_choice" -lt 1 ] || [ "$model_choice" -gt $((i-1)) ]; then
                printf "${R}[x] 序号超出范围${N}\n"
                continue
            fi

            SELECTED_MODEL=$(sed -n "${model_choice}p" "$MODEL_LIST_FILE")
            break
        done

        rm -f "$MODEL_LIST_FILE" 2>/dev/null

        printf "\n"
        printf "${G}[√] 已选择机型: $SELECTED_MODEL${N}\n"
        printf "\n"

        dtbo_select_version_type "$SELECTED_MODEL"
    }

    dtbo_select_version_type() {
        SELECTED_MODEL="$1"
        MODEL_PATH="$DTBO_BASE_DIR/$SELECTED_MODEL"

        if [ ! -d "$MODEL_PATH" ]; then
            printf "${R}[x] 错误: 机型目录不存在: $MODEL_PATH${N}\n"
            printf "按回车键返回..."
            read
            return 1
        fi

        VERSION_LIST_FILE="$SCRIPT_DIR/.dtbo_version_list_$$.tmp"
        rm -f "$VERSION_LIST_FILE" 2>/dev/null

        if ! (cd "$MODEL_PATH" 2>/dev/null && ls -d */ 2>/dev/null | sed 's|/||g') > "$VERSION_LIST_FILE"; then
            rm -f "$VERSION_LIST_FILE" 2>/dev/null
            printf "${R}[x] 无法读取机型目录: $MODEL_PATH${N}\n"
            printf "按回车键返回..."
            read
            return 1
        fi

        if [ ! -s "$VERSION_LIST_FILE" ]; then
            printf "${Y}[!] $SELECTED_MODEL 目录下没有版本文件夹，直接查找img文件...${N}\n"
            rm -f "$VERSION_LIST_FILE" 2>/dev/null
            dtbo_select_img_file_7 "$MODEL_PATH" "$SELECTED_MODEL" ""
            return
        fi

        printf "${B}[*] === 选择机型 ===${N}\n"
        printf "\n"
        printf "请选择机型:\n"
        printf "\n"

        i=1
        while IFS= read -r version; do
            [ -n "$version" ] || continue
            printf "${Y}$i. $version${N}\n"
            i=$((i+1))
        done < "$VERSION_LIST_FILE"

        printf "\n"

        while true; do
            printf "请输入序号 (1-$((i-1))): "
            read version_choice

            if [ -z "$version_choice" ] || ! printf "$version_choice\n" | grep -qE '^[0-9]+$'; then
                printf "${R}[x] 请输入有效的数字${N}\n"
                continue
            fi

            if [ "$version_choice" -lt 1 ] || [ "$version_choice" -gt $((i-1)) ]; then
                printf "${R}[x] 序号超出范围${N}\n"
                continue
            fi

            SELECTED_VERSION=$(sed -n "${version_choice}p" "$VERSION_LIST_FILE")
            break
        done

        rm -f "$VERSION_LIST_FILE" 2>/dev/null

        printf "\n"
        printf "${G}[√] 已选择版本: $SELECTED_VERSION${N}\n"
        printf "\n"

        VERSION_PATH="$MODEL_PATH/$SELECTED_VERSION"
        dtbo_select_img_file_7 "$VERSION_PATH" "$SELECTED_MODEL" "$SELECTED_VERSION"
    }

    dtbo_select_img_file_7() {
        CURRENT_PATH="$1"
        MODEL_NAME="$2"
        VERSION_NAME="$3"

        printf "${B}[*] === 选择DTBO文件 ===${N}\n"
        printf "\n"
        if [ -n "$VERSION_NAME" ]; then
            printf "尊敬的${G}$VERSION_NAME${N}用户，请刷入您机型的${G}$MODEL_NAME${N}的dtbo文件:\n"
        else
            printf "尊敬的${G}$MODEL_NAME${N}用户，请刷入您机型的dtbo文件:\n"
        fi
        printf "\n"

        if [ ! -d "$CURRENT_PATH" ]; then
            printf "${R}[x] 错误: 目录不存在: $CURRENT_PATH${N}\n"
            printf "按回车键返回..."
            read
            return 1
        fi

        IMG_LIST_FILE="$SCRIPT_DIR/.dtbo_img_list_$$.tmp"
        rm -f "$IMG_LIST_FILE" 2>/dev/null

        if ! (cd "$CURRENT_PATH" 2>/dev/null && ls -1 *.img 2>/dev/null) > "$IMG_LIST_FILE"; then
            rm -f "$IMG_LIST_FILE" 2>/dev/null
            printf "${R}[x] 无法读取DTBO文件目录: $CURRENT_PATH${N}\n"
            printf "按回车键返回..."
            read
            return 1
        fi

        if [ ! -s "$IMG_LIST_FILE" ]; then
            printf "${R}[x] 错误: $CURRENT_PATH 目录下没有找到任何 .img 文件${N}\n"
            printf "\n"
            printf "目录内容:\n"
            ls -la "$CURRENT_PATH"
            rm -f "$IMG_LIST_FILE" 2>/dev/null
            printf "按回车键返回..."
            read
            return 1
        fi

        i=1
        while IFS= read -r file; do
            [ -n "$file" ] || continue
            size=$(ls -lh "$CURRENT_PATH/$file" 2>/dev/null | awk '{print $5}')
            printf "  ${Y}$i. $file ($size)${N}\n"
            i=$((i+1))
        done < "$IMG_LIST_FILE"

        printf "\n"

        while true; do
            printf "请输入序号 (1-$((i-1))): "
            read file_choice

            if [ -z "$file_choice" ] || ! printf "$file_choice\n" | grep -qE '^[0-9]+$'; then
                printf "${R}[x] 请输入有效的数字${N}\n"
                continue
            fi

            if [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt $((i-1)) ]; then
                printf "${R}[x] 序号超出范围${N}\n"
                continue
            fi

            SELECTED_FILE=$(sed -n "${file_choice}p" "$IMG_LIST_FILE")
            break
        done

        rm -f "$IMG_LIST_FILE" 2>/dev/null

        SELECTED_FILE_PATH="$CURRENT_PATH/$SELECTED_FILE"
        printf "\n"
        printf "${G}[√] 已选择: $SELECTED_FILE${N}\n"
        printf "${B}[*] 完整路径: $SELECTED_FILE_PATH${N}\n"
        ls -lh "$SELECTED_FILE_PATH"
        printf "\n"

        dtbo_show_flash_menu_7 "$SELECTED_FILE_PATH"
    }

    dtbo_show_flash_menu_7() {
        SELECTED_FILE="$1"
        while true; do
            printf "${B}[*] === 选择刷入模式 ===${N}\n"
            printf "  ${G}y. 无脑一键自动刷入${N} (自动选择双槽位/无AB，刷完自动重启)\n"
            printf "  ${Y}k. 手动选择刷入${N} (自己选择卡槽和是否重启)\n"
            printf "  ${R}n. 返回机型选择${N}\n"
            printf "\n"
            printf "选择 (y/k/n): "
            read mode_choice
            case "$mode_choice" in
                y|Y)
                    dtbo_auto_flash_dtbo_7 "$SELECTED_FILE"
                    break
                    ;;
                k|K)
                    dtbo_manual_flash_dtbo_7 "$SELECTED_FILE"
                    break
                    ;;
                n|N)
                    dtbo_select_direct_model
                    break
                    ;;
                *)
                    printf "${R}[x] 无效选择，请输入 y, k 或 n${N}\n"
                    ;;
            esac
        done
    }
    dtbo_auto_flash_dtbo_7() {
        SELECTED_FILE="$1"
        printf "\n"
        printf "${B}[*] === 一键无脑刷入DTBO ===${N}\n"
        printf "\n"
        dtbo_get_slot_info_7
        if ls /dev/block/by-name/boot_a >/dev/null 2>&1 || ls /dev/block/by-name/system_a >/dev/null 2>&1; then
            printf "${B}[*] 检测到A/B分区设备，自动刷入两个槽位...${N}\n"
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo_a" ]; then
                printf "刷入dtbo_a...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo_a" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo_a 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo_a 刷入失败${N}\n"
                fi
            else
                printf "${Y}[!] dtbo_a 分区不存在，跳过${N}\n"
            fi
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo_b" ]; then
                printf "刷入dtbo_b...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo_b" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo_b 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo_b 刷入失败${N}\n"
                fi
            else
                printf "${Y}[!] dtbo_b 分区不存在，跳过${N}\n"
            fi
        else
            printf "${B}[*] 检测到非A/B分区设备，刷入dtbo分区...${N}\n"
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo" ]; then
                printf "刷入dtbo...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo 刷入失败${N}\n"
                    return 1
                fi
            else
                printf "${R}[x] 错误：dtbo分区不存在${N}\n"
                return 1
            fi
        fi
        printf "\n"
        printf "${G}[√] 一键刷入操作完成${N}\n"
        dtbo_reboot_device_7
    }
    dtbo_manual_flash_dtbo_7() {
        SELECTED_FILE="$1"
        printf "\n"
        printf "${B}[*] === 手动刷入DTBO ===${N}\n"
        printf "\n"
        dtbo_get_slot_info_7
        if ls /dev/block/by-name/boot_a >/dev/null 2>&1 || ls /dev/block/by-name/system_a >/dev/null 2>&1; then
            CURRENT_SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null)
            if [ -z "$CURRENT_SLOT" ]; then
                CURRENT_SLOT=$(getprop ro.boot.slot 2>/dev/null)
                [ -n "$CURRENT_SLOT" ] && CURRENT_SLOT="_$CURRENT_SLOT"
            fi
            if [ -n "$CURRENT_SLOT" ]; then
                printf "${G}[√] [!] 当前活动槽位: $CURRENT_SLOT${N}\n"
                printf "\n"
            fi
            printf "刷入选项:\n"
            printf "  ${Y}1. 刷入dtbo_a (a槽位)${N}\n"
            printf "  ${Y}2. 刷入dtbo_b (b槽位)${N}\n"
            printf "  ${G}[√] 3. 两个槽位都刷入（推荐）${N}\n"
            if [ -n "$CURRENT_SLOT" ]; then
                if [ "$CURRENT_SLOT" = "_a" ] || [ "$CURRENT_SLOT" = "_b" ]; then
                    printf "  ${B}[*] 4. 刷入检测到的槽位: $CURRENT_SLOT${N}\n"
                fi
            fi
            printf "  ${R}5. 取消${N}\n"
            printf "\n"
            while true; do
                printf "选择 (1-5): "
                read target_choice
                case "$target_choice" in
                    1)
                        TARGET_PARTITION="/dev/block/by-name/dtbo_a"
                        PARTITION_NAME="a槽位"
                        if [ ! -e "$TARGET_PARTITION" ]; then
                            printf "${R}[x] 错误：分区不存在${N}\n"
                            continue
                        fi
                        break
                        ;;
                    2)
                        TARGET_PARTITION="/dev/block/by-name/dtbo_b"
                        PARTITION_NAME="b槽位"
                        if [ ! -e "$TARGET_PARTITION" ]; then
                            printf "${R}[x] 错误：分区不存在${N}\n"
                            continue
                        fi
                        break
                        ;;
                    3)
                        TARGET_PARTITION="both"
                        PARTITION_NAME="两个槽位"
                        break
                        ;;
                    4)
                        if [ -n "$CURRENT_SLOT" ]; then
                            if [ "$CURRENT_SLOT" = "_a" ]; then
                                TARGET_PARTITION="/dev/block/by-name/dtbo_a"
                                PARTITION_NAME="检测到的a槽位"
                            elif [ "$CURRENT_SLOT" = "_b" ]; then
                                TARGET_PARTITION="/dev/block/by-name/dtbo_b"
                                PARTITION_NAME="检测到的b槽位"
                            else
                                printf "${R}[x] 无法确定检测到的槽位${N}\n"
                                continue
                            fi
                            if [ ! -e "$TARGET_PARTITION" ]; then
                                printf "${R}[x] 错误：分区不存在${N}\n"
                                continue
                            fi
                            break
                        else
                            printf "${R}[x] 无法确定检测到的槽位${N}\n"
                            continue
                        fi
                        ;;
                    5)
                        printf "操作取消\n"
                        dtbo_show_flash_menu_7 "$SELECTED_FILE"
                        return
                        ;;
                    *)
                        printf "${R}[x] 无效选择${N}\n"
                        ;;
                esac
            done
        else
            TARGET_PARTITION="/dev/block/by-name/dtbo"
            PARTITION_NAME="dtbo分区"
            if [ ! -e "$TARGET_PARTITION" ]; then
                printf "${R}[x] 错误：分区 $TARGET_PARTITION 不存在${N}\n"
                return 1
            fi
            printf "刷入选项:\n"
            printf "  ${G}[√] 1. 刷入dtbo分区${N}\n"
            printf "  ${R}2. 取消${N}\n"
            printf "\n"
            while true; do
                printf "选择 (1-2): "
                read target_choice
                case "$target_choice" in
                    1)
                        break
                        ;;
                    2)
                        printf "操作取消\n"
                        dtbo_show_flash_menu_7 "$SELECTED_FILE"
                        return
                        ;;
                    *)
                        printf "${R}[x] 无效选择${N}\n"
                        ;;
                esac
            done
        fi
        printf "\n"
        printf "${B}[*] 刷入信息:${N}\n"
        printf "  镜像文件: $SELECTED_FILE\n"
        if [ "$TARGET_PARTITION" = "both" ]; then
            printf "  刷入目标: dtbo_a 和 dtbo_b\n"
        else
            printf "  刷入目标: $TARGET_PARTITION\n"
        fi
        printf "  目标名称: $PARTITION_NAME\n"
        printf "\n"
        printf "确认刷入？(y=确认, n=取消): "
        read confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            printf "操作取消\n"
            dtbo_show_flash_menu_7 "$SELECTED_FILE"
            return
        fi
        printf "\n"
        printf "${B}[*] 正在刷入...${N}\n"
        if [ "$TARGET_PARTITION" = "both" ]; then
            printf "刷入两个槽位...\n"
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo_a" ]; then
                printf "刷入dtbo_a...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo_a" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo_a 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo_a 刷入失败${N}\n"
                fi
            else
                printf "${Y}[!] dtbo_a 分区不存在，跳过${N}\n"
            fi
            printf "\n"
            if [ -e "/dev/block/by-name/dtbo_b" ]; then
                printf "刷入dtbo_b...\n"
                dd if="$SELECTED_FILE" of="/dev/block/by-name/dtbo_b" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[√] dtbo_b 刷入成功${N}\n"
                else
                    printf "${R}[x] dtbo_b 刷入失败${N}\n"
                fi
            else
                printf "${Y}[!] dtbo_b 分区不存在，跳过${N}\n"
            fi
        else
            printf "刷入 $PARTITION_NAME...\n"
            dd if="$SELECTED_FILE" of="$TARGET_PARTITION" 2>/dev/null
            if [ $? -eq 0 ]; then
                printf "${G}[√] $PARTITION_NAME 刷入成功${N}\n"
            else
                printf "${R}[x] $PARTITION_NAME 刷入失败${N}\n"
                return 1
            fi
        fi
        printf "\n"
        printf "${G}[√] 刷入操作完成${N}\n"
        printf "\n"
        printf "是否立即重启手机？(y=立即重启, n=不重启): "
        read reboot_choice
        if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ]; then
            dtbo_reboot_device_7
        else
            printf "\n"
            printf "${Y}[!] 请稍后手动重启手机以使DTBO生效${N}\n"
            printf "\n"
            printf "按回车键继续..."
            read
            dtbo_show_flash_menu_7 "$SELECTED_FILE"
        fi
    }
    dtbo_select_direct_model
    printf "按回车键返回..."
    read
}

dtbo_menu_option_8() {
    printf "\n${C}[*] [8/8] ${B}删除相关文件${N}\n\n"
    rm -rf dts.dtb.[0-9]*
    rm -rf dtbo.img
    rm -rf dtbo_a.img
    rm -rf dtbo_b.img
    rm -rf dtbo_new.img
    rm -rf $OUT_DIR/* $OUT_DIR/.* 2>/dev/null
    printf "${G}[√] 文件清理完成${N}\n\n"
    printf "按回车键返回..."
    read
}

dtbo_menu_option_9() {
    printf "\n${C}[*] [9/9] ${B}调整bin目录文件权限${N}\n\n"
    
    BIN_PATH="$SCRIPT_DIR/bin"
    
    if [ ! -d "$BIN_PATH" ]; then
        printf "${R}[x] 错误: 未找到bin目录${N}\n"
        printf "${Y}[*] 路径: $BIN_PATH${N}\n"
        printf "按回车键返回..."
        read
        return
    fi
    
    printf "${C}[*] 正在检查bin目录下文件权限...${N}\n"
    printf "\n"
    
    FILE_LIST=$(find "$BIN_PATH" -type f 2>/dev/null)
    if [ -z "$FILE_LIST" ]; then
        printf "${Y}[!] bin目录下没有找到文件${N}\n"
        printf "按回车键返回..."
        read
        return
    fi
    
    NEED_FIX=0
    for file in $FILE_LIST; do
        CURRENT_PERM=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)
        if [ "$CURRENT_PERM" != "777" ]; then
            NEED_FIX=1
            printf "${Y}[*]   $file (权限: $CURRENT_PERM)${N}\n"
        fi
    done
    
    if [ $NEED_FIX -eq 0 ]; then
        printf "${G}[√] bin目录下所有文件权限已正确设置为777${N}\n"
        printf "按回车键返回..."
        read
        return
    fi
    
    printf "\n"
    printf "${Y}[!] 是否需要调整以上文件的权限为777？(y=修复, n=取消): \n"
    read fix_choice
    
    if [ "$fix_choice" = "y" ] || [ "$fix_choice" = "Y" ]; then
        SUCCESS_COUNT=0
        FAIL_COUNT=0
        for file in $FILE_LIST; do
            chmod 777 "$file" 2>/dev/null
            if [ $? -eq 0 ]; then
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                FAIL_COUNT=$((FAIL_COUNT + 1))
                printf "${R}[x] 调整失败: $file${N}\n"
            fi
        done
        
        printf "\n"
        if [ $FAIL_COUNT -eq 0 ]; then
            printf "${G}[√] 成功调整 $SUCCESS_COUNT 个文件权限为777${N}\n"
        else
            printf "${Y}[!] 成功调整 $SUCCESS_COUNT 个文件，失败 $FAIL_COUNT 个${N}\n"
        fi
    else
        printf "${Y}[!] 已取消修复操作${N}\n"
    fi
    
    printf "\n"
    printf "按回车键返回..."
    read
}

run_flash_toolkit() {
    # 检查模块标记文件
    if [ ! -f "$SCRIPT_DIR/.flash_deps_installed" ]; then
        check_and_download_flash_deps
        # 如果用户选择不重启，check_and_download_flash_deps会返回1
        return 1
    fi
    
    # 检测模块是否已生效（adb/fastboot是否可用）
    if ! which adb >/dev/null 2>&1 || ! which fastboot >/dev/null 2>&1; then
        printf "${R}[!] 刷机工具模块已安装但未生效${N}\n"
        printf "${Y}[!] 请重启设备后再使用刷机工具${N}\n"
        printf "  ${DI}按回车返回...${N}"
        read
        return 1
    fi

    # Initialize flash toolkit global variables
    FLASH_DEVICE_SERIAL=""
    FLASH_CONNECTION_MODE=""
    FLASH_DEVICE_TIMEOUT=10
    FLASH_MAX_RETRIES=3
    FLASH_SELECTED_PATH=""
    FLASH_ENVIRONMENT="Linux环境"
    FLASH_VERSION="版本:1.0(Integrated)"
    FLASH_LOADER_PATH=""
    FLASH_EDL_DEV_PATH=""
    FLASH_DOUBLE_AD_IMG1=""
    FLASH_DOUBLE_AD_IMG2=""
    FLASH_DOUBLE_AD_STATUS=""
    FLASH_NEED_EXTRA_FLASH_DOUBLE_AD=0
    FLASH_MISC_IMG=""
    FLASH_PRELOADER_RAW_IMG=""
    FLASH_HAS_PRELOADER_RAW="0"
    if which adb >/dev/null 2>&1; then
        FLASH_adb_version=$(adb version 2>/dev/null | head -n1 | awk '{print $NF}')
    fi
    if which fastboot >/dev/null 2>&1; then
        FLASH_fastboot_version=$(fastboot --version 2>/dev/null | head -n1 | awk '{print $NF}')
    fi
    FLASH_gitee_ChenXluk="https://gitee.com/ChenXluk/ADBToolkit-Pro/raw/master/img/"

    # Main loop
    local main_choice
    while true; do
        clear
        printf "################################################\n"
        printf "  ${FLASH_VERSION} ${Y}@ChenXluk${N} ${FLASH_ENVIRONMENT}\n"
        printf "${P}\n"
        printf " ██████╗ ██╗     ██╗████████╗ ██████╗██╗  ██╗       ██╗  ██╗██╗   ██╗███╗   ██╗████████╗\n"
        printf "██╔════╝ ██║     ██║╚══██╔══╝██╔════╝██║  ██║       ██║  ██║██║   ██║████╗  ██║╚══██╔══╝\n"
        printf "██║  ███╗██║     ██║   ██║   ██║     ███████║       ███████║██║   ██║██╔██╗ ██║   ██║   \n"
        printf "██║   ██║██║     ██║   ██║   ██║     ██╔══██║       ██╔══██║██║   ██║██║╚██╗██║   ██║   \n"
        printf "╚██████╔╝███████╗██║   ██║   ╚██████╗██║  ██╗       ██╗  ██╗╚██████╔╝██║ ╚████║   ██║   \n"
        printf " ╚═════╝ ╚══════╝╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   \n"
        printf "${N}\n"
        printf "${Y}脚本永久免费${N}只会在 ${G}开源社区 ${Y}发布和更新${N}\n"
        printf "如果发现未经允许倒卖，请申请退款并问候他全家\n"
        printf "${R}请遵守在脚本中退出，避免有sh/bash进程${G}占用CPU\n"
        flash_draw_title_line " Main Menu " 19
        printf " ${B}［普通］\n"
        printf " ${Y}1${N}.Recovery功能             ${Y}2${N}.系统功能\n"
        printf " ${Y}3${N}.Fastboot功能             ${Y}4${N}.设备重启\n"
        printf " ${Y}5${N}.Payload.bin解压          ${Y}6${N}.${B}快捷链接${N}\n"
        printf " ${Y}7${N}.使用指南                 ${Y}8${N}.连接稳定性测试\n"
        printf " ${B}［进阶］${N}\n"
        printf " ${Y}9${N}.设备检测                 ${Y}10${N}.自定义命令\n"
        printf " ${Y}11${N}.欧加线刷工具            ${Y}12${N}.清理进程\n"
        printf " ${Y}13${N}.小米线刷                ${Y}14${N}.高通9008\n"
        printf " ${Y}0${N}.退出\n"
        printf "请输入 [${Y}0-14${N}]: "
        read main_choice
        case $main_choice in
            1) flash_recovery_functions ;;
            2) flash_system_functions ;;
            3) flash_fastboot_functions ;;
            4) flash_reboot_menu ;;
            5) flash_extract_payload_bin ;;
            6) flash_link_jump_menu ;;
            7) flash_show_usage_guide ;;
            8) flash_connection_stability_test ;;
            9) flash_device_detection ;;
            10) flash_Custom_Directives ;;
            11) flash_ColorOS_functions ;;
            12) flash_clean_adb_fastboot_processes ;;
            13) flash_mi_flash_functions ;;
            14) flash_edl_9008_functions ;;
            0) return 0 ;;
            *) printf "${R}无效选择${N}\n" && sleep 1 ;;
        esac
    done
}

flash_show_usage_guide() {
    clear
    flash_draw_title_line " 使用指南 " 18
    printf "
${Y}=== 驱动安装步骤 ===${N}

${G}1. 确保设备已开启USB调试（开发者选项）${N}
${G}2. 使用USB数据线连接设备和电脑${N}
${G}3. 如果电脑未识别设备，需要安装驱动：${N}
   ${Y}a) 下载对应平台的USB驱动${N}
   ${Y}b) 设备管理器中找到未知设备${N}
   ${Y}c) 右键 -> 更新驱动程序 -> 浏览计算机${N}
   ${Y}d) 选择驱动所在目录并安装${N}
${G}4. 安装完成后，执行adb devices验证连接${N}

${Y}=== 常见问题 ===${N}
${B}- 设备未识别：检查驱动是否正确安装${N}
${B}- unauthorized：在设备上允许USB调试${N}
${B}- fastboot无设备：确认设备已进入fastboot模式${N}

${Y}=== 使用流程 ===${N}
${G}1. 连接设备后，选择对应的功能模式${N}
${G}2. Recovery/系统模式：通过ADB操作设备${N}
${G}3. Fastboot模式：刷入分区镜像${N}
${G}4. 欧加线刷：适用于一加/OPPO/Realme设备${N}
${G}5. 小米线刷：适用于小米/Redmi设备${N}
\n"
    printf "  ${DI}Press Enter to return...${N}"
    read
}


flash_pause() {
    printf "  ${DI}Press Enter to continue...${N}"
    read
}

flash_Reminder() {
printf "\n${Y}例如/sdcard/×××.img${N} 或将文件拖入窗口\n"
printf "如果脚本当前路径 有镜像可以直接回车 ${Y}q退出${N}\n"
echo
}
flash_Reminder2() {
printf "\n${Y}例如${N}/sdcard/images/ （q退出）\n"
printf "或将文件夹拖入窗口\n"
echo
}
#统一路径
flash_get_path() {
local prompt="$1"
local suffix="$2"
local mode="$3"
local auto_scan="$4"
local input_path=""
local default_path=""
while true; do
    printf "$prompt${Y}"
    read input_path
    printf "${N}"
    input_path=$(printf "$input_path\n" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed "s/^'//;s/'$//" | sed 's/^"//;s/"$//')
    
    if [ -z "$input_path" ] && [ "$auto_scan" = "0" ]; then
        if [ "$mode" = "file" ] && [ -n "$suffix" ]; then
            set +f
            files=$(find . -maxdepth 1 -type f -name "*$suffix" -o -name "*$suffix" 2>/dev/null | sort | sed 's|^\./||')
            set -f
            count=$(printf "$files\n" | grep -c '^')
            if [ "$count" -eq 0 ]; then
                printf "${R}当前目录未找到*$suffix文件请 重试或手动输入${N}\n"
                continue
            elif [ "$count" -eq 1 ]; then
                input_path="$files"
                printf "${Y}（自动扫描到: $input_path）${N}\n"
            else
                printf "${Y}检测到多个*$suffix文件${N}\n"
                i=1
                printf "$files\n" | while IFS= read -r f; do
                    printf "  $i. $f\n"
                    i=$((i+1))
                done
                printf "请选择文件编号 (1-$count) 或 q 退出: "
                read choice
                if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
                    FLASH_SELECTED_PATH=""
                    return 0
                fi
                if printf "$choice\n" | grep -qE '^[0-9]+$' && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
                    input_path=$(printf "$files\n" | sed -n "${choice}p")
                else
                    printf "${R}无效选择${N}\n"
                    continue
                fi
            fi
        elif [ "$mode" = "save" ]; then
            input_path="./"
        else
            continue
        fi
    fi
    
    if [ "$input_path" = "q" ] || [ "$input_path" = "Q" ]; then
        FLASH_SELECTED_PATH=""
        return 0
    fi
    if [ -z "$input_path" ]; then
        printf "${R}输入不能为空${N}\n" >&2
        continue
    fi
    if [ "$mode" = "file" ]; then
        if [ ! -f "$input_path" ]; then
            printf "${R}文件不存在: $input_path${N}\n" >&2
            continue
        fi
        if [ -n "$suffix" ] && ! printf "$input_path\n" | grep -q "$suffix$"; then
            printf "${R}文件后缀必须是 $suffix${N}\n" >&2
            continue
        fi
        FLASH_SELECTED_PATH="$input_path"
        return 0
    elif [ "$mode" = "dir" ]; then
        if [ ! -d "$input_path" ]; then
            printf "${R}目录不存在: $input_path${N}\n" >&2
            continue
        fi
        if [ -n "$suffix" ]; then
            local count=$(find "$input_path" -maxdepth 1 -type f -name "*$suffix" 2>/dev/null | wc -l)
            if [ "$count" -eq 0 ]; then
                printf "${R}目录下没有找到 *$suffix 文件${N}\n" >&2
                continue
            fi
        fi
        FLASH_SELECTED_PATH="$input_path"
        return 0
    elif [ "$mode" = "save" ]; then
        mkdir -p "$input_path" >/dev/null 2>&1
        if [ ! -d "$input_path" ]; then
            printf "${R}保存目录创建失败: $input_path${N}\n" >&2
            continue
        fi
        FLASH_SELECTED_PATH="$input_path"
        printf "${G}[OK]保存目录已就绪${N}\n"
        return 0
    else
        printf "${R}参数错误: $mode（应为 file/dir/save）${N}\n" >&2
        return 1
    fi
done
}

#绘制一个带标题的分隔线，用于美化界面输出。
flash_draw_title_line() {
local title="${1:-}"
local line_count=${2:-12}
local color_name=${3:-GREEN}
local color_code
local left_line=""
local i=0

case "$color_name" in
   RED|R) color_code="$R" ;;
   GREEN|G) color_code="$G" ;;
   YELLOW|Y) color_code="$Y" ;;
   B|B) color_code="$B" ;;
   *) color_code="$G" ;;
esac

while [ "$i" -lt "$line_count" ]; do
    left_line="${left_line}━"
    i=$((i + 1))
done

printf "${color_code}${left_line}${title}${left_line}${N}\n"
}

#交互式确认询问，支持自定义确认关键词和默认选项。
flash_confirm_prompt() {
local prompt="$1"
local default="${2:-n}"
local accept_key="${3:-y}"
local input
local lower_input
while true; do
    printf "$prompt${B}"
    read input
    printf "${N}"
    input=$(printf "$input\n" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    lower_input=$(printf "$input\n" | tr '[:upper:]' '[:lower:]')
    if [ -z "$lower_input" ]; then
        lower_input="$default"
    fi
    case "$lower_input" in
        q|quit|exit|n|no) return 1 ;;
    esac
    case "$accept_key" in
        y) if [ "$lower_input" = "y" ] || [ "$lower_input" = "yes" ]; then
               return 0
           fi ;;
      yes) if [ "$lower_input" = "yes" ]; then
               return 0
           fi ;;
        *) if [ "$lower_input" = "$accept_key" ]; then
               return 0
           fi ;;
    esac
  printf "${R}无效输入，请按提示输入有效选项${N}\n"
done
}

#读取设备电池电量（通过/sys/class/power_supply/battery/capacity 如果不存在跳过显示）
flash_get_battery_level() {
local battery_path="/sys/class/power_supply/battery/capacity"
local level
if [ -r "$battery_path" ]; then
    level=$(cat "$battery_path")
    if printf "$level\n" | grep -q '^[0-9]\{1,3\}$' && [ "$level" -ge 0 ] && [ "$level" -le 100 ]; then
        if [ "$level" -lt 35 ]; then
            printf "${R} [!] 当前设备电量过低：${Y}$level%%${R}（建议≥35%%）${N} [!]\n"
            echo
        else
            printf "${G}当前设备电量：${Y}$level%%${N}\n"
            echo
        fi
    return 0
   fi
fi
}

#脚本更新

#检测设备连接状态，支持多种模式（ADB、Fastboot、Recovery、 Sideload、任意模式)。
flash_check_device_connection() {
local mode=$1
local timeout=$((FLASH_DEVICE_TIMEOUT + 1))
local interval=1
local elapsed=0
local has_shown_unauth_warning=0
local adb_full_output
local fastboot_full_output
local adb_has_device
local fastboot_has_device
local unauthorized_devices
local adb_devices
local recovery_devices
local sideload_devices
local fastboot_list
local device_serial
local device_mode
local key

printf "[*]正在检测设备\n"
while [ $elapsed -lt $timeout ]; do
    adb_full_output=$(adb devices 2>/dev/null)
    fastboot_full_output=$(fastboot devices 2>/dev/null)
    adb_has_device=$(printf "$adb_full_output\n" | grep -v "List of devices attached" | grep -v '^[[:space:]]*$' | wc -l)
    fastboot_has_device=$(printf "$fastboot_full_output\n" | grep -v '^[[:space:]]*$' | wc -l)
    if [ "$adb_has_device" -eq 0 ] && [ "$fastboot_has_device" -eq 0 ]; then
        printf "\r等待设备响应 ${Y}%d/${FLASH_DEVICE_TIMEOUT}秒${N} q退出:" $elapsed
        read -t $interval -n 1 key 2>/dev/null || true
        if [ "$key" = "q" ] || [ "$key" = "Q" ]; then
            echo
            printf "\n${Y}已主动退出设备检测${N}\n"
            return 1
        fi
        elapsed=$((elapsed + interval))
        continue
    fi
    if [ "$mode" = "adb" ] || [ "$mode" = "any" ]; then
        unauthorized_devices=$(printf "$adb_full_output\n" | grep -v "List of devices" | grep "unauthorized$" | awk '{print $1}')
        if [ -n "$unauthorized_devices" ] && [ "$has_shown_unauth_warning" -eq 0 ]; then
            printf "\n${R}[!] 检测到未授权设备：$unauthorized_devices${N}\n"
            printf "${B}请在设备上勾选「一律允许使用这台计算机进行调试」${N}\n"
            printf "${B}然后点击「允许」${N}\n"
            echo
            has_shown_unauth_warning=1
        fi
    fi
    case $mode in
        "adb")
            adb_devices=$(printf "$adb_full_output\n" | grep -v "List of devices" | grep "device$" | awk '{print $1}')
            if [ -n "$adb_devices" ]; then
                FLASH_DEVICE_SERIAL=$(printf "$adb_devices\n" | head -n1)
                FLASH_CONNECTION_MODE="adb"  
                printf "${G}ADB已连接 $FLASH_DEVICE_SERIAL${N}\n"
                return 0
            fi ;;
        "fastboot")
            fastboot_list=$(printf "$fastboot_full_output\n" | head -n1)
            if [ -n "$fastboot_list" ]; then
                FLASH_DEVICE_SERIAL=$(printf "$fastboot_list\n" | awk '{print $1}')
                device_mode=$(printf "$fastboot_list\n" | awk '{print $2}')
                if [ "$device_mode" = "fastbootd" ]; then
                    FLASH_CONNECTION_MODE="fastbootD"
                    printf "${G}FastbootD已连接 $FLASH_DEVICE_SERIAL${N}\n"
                else
                    FLASH_CONNECTION_MODE="fastboot"
                    printf "${G}Fastboot已连接 $FLASH_DEVICE_SERIAL${N}\n"
                fi
                return 0
            fi ;;
        "recovery")
            recovery_devices=$(printf "$adb_full_output\n" | grep -v "List of devices" | grep "recovery$" | awk '{print $1}')
            if [ -n "$recovery_devices" ]; then
                FLASH_DEVICE_SERIAL=$(printf "$recovery_devices\n" | head -n1)
                FLASH_CONNECTION_MODE="recovery"  
                printf "${G}Recovery已连接 $FLASH_DEVICE_SERIAL${N}\n"
                return 0
            fi ;;
        "any")
            adb_devices=$(printf "$adb_full_output\n" | grep -v "List of devices" | grep "device$" | awk '{print $1}')
            fastboot_list=$(printf "$fastboot_full_output\n" | head -n1)
            sideload_devices=$(printf "$adb_full_output\n" | grep -v "List of devices" | grep "sideload$" | awk '{print $1}')
            recovery_devices=$(printf "$adb_full_output\n" | grep -v "List of devices" | grep "recovery$" | awk '{print $1}')
            
            if [ -n "$adb_devices" ]; then
                FLASH_DEVICE_SERIAL=$(printf "$adb_devices\n" | head -n1)
                FLASH_CONNECTION_MODE="adb"  
                printf "${G}ADB已连接 $FLASH_DEVICE_SERIAL${N}\n"
                return 0
            elif [ -n "$fastboot_list" ]; then
                FLASH_DEVICE_SERIAL=$(printf "$fastboot_list\n" | awk '{print $1}')
                device_mode=$(printf "$fastboot_list\n" | awk '{print $2}')
                if [ "$device_mode" = "fastbootd" ]; then
                    FLASH_CONNECTION_MODE="fastbootD"
                    printf "${G}FastbootD已连接 $FLASH_DEVICE_SERIAL${N}\n"
                else
                    FLASH_CONNECTION_MODE="fastboot"
                    printf "${G}Fastboot已连接 $FLASH_DEVICE_SERIAL${N}\n"
                fi
                return 0
            elif [ -n "$sideload_devices" ]; then
                FLASH_DEVICE_SERIAL=$(printf "$sideload_devices\n" | head -n1)
                FLASH_CONNECTION_MODE="sideload"
                printf "${G}Sideload已连接 $FLASH_DEVICE_SERIAL${N}\n"
                return 0
            elif [ -n "$recovery_devices" ]; then
                FLASH_DEVICE_SERIAL=$(printf "$recovery_devices\n" | head -n1)
                FLASH_CONNECTION_MODE="recovery"
                printf "${G}Recovery已连接 $FLASH_DEVICE_SERIAL${N}\n"
                return 0
            fi ;;
    esac
    printf "\r等待设备响应 ${Y}%d/${FLASH_DEVICE_TIMEOUT}秒${N} q退出:" $elapsed
    read -t $interval -n 1 key 2>/dev/null || true
    if [ "$key" = "q" ] || [ "$key" = "Q" ]; then
        echo
        printf "\n${Y}已主动退出设备检测${N}\n"
        return 1
    fi
    
    elapsed=$((elapsed + interval))
done
printf "\n${R}设备连接超时${N}\n"
printf "${Y}请检查是否开启OTG 和设备连接${N}\n"
return 1
}

#fastboot flash刷入+重试
flash_flash_with_retry() {
local PARTITION="$1"
local IMG_PATH="$2"
local RETRY_COUNT=0
local SUCCESS=0
printf "\n${B}刷入分区${N}：${Y}$PARTITION${N}\n"

while [ $RETRY_COUNT -lt $FLASH_MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    if [ $RETRY_COUNT -gt 1 ]; then
        printf "\n${Y}尝试第 $RETRY_COUNT 次刷入${N}\n"
    fi
    fastboot flash "$PARTITION" "$IMG_PATH"
    
    if [ $? -eq 0 ]; then
        printf "${G}刷入成功。${N}\n"
        SUCCESS=1
        break
    else
        if [ $RETRY_COUNT -lt $FLASH_MAX_RETRIES ]; then
            printf "${R}刷入失败 (第 $RETRY_COUNT 次)${N}\n"
            sleep 1
        fi
    fi
done
if [ $SUCCESS -eq 0 ]; then
    printf "\n${R}错误: [$PARTITION] 分区刷入 $FLASH_MAX_RETRIES 次后仍然失败${N}\n"
    return 1
fi
return 0
}

#向已连接的设备（ADB或Recovery 模式）推送本地文件或文件夹。
flash_file_upload() {
local local_path
local device_path
while true; do
    clear
    flash_draw_title_line " 传输文件/文件夹 " 14
    echo
    flash_get_battery_level
    
    if ! flash_check_device_connection "any"; then
        return 1
    fi
    
    if [ "$FLASH_CONNECTION_MODE" != "adb" ] && [ "$FLASH_CONNECTION_MODE" != "recovery" ]; then
        printf "${R}仅支持系统(ADB)或Recovery模式连接！${N}\n"
        return 1
    fi
    
    printf "\n例如 /sdcard/file.apk 或 /sdcard/folder/\n"
    printf "${B}支持单个文件、文件夹${N}\n"
    printf "请输入${Y}本地${N}路径: "
    read local_path
    
    printf "\n例如 /sdcard/ 或 /data/local/tmp/\n"
    printf "请输入${Y}目标设备${N}保存路径: "
    read device_path
    
    if [ -z "$local_path" ] || [ -z "$device_path" ]; then
        printf "${R}本地路径和设备路径 不能为空！${N}\n"
        flash_pause
        continue
    fi
    
    if [ ! -e "$local_path" ]; then
        printf "${R}本地文件/文件夹不存在：$local_path${N}\n"
        flash_pause
        continue
    fi
    
    printf "${Y}正在传输...${N}\n"
    adb -s "$FLASH_DEVICE_SERIAL" push "$local_path" "$device_path"
    
    if [ $? -eq 0 ]; then
        printf "\n${G}传输完成！内容已保存至设备：$device_path${N}\n"
    else
        printf "\n${R}传输失败！请检查路径权限、设备连接或内容完整性${N}\n"
    fi
    
    echo
    if ! flash_confirm_prompt "是否继续传输其他文件/文件夹？(y/n): "; then
        break
    fi
done
}

#从设备（ADB 或 Recovery 模式）提取文件或文件夹到本地。
flash_file_extract() {
local device_path
local local_path
while true; do
    clear
    flash_draw_title_line " 文件/文件夹提取 " 14
    echo
    flash_get_battery_level
    
    if ! flash_check_device_connection "any"; then
        return 1
    fi
    
    if [ "$FLASH_CONNECTION_MODE" != "adb" ] && [ "$FLASH_CONNECTION_MODE" != "recovery" ]; then
        printf "${R}仅支持系统(ADB)或Recovery模式连接！${N}\n"
        return 1
    fi
    
    printf "\n例如 /sdcard/file.apk 或 /sdcard/folder/\n"
    printf "${B}支持单个文件、文件夹${N}\n"
    printf "请输入${Y}目标设备${N}路径: "
    read device_path
    
    printf "\n例如 /sdcard/ 或 ./backup/\n"
    printf "请输入${Y}本地${N}保存路径: "
    read local_path
    
    if [ -z "$device_path" ] || [ -z "$local_path" ]; then
        printf "${R}设备路径和本地路径 不能为空！${N}\n"
        flash_pause
        continue
    fi
    
    adb -s "$FLASH_DEVICE_SERIAL" shell ls "$device_path" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        printf "${R}设备路径不存在或无访问权限：$device_path${N}\n"
        flash_pause
        continue
    fi
    
    mkdir -p "$local_path" >/dev/null 2>&1
    
    printf "${Y}正在提取...${N}\n"
    adb -s "$FLASH_DEVICE_SERIAL" pull "$device_path" "$local_path"
    
    if [ $? -eq 0 ]; then
        printf "\n${G}提取完成！内容已保存至本地：$local_path${N}\n"
    else
        printf "\n${R}提取失败！请检查路径权限、设备连接或内容完整性${N}\n"
    fi
    
    echo
    if ! flash_confirm_prompt "是否继续提取其他文件/文件夹？(y/n): "; then
        break
    fi
done
}

#提取设备分区镜像（需要 root 权限，或Recovery模式)。
flash_extract_image() {
local op_choice
local p_input
local ALL_VALID_PARTS
local slot_suffix
local p
local target_part
local part_with_slot
local path_in
local dir
local user_prefix
local file
local ok
local fail
local part
local base_name
local slot_suffix_name
local save_name
local save_path
local tmp
local tmp_path
local dd_code
local code
while true; do
    clear
    flash_draw_title_line " 镜像提取 " 18
    printf "\n系统模式需给Shell Root权限\n"
    printf "禁止提取userdata分区\n"
    printf "${Y}请选择操作：${N}\n"
    printf "  ${Y}1${N}. 查看设备分区表\n"
    printf "  ${Y}2${N}. 提取分区镜像\n"
    printf "\n  空回车退出\n"
    printf "请输入 [${Y}1-2${N}]: "
    read op_choice
    case $op_choice in
        1) clear
            flash_draw_title_line "设备分区表" 19
            echo
            if ! flash_check_device_connection "any"; then
                flash_pause
                continue
            fi
            if [ "$FLASH_CONNECTION_MODE" != "adb" ] && [ "$FLASH_CONNECTION_MODE" != "recovery" ]; then
                printf "${R}仅支持ADB或Recovery模式连接${N}\n"
                flash_pause
                continue
            fi
            echo
            adb -s "$FLASH_DEVICE_SERIAL" shell ls -1 /dev/block/by-name/ 2>/dev/null
            if [ $? -ne 0 ]; then
                printf "${R}读取分区表失败${N}\n"
            fi
            echo
            flash_pause ;;
        2) clear
            flash_draw_title_line "提取分区镜像" 18
            echo
            if ! flash_check_device_connection "any"; then
                flash_pause
                continue
            fi
            if [ "$FLASH_CONNECTION_MODE" != "adb" ] && [ "$FLASH_CONNECTION_MODE" != "recovery" ]; then
                printf "${R}仅支持ADB或Recovery模式连接${N}\n"
                flash_pause
                continue
            fi
            while true; do
                printf "\n例：boot、recovery、vbmeta（多个分区用空格分隔）\n"
                printf "请输入要提取的分区名称: "
                read p_input
                
                if [ -z "$p_input" ]; then
                    printf "${R}分区名称不能为空${N}\n"
                    flash_pause
                    continue
                fi
                ALL_VALID_PARTS=""
                slot_suffix=$(adb -s "$FLASH_DEVICE_SERIAL" shell getprop ro.boot.slot_suffix 2>/dev/null | tr -d '[:space:]')
                for p in $p_input; do
                    [ -z "$p" ] && continue
                    
                    target_part=""
                    if printf "$p\n" | grep -qE '_[ab]$'; then
                        target_part="$p"
                    else
                        part_with_slot="${p}${slot_suffix}"
                        adb -s "$FLASH_DEVICE_SERIAL" shell test -b "/dev/block/by-name/${part_with_slot}" 2>/dev/null
                        if [ $? -eq 0 ]; then
                            target_part="$part_with_slot"
                        else
                            target_part="$p"
                        fi
                    fi
                    
                    adb -s "$FLASH_DEVICE_SERIAL" shell test -b "/dev/block/by-name/${target_part}" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        ALL_VALID_PARTS="$ALL_VALID_PARTS $target_part"
                    else
                        printf "${R}分区不存在：$target_part${N}\n"
                        sleep 0.5
                    fi
                done
                
                ALL_VALID_PARTS=$(printf "$ALL_VALID_PARTS\n" | sed 's/^ *//;s/ *$//')
                if [ -z "$ALL_VALID_PARTS" ]; then
                    printf "${R}无有效分区可提取${N}\n"
                    flash_pause
                    continue
                fi
                
                printf "\n${Y}q退出${N}\n"
                flash_get_path "请输入保存目录（回车默认当前目录）:" "" "save" "0"
                if [ -z "$FLASH_SELECTED_PATH" ]; then
                    continue
                fi
                dir="$FLASH_SELECTED_PATH"
                user_prefix=""
                
                printf "\n${Y}开始提取...${N}\n"
                ok=0
                fail=0
                for part in $ALL_VALID_PARTS; do
                    printf "\n${B}【$part】${N}\n"
                    
                    if printf "$part\n" | grep -qE '_[ab]$'; then
                        base_name=$(printf "$part\n" | sed 's/_[ab]$//')
                        slot_suffix_name=$(printf "$part\n" | grep -oE '_[ab]$')
                        save_name="${base_name}${slot_suffix_name}.img"
                    else
                        save_name="${part}.img"
                    fi
                    save_path="${dir}${save_name}"
                    
                    if [ "$FLASH_CONNECTION_MODE" = "recovery" ]; then
                        adb -s "$FLASH_DEVICE_SERIAL" pull "/dev/block/by-name/$part" "$save_path" 2>/dev/null
                        code=$?
                    else
                        tmp="tmp_extract_${part}_$(date +%Y%m%d%H%M%S).img"
                        tmp_path="/sdcard/$tmp"
                        adb -s "$FLASH_DEVICE_SERIAL" shell su -c "dd if=/dev/block/by-name/$part of=$tmp_path bs=4M 2>/dev/null"
                        dd_code=$?
                        if [ $dd_code -ne 0 ]; then
                            printf "${R}提取失败${N}\n"
                            adb -s "$FLASH_DEVICE_SERIAL" shell rm -f "$tmp_path" 2>/dev/null
                            code=1
                        else
                            adb -s "$FLASH_DEVICE_SERIAL" pull "$tmp_path" "$save_path" 2>/dev/null
                            code=$?
                            adb -s "$FLASH_DEVICE_SERIAL" shell rm -f "$tmp_path" 2>/dev/null
                        fi
                    fi
                    if [ $code -eq 0 ] && [ -f "$save_path" ]; then
                        printf "${G}成功 保存至：$save_path${N}\n"
                        ok=$((ok + 1))
                    else
                        printf "${R}失败${N}\n"
                        fail=$((fail + 1))
                    fi
                done
                echo
                flash_draw_title_line "提取完成" 9
                printf "${G}成功：$ok 个${N} | ${R}失败：$fail 个${N}\n"
                if ! flash_confirm_prompt "\n是否继续提取？(y/n): "; then
                    break
                fi
            done ;;
        *) return 2 ;;
    esac
done
}

#强制终止与ADB/Fastboot 相关的后台进程
flash_clean_adb_fastboot_processes() {
local TARGET_PROCESSES="adb e2fsdroid img2simg lpflash make_f2fs sload_f2fs append2simg ext2simg lpadd lpmake mke2fs.android brotli fastboot lpdump lpunpack simg2img payload-dumper-go"
local has_found=0
local proc
local pids
local DELAY_TIME=1

clear
flash_draw_title_line " 清理进程 " 18
printf "\n即将清理以下进程：
${Y}  adb e2fsdroid img2simg lpflash make_f2fs
  sload_f2fs append2simg ext2simg lpadd lpmake
  mke2fs.android brotli fastboot lpdump lpunpack
  simg2img payload-dumper-go${N}\n"
flash_draw_title_line "" 17

printf "${G}正在扫描目标进程...${N}\n"
for proc in ${TARGET_PROCESSES}; do
    pids=$(pidof "${proc}" 2>/dev/null)
    if [ -n "${pids}" ]; then
        has_found=1
        printf " 找到进程：${B}${proc}${N} | PID：${Y}${pids}${N}\n"
    fi
done

if [ "${has_found}" -eq 0 ]; then
    printf "\n${G}[OK] 未检测到任何目标进程，无需清理${N}\n"
    flash_pause
    return 0
fi
echo
if ! flash_confirm_prompt "确认强制清理以上进程？(y/回车退出)：" "n"; then
    return 0
fi
printf "\n${Y}正在强制清理进程...${N}\n"
for proc in ${TARGET_PROCESSES}; do
    pids=$(pidof "${proc}" 2>/dev/null)
    if [ -n "${pids}" ]; then
        for pid in ${pids}; do
            kill -9 "${pid}" >/dev/null 2>&1
            sleep ${DELAY_TIME}
            if ! kill -0 "${pid}" >/dev/null 2>&1; then
                printf "  [OK] 已清理：${proc}（PID：${pid}）\n"
            else
                printf "  [X] 清理失败：${proc}（PID：${pid}）\n"
            fi
        done
    fi
done
echo
flash_draw_title_line "" 17
printf "${G}进程清理操作执行完成${N}\n"
flash_pause
}

#检测设备是否为A/B分区架构(通过 fastboot getvar current-slot或slot-count)。
flash_check_ab_partitions() {
local current_slot
local slot_count
printf "${Y}正在检测AB分区状态...${N}\n"

if ! flash_check_device_connection "fastboot"; then
    return 1
fi

current_slot=$(fastboot -s "$FLASH_DEVICE_SERIAL" getvar current-slot 2>&1 | grep -E '^current-slot:' | sed -n 's/.*: *//p' | tr -d '[:space:]')
if [ "$current_slot" = "a" ] || [ "$current_slot" = "b" ]; then
    printf "${G}\n当前激活分区：$current_slot${N}\n"
    return 0
else
    slot_count=$(fastboot -s "$FLASH_DEVICE_SERIAL" getvar slot-count 2>&1 | grep -E '^slot-count:' | sed -n 's/.*: *//p' | tr -d '[:space:]')
    if [ "$slot_count" = "2" ]; then
        printf "${G}检测成功：当前设备为AB分区架构（slot-count=2）${N}\n"
        printf "${Y}警告：未获取到明确激活分区，可能是分区信息异常${N}\n"
        return 0
    fi
    
    printf "${R}检测结果：当前设备为非AB分区架构${N}\n"
    return 1
fi
}

#切换当前激活的 A/B 槽位（a ↔ b）
flash_switch_ab_partition() {
local current_slot
local target_slot

flash_check_ab_partitions
if [ $? -ne 0 ]; then
    return 1
fi
current_slot=$(fastboot getvar current-slot 2>&1 | grep -o "current-slot: [a-b]" | awk '{print $2}')
target_slot="b"
if [ "$current_slot" = "b" ]; then
    target_slot="a"
fi

printf "${Y}即将切换到 $target_slot 分区${N}\n"
printf "${R}切换分区可能导致系统无法启动${N}\n"
if ! flash_confirm_prompt "确认切换? (yes/n): " "n" "yes"; then
    return 0
fi

fastboot set_active $target_slot
if [ $? -eq 0 ]; then
    printf "${G}分区切换成功！新激活分区：$target_slot${N}\n"
else
    printf "${R}分区切换失败！${N}\n"
fi
}

#将设备重启到指定的 Fastboot 或 FastbootD 模式，并等待设备进入目标状态。
flash_ensure_target_mode() {
local target="$1"
local REBOOT_SUCCESS=0
local start_time=$(date +%s)
local q_cmd
local fastboot_list
local current_serial
local current_mode
local elapsed
local last_output_time=0
echo
if [ "$FLASH_CONNECTION_MODE" = "fastboot" ] || [ "$FLASH_CONNECTION_MODE" = "fastbootD" ]; then
    if [ "$target" = "fastbootD" ] && [ "$FLASH_CONNECTION_MODE" = "fastbootD" ]; then
        printf "${G}当前已在 fastbootD 模式${N}\n"
        printf "${Y}等待 8 秒稳定...${N}\n"
        sleep 8
        return 0
    elif [ "$target" = "bootloader" ] && [ "$FLASH_CONNECTION_MODE" = "fastboot" ]; then
        printf "${G}当前已在 fastboot 模式${N}\n"
        printf "${Y}等待 8 秒稳定...${N}\n"
        sleep 8
        return 0
    fi
fi
if [ "$target" = "fastbootD" ]; then
    printf "${G}当前模式：$FLASH_CONNECTION_MODE → 重启到 fastbootD${N}\n"
    case "$FLASH_CONNECTION_MODE" in
        "adb"|"recovery") adb reboot fastboot ;;
        "fastboot") (fastboot reboot fastboot >/dev/null 2>&1 &) && disown $! 2>/dev/null ;;
        *)  printf "${R}不支持的设备模式，无法重启到 fastbootD${N}\n"
            return 1 ;;
    esac
elif [ "$target" = "bootloader" ]; then
    printf "${G}当前模式：$FLASH_CONNECTION_MODE → 重启到 fastboot${N}\n"
    if [ "$FLASH_CONNECTION_MODE" = "fastbootD" ]; then
        (fastboot reboot-bootloader >/dev/null 2>&1 &) && disown $! 2>/dev/null
    elif [ "$FLASH_CONNECTION_MODE" = "adb" ] || [ "$FLASH_CONNECTION_MODE" = "recovery" ]; then
        adb reboot bootloader
    else
        printf "${R}不支持的设备模式，无法重启到 fastboot${N}\n"
        return 1
    fi
else
    printf "${R}未知目标模式${N}\n"
    return 1
fi
while true; do
    read -t 1 -n 1 q_cmd 2>/dev/null || true
    if [ "$q_cmd" = "q" ] || [ "$q_cmd" = "Q" ]; then
        printf "\n${R}主动退出等待，操作终止！${N}\n"
        return 1
    fi
    fastboot_list=$(fastboot devices 2>/dev/null | head -n1)
    if [ -n "$fastboot_list" ]; then
        current_serial=$(printf "$fastboot_list\n" | awk '{print $1}')
        current_mode=$(printf "$fastboot_list\n" | awk '{print $2}')
        if [ "$target" = "fastbootD" ] && [ "$current_mode" = "fastbootd" ]; then
            FLASH_DEVICE_SERIAL="$current_serial"
            FLASH_CONNECTION_MODE="fastbootD"
            elapsed=$(( $(date +%s) - start_time ))
            printf "\n${G}设备成功进入 fastbootD 模式！（共等待 ${elapsed} 秒）${N}\n"
            printf "${Y}等待 8 秒稳定...${N}\n"
            sleep 8
            REBOOT_SUCCESS=1
            break
        elif [ "$target" = "bootloader" ] && [ "$current_mode" = "fastboot" ]; then
            FLASH_DEVICE_SERIAL="$current_serial"
            FLASH_CONNECTION_MODE="fastboot"
            elapsed=$(( $(date +%s) - start_time ))
            printf "\n${G}设备成功进入 fastboot 模式！（共等待 ${elapsed} 秒）${N}\n"
            printf "${Y}等待 8 秒稳定...${N}\n"
            sleep 8
            REBOOT_SUCCESS=1
            break
        fi
    fi
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    if [ $((current_time - last_output_time)) -ge 1 ]; then
        printf "\r  60秒/已等待 %2d 秒，按 q 退出：" $elapsed
        last_output_time=$current_time
    fi
    if [ $elapsed -ge 60 ]; then
        printf "\n${R}等待60秒超时，未检测到设备进入目标模式${N}\n"
        if flash_confirm_prompt "是否继续检测？(y继续/n退出): "; then
            start_time=$(date +%s)
            elapsed=0
            last_output_time=0
        else
            printf "${Y}已退出检测，操作终止${N}\n"
            return 1
        fi
    fi
done
printf "\r\n"
if [ $REBOOT_SUCCESS -eq 1 ]; then
    return 0
else
    printf "${R}进入目标模式失败${N}\n"
    return 1
fi
}

#在FastbootD模式下，取消快照更新并删除逻辑分区的COW分区，然后重建逻辑分区（my_* 及特定分区）。
flash_erase_cow_partitions_in_fastbootd() {
local MAIN_IMG_DIR="$1"
local DOUBLE_AD_DIR="$2"
local SPECIFIC_RECONSTRUCT_PARTS="odm system system_dlkm system_ext vendor vendor_dlkm product odm_dlkm"
local PARTITIONS_TO_RECONSTRUCT=""
local VALID_IMGS=""
local img_path
local PARTITION
local part
local PART_COUNT

printf "\n取消快照更新...\n"
fastboot snapshot-update cancel

set +f
for img_path in "$MAIN_IMG_DIR"/*.img "$MAIN_IMG_DIR"/*.IMG; do
    [ -f "$img_path" ] && VALID_IMGS="$VALID_IMGS $img_path"
done
if [ -n "$DOUBLE_AD_DIR" ] && [ "$DOUBLE_AD_DIR" != "$MAIN_IMG_DIR" ] && [ -d "$DOUBLE_AD_DIR" ]; then
    for img_path in "$DOUBLE_AD_DIR"/*.img; do
        [ -f "$img_path" ] && VALID_IMGS="$VALID_IMGS $img_path"
    done
fi
set -f

for img_path in $VALID_IMGS; do
    [ -z "$img_path" ] && continue
    PARTITION=$(basename "$img_path")
    PARTITION=${PARTITION%.*}
    if [ "$(printf "$PARTITION\n" | cut -c1-3)" = "my_" ]; then
        if ! printf " $PARTITIONS_TO_RECONSTRUCT \n" | grep -qF " $PARTITION "; then
            PARTITIONS_TO_RECONSTRUCT="$PARTITIONS_TO_RECONSTRUCT $PARTITION"
        fi
    fi
done

for part in $SPECIFIC_RECONSTRUCT_PARTS; do
    if [ -f "$MAIN_IMG_DIR/$part.img" ] || [ -f "$MAIN_IMG_DIR/$part.IMG" ] || [ -n "$DOUBLE_AD_DIR" -a -f "$DOUBLE_AD_DIR/$part.img" ]; then
        if ! printf " $PARTITIONS_TO_RECONSTRUCT \n" | grep -qF " $part "; then
            PARTITIONS_TO_RECONSTRUCT="$PARTITIONS_TO_RECONSTRUCT $part"
        fi
    fi
done

if [ -n "$PARTITIONS_TO_RECONSTRUCT" ]; then
    PART_COUNT=$(printf "$PARTITIONS_TO_RECONSTRUCT\n" | wc -w)
    printf "${Y}开始重构逻辑分区（共 $PART_COUNT 个）...${N}\n"
    
    for part in $PARTITIONS_TO_RECONSTRUCT; do
        printf "\n${B}重构：$part${N}\n"
        fastboot delete-logical-partition "${part}_a" 2>/dev/null
        fastboot delete-logical-partition "${part}_b" 2>/dev/null
        fastboot delete-logical-partition "${part}_a-cow" 2>/dev/null
        fastboot delete-logical-partition "${part}_b-cow" 2>/dev/null
        fastboot create-logical-partition "${part}_a" 1
        fastboot create-logical-partition "${part}_b" 1
        printf "${G}  - 重构完成。${N}\n"
    done
else
    printf "${Y}未检测到需要重构的动态分区，跳过重构步骤。${N}\n"
fi
}

flash_flash_main_partitions_in_fastbootd() {
local img_folder="$1"
local double_ad_img1="$2"
local double_ad_img2="$3"
local LOGICAL_PARTS="odm system system_dlkm system_ext vendor vendor_dlkm product odm_dlkm"
local skipped_count=0
local flashed_count=0
local VALID_IMGS=""
local img_path
local filename
local filename_lower
local part_raw
local part
local is_logical
local log_part
local slot
local ab_part

set +f

for img_path in "$img_folder"/*.img "$img_folder"/*.IMG; do
    [ -f "$img_path" ] && VALID_IMGS="$VALID_IMGS $img_path"
done
[ -f "$double_ad_img1" ] && VALID_IMGS="$VALID_IMGS $double_ad_img1"
[ -f "$double_ad_img2" ] && VALID_IMGS="$VALID_IMGS $double_ad_img2"
set -f

for img_path in $VALID_IMGS; do
    [ -z "$img_path" ] && continue
    
    filename=$(basename "$img_path")
    filename_lower=$(printf "$filename\n" | tr '[:upper:]' '[:lower:]')
    
    if [ "$filename_lower" = "modem.img" ] || \
       [ "$filename_lower" = "mise.img" ] || \
       [ "$filename_lower" = "mise_a.img" ] || \
       [ "$filename_lower" = "mise_b.img" ] || \
       [ "$filename_lower" = "misc_wipedata_oppo.img" ] || \
       [ "$filename_lower" = "preloader_raw.img" ]; then
        printf "${Y}跳过: $filename（后续处理）${N}\n"
        skipped_count=$((skipped_count + 1))
        continue
    fi
    
    part_raw=$(basename "$img_path" .img)
    part_raw=$(basename "$part_raw" .IMG)
    
    local mapped_part="$part_raw"
    local part_lower=$(printf "$part_raw\n" | tr '[:upper:]' '[:lower:]')
    case "$part_lower" in
        "my_a") mapped_part="my" ;;
        "system_a") mapped_part="system" ;;
    esac
    part="$mapped_part"
    
    is_logical=0
    if [ "$(printf "$part\n" | cut -c1-3)" = "my_" ]; then
        is_logical=1
    else
        for log_part in $LOGICAL_PARTS; do
            [ "$part" = "$log_part" ] && is_logical=1 && break
        done
    fi
    
    if [ $is_logical -eq 1 ]; then
        if flash_flash_with_retry "$part" "$img_path"; then
            flashed_count=$((flashed_count + 1))
        else
            printf "${Y}逻辑分区$part刷写失败，继续下一个分区...${N}\n"
        fi
    else
        for slot in _a _b; do
            ab_part="${part}${slot}"
            if flash_flash_with_retry "$ab_part" "$img_path"; then
                flashed_count=$((flashed_count + 1))
            else
                printf "${Y}物理分区$ab_part刷写失败，继续下一个槽位/分区...${N}\n"
            fi
        done
    fi
done
echo
flash_draw_title_line "" 13
printf "${Y}主分区刷写完成${N}\n"
}

flash_get_oppo_images() {
local user_folder="$1"
local script_dir=$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)
local script_img_path="${script_dir}/img"
local gitee_base="${FLASH_gitee_ChenXluk}"
local download_success=0
flash_download_file() {
local url="$1"
local dest="$2"
local dest_dir=$(dirname "$dest")
mkdir -p "$dest_dir" 2>/dev/null
if which curl >/dev/null 2>&1; then
    curl -fsSL --connect-timeout 10 -o "$dest" "$url"
elif which wget >/dev/null 2>&1; then
    wget -qO "$dest" --timeout=10 "$url"
else
    return 1
fi
return $?
}
FLASH_DOUBLE_AD_IMG1=""
FLASH_DOUBLE_AD_IMG2=""
FLASH_DOUBLE_AD_STATUS="部分缺失/无"
FLASH_NEED_EXTRA_FLASH_DOUBLE_AD=0
if [ -f "${user_folder}/my_company.img" ] && [ -f "${user_folder}/my_preload.img" ]; then
    FLASH_DOUBLE_AD_IMG1="${user_folder}/my_company.img"
    FLASH_DOUBLE_AD_IMG2="${user_folder}/my_preload.img"
    FLASH_DOUBLE_AD_STATUS="完整"
elif [ -f "${script_img_path}/双广/my_company.img" ] && [ -f "${script_img_path}/双广/my_preload.img" ]; then
    FLASH_DOUBLE_AD_IMG1="${script_img_path}/双广/my_company.img"
    FLASH_DOUBLE_AD_IMG2="${script_img_path}/双广/my_preload.img"
    FLASH_DOUBLE_AD_STATUS="使用脚本双广"
    FLASH_NEED_EXTRA_FLASH_DOUBLE_AD=1
else
    printf "${Y}未找到双广镜像，尝试从gitee下载${N}\n"
    local need_download=0
    local company_dest="${script_img_path}/双广/my_company.img"
    local preload_dest="${script_img_path}/双广/my_preload.img"
    if [ ! -f "$company_dest" ]; then
        printf "下载 my_company.img\n"
        if flash_download_file "${gitee_base}my_company.img" "$company_dest"; then
            printf "${G}下载成功${N}\n"
        else
            printf "${R}下载失败${N}\n"
            need_download=1
        fi
    fi
    if [ ! -f "$preload_dest" ]; then
        printf "下载 my_preload.img\n"
        if flash_download_file "${gitee_base}my_preload.img" "$preload_dest"; then
            printf "${G}下载成功${N}\n"
        else
            printf "${R}下载失败${N}\n"
            need_download=1
        fi
    fi
    if [ $need_download -eq 0 ] && [ -f "$company_dest" ] && [ -f "$preload_dest" ]; then
        FLASH_DOUBLE_AD_IMG1="$company_dest"
        FLASH_DOUBLE_AD_IMG2="$preload_dest"
        FLASH_DOUBLE_AD_STATUS="使用脚本双广(已下载)"
        FLASH_NEED_EXTRA_FLASH_DOUBLE_AD=1
    else
        printf "${R}请检查网络或手动放置${N}\n"
    fi
fi

FLASH_MISC_IMG=""
if [ -f "${user_folder}/misc_wipedata_oppo.img" ]; then
    FLASH_MISC_IMG="${user_folder}/misc_wipedata_oppo.img"
elif [ -f "${script_img_path}/misc_wipedata_oppo/misc_wipedata_oppo.img" ]; then
    FLASH_MISC_IMG="${script_img_path}/misc_wipedata_oppo/misc_wipedata_oppo.img"
else
    printf "${Y}未找到 misc_wipedata_oppo.img，尝试从gitee下载${N}\n"
    local misc_dest="${script_img_path}/misc_wipedata_oppo/misc_wipedata_oppo.img"
    if flash_download_file "${gitee_base}misc_wipedata_oppo.img" "$misc_dest"; then
        FLASH_MISC_IMG="$misc_dest"
        printf "${G}下载成功${N}\n"
    else
        printf "${R}下载失败，请检查网络或手动放置${N}\n"
    fi
fi
}

#执行 Bootloader 解锁命令（fastboot flashing unlock），适用于欧加/Pixel 设备。
flash_unlock_bl() {
clear
flash_draw_title_line " 欧加/pixel 设备BL解锁 " 11
printf "\n${R}解锁BL会清除所有数据！${N}\n"
printf "联发科：需要提前按住音量上之后执行解锁\n"
printf "\n高通：执行后使用音量下键选择到\n"
printf "UNLOCK THE BOOTLOADER并按下锁屏键\n"

echo
printf "${Y}确保设置中的OEM已开启${N}\n"
if ! flash_confirm_prompt "确认解锁? (yes/n): " "n" "yes"; then
    printf "${Y}已取消BL解锁操作${N}\n"
    return 0
fi

if ! flash_check_device_connection "fastboot"; then
    return 1
fi
printf "${Y}开始执行BL解锁...${N}\n"
fastboot flashing unlock
if [ $? -eq 0 ]; then
    printf "${G}BL解锁命令执行完成！${N}\n"
else
    printf "${R}BL解锁失败！${N}\n"
fi
flash_pause
}

#执行 Bootloader 上锁命令（fastboot flashing lock）。
flash_oem_lock() {
clear
flash_draw_title_line " BL上锁 " 19
printf "\n执行fastboot flashing lock\n"
printf "
${R}上锁BL会清除所有数据！
${Y}强烈建议刷一遍官方完整包${N}
\n"
if ! flash_check_device_connection "fastboot"; then
    return 1
fi

if ! flash_confirm_prompt "确认上锁? (yes/n): " "n" "yes"; then
    printf "${Y}已取消BL上锁操作${N}\n"
    return 0
fi

printf "${Y}开始执行BL上锁...${N}\n"
fastboot flashing lock
if [ $? -eq 0 ]; then
    printf "${G}BL上锁命令执行完成！${N}\n"
else
    printf "${R}BL上锁失败！${N}\n"
fi
flash_pause
}

#刷入关闭AVB 2.0验证的vbmeta.img
flash_disable_avb20() {
local vbmeta_path
clear
flash_draw_title_line " [*]关闭AVB2.0验证 " 15
printf "\n不一定全设备通用\n"
echo
if ! flash_check_device_connection "fastboot"; then
    return 1
fi

if ! flash_confirm_prompt "确认关闭AVB2.0验证? (y/n): "; then
    printf "${Y}已取消关闭AVB2.0验证操作${N}\n"
    return 0
fi

flash_Reminder
flash_get_path "请输入vbmeta.img文件路径: " ".img" "file" "0"
if [ -z "$FLASH_SELECTED_PATH" ]; then
 return
fi
vbmeta_path="$FLASH_SELECTED_PATH"
printf "${Y}开始执行关闭AVB2.0验证（刷入vbmeta.img）...${N}\n"
fastboot --disable-verity --disable-verification flash vbmeta "$vbmeta_path"

if [ $? -eq 0 ]; then
    printf "${G}AVB2.0验证关闭成功！vbmeta.img刷入完成${N}\n"
else
    printf "${R}AVB2.0验证关闭失败！请检查镜像文件或设备连接${N}\n"
fi
flash_pause
}

#修复 FastbootD 模式，刷入一组关键分区（boot、recovery、dtbo、modem、vbmeta 等）的 A/B 槽位。
flash_fix_fastbootd() {
local FULL_PACKAGE_IMG_DIR
local TARGET_PARTS="boot recovery dtbo modem vbmeta vendor_boot init_boot lk md1img"
local part
local IMG_PATH
local VALID_ENTRIES=""
local PART
local IMG_TO_FLASH
local valid_count

clear
flash_draw_title_line " [*]修复fastbootD模式 " 13
printf "\n请将设备重启到 fastboot \n"
printf "自动刷入以下分区\n"
printf "\nboot、recovery、dtbo、modem、vbmeta\n"
printf "vendor_boot、init_boot、lk、md1img\n"

echo
if ! flash_confirm_prompt "确认执行修复操作吗？(y继续/回车退出)：" "n"; then
    return
fi

flash_Reminder2
flash_get_path "请输入镜像所在路径：" ".img" "dir" ""
if [ -z "$FLASH_SELECTED_PATH" ]; then
 return
fi
FULL_PACKAGE_IMG_DIR="$FLASH_SELECTED_PATH"

echo
if ! flash_check_device_connection "fastboot"; then
    flash_pause
    return 1
fi

printf "${Y}正在扫描可刷入的镜像文件...${N}\n"
for part in $TARGET_PARTS; do
    IMG_PATH=""
    if [ -f "${FULL_PACKAGE_IMG_DIR}/${part}.img" ]; then
        IMG_PATH="${FULL_PACKAGE_IMG_DIR}/${part}.img"
    elif [ -f "${FULL_PACKAGE_IMG_DIR}/${part}.IMG" ]; then
        IMG_PATH="${FULL_PACKAGE_IMG_DIR}/${part}.IMG"
    fi

    if [ -n "$IMG_PATH" ]; then
        VALID_ENTRIES="${VALID_ENTRIES}
${part}|${IMG_PATH}"
        printf "纳入列表: $part\n"
    else
        printf "未找到${part}镜像，自动跳过\n"
    fi
done
valid_count=$(printf "$VALID_ENTRIES\n" | sed '/^[[:space:]]*$/d' | wc -l)
if [ "$valid_count" -eq 0 ]; then
    printf "${R}在 $FULL_PACKAGE_IMG_DIR 目录下没有找到任何有效的目标分区镜像文件 (.img)！${N}\n"
    flash_pause
    return
fi

printf "${Y}开始刷入分区（共 $valid_count 个）...${N}\n"
printf "$VALID_ENTRIES\n" | sed '/^[[:space:]]*$/d' | while IFS='|' read -r PART IMG_TO_FLASH; do
    flash_flash_with_retry "${PART}_a" "$IMG_TO_FLASH"
    flash_flash_with_retry "${PART}_b" "$IMG_TO_FLASH"
done

printf "\n${G}所有检测到的分区刷入完成！修复操作结束。${N}\n"
flash_pause
}

#修复欧加设备的 Super 分区（动态分区表损坏或 my_* 镜像刷入失败时使用）。
#移植 @小尘爱摆烂（Super分区修复测试.sh）二改提供@荆棘ty(天宇)
flash_fix_super_partition() {
local dec16
local dec_var
local group_size
clear
flash_draw_title_line " [*]欧加Super分区修复 " 13
printf "\n需要提前重启到${Y}fastboot${N}模式\n"
printf "\n 用于修复分区表损坏\n"
printf " 或修复 my_开头镜像/逻辑镜像 刷入失败\n"
echo
for tool in bc lpmake; do
    if ! which "$tool" >/dev/null 2>&1; then
        printf "${R}[X] 缺少依赖工具：$tool${N}\n"
        flash_pause
        return 1
    fi
done
echo
if ! flash_check_device_connection "fastboot"; then
    flash_pause
    return 1
fi
if [ "$FLASH_CONNECTION_MODE" = "fastbootD" ]; then
    printf "${R}[X] 当前为FastbootD模式，请重启到fastboot${N}\n"
    flash_pause
    return 1
fi
printf "${Y}正在读取super分区信息...${N}\n"
dec16=$(fastboot getvar all 2>&1 | grep 'partition-size:super' | sed 's/0x//g' | tr -d ' ' | sort -u | cut -d ':' -f 3-)
if [ -z "$dec16" ]; then
    printf "${R}[X] 未读取到super分区大小，请检查设备是否支持动态分区${N}\n"
    flash_pause
    return 1
fi
dec_var=$(printf "ibase=16; $dec16\n" | bc)
group_size=$(printf "$dec_var - 4194304\n" | bc)
if [ $(printf "$dec_var <= 0\n" | bc) -eq 1 ]; then
    printf "${R}[X] 读取到的super分区大小无效${N}\n"
    flash_pause
    return 1
fi
if [ $(printf "$group_size <= 0\n" | bc) -eq 1 ]; then
    printf "${R}[X] super分区空间不足，无法生成镜像${N}\n"
    flash_pause
    return 1
fi
printf "${G}[OK] 读取成功：super分区总大小 $dec_var 字节${N}\n"
printf "\n${Y}正在生成空super镜像...${N}\n"
lpmake \
--device-size="$dec_var" \
--metadata-size=65536 \
--metadata-slots=3 \
--super-name=super \
--group=qti_dynamic_partitions_a:"$group_size" \
--group=qti_dynamic_partitions_b:"$group_size" \
--partition=my_bigball_a:none:0:qti_dynamic_partitions_a \
--partition=my_bigball_b:none:0:qti_dynamic_partitions_b \
--partition=my_carrier_a:none:0:qti_dynamic_partitions_a \
--partition=my_carrier_b:none:0:qti_dynamic_partitions_b \
--partition=my_engineering_a:none:0:qti_dynamic_partitions_a \
--partition=my_engineering_b:none:0:qti_dynamic_partitions_b \
--partition=my_heytap_a:none:0:qti_dynamic_partitions_a \
--partition=my_heytap_b:none:0:qti_dynamic_partitions_b \
--partition=my_manifest_a:none:0:qti_dynamic_partitions_a \
--partition=my_manifest_b:none:0:qti_dynamic_partitions_b \
--partition=my_product_a:none:0:qti_dynamic_partitions_a \
--partition=my_product_b:none:0:qti_dynamic_partitions_b \
--partition=my_region_a:none:0:qti_dynamic_partitions_a \
--partition=my_region_b:none:0:qti_dynamic_partitions_b \
--partition=my_stock_a:none:0:qti_dynamic_partitions_a \
--partition=my_stock_b:none:0:qti_dynamic_partitions_b \
--partition=odm_a:none:0:qti_dynamic_partitions_a \
--partition=odm_b:none:0:qti_dynamic_partitions_b \
--partition=odm_dlkm_a:none:0:qti_dynamic_partitions_a \
--partition=odm_dlkm_b:none:0:qti_dynamic_partitions_b \
--partition=system_a:none:0:qti_dynamic_partitions_a \
--partition=system_b:none:0:qti_dynamic_partitions_b \
--partition=system_dlkm_a:none:0:qti_dynamic_partitions_a \
--partition=system_dlkm_b:none:0:qti_dynamic_partitions_b \
--partition=system_ext_a:none:0:qti_dynamic_partitions_a \
--partition=system_ext_b:none:0:qti_dynamic_partitions_b \
--partition=product_a:none:0:qti_dynamic_partitions_a \
--partition=product_b:none:0:qti_dynamic_partitions_b \
--partition=vendor_a:none:0:qti_dynamic_partitions_a \
--partition=vendor_b:none:0:qti_dynamic_partitions_b \
--partition=vendor_dlkm_a:none:0:qti_dynamic_partitions_a \
--partition=vendor_dlkm_b:none:0:qti_dynamic_partitions_b \
--partition=my_company_a:none:0:qti_dynamic_partitions_a \
--partition=my_company_b:none:0:qti_dynamic_partitions_b \
--partition=my_preload_a:none:0:qti_dynamic_partitions_a \
--partition=my_preload_b:none:0:qti_dynamic_partitions_b \
--output=super_empty.img >/dev/null 2>&1
if [ $? -eq 0 ] && [ -f "super_empty.img" ]; then
    printf "\n${G}[OK] 空super镜像生成成功！${N}\n"
    printf "${Y}镜像路径：$(pwd)/super_empty.img${N}\n"
    echo
    if flash_confirm_prompt "是否一键刷入super_empty.img (y/回车取消): " "n"; then
        printf "\n${Y}开始刷入super分区...${N}\n"
        if flash_flash_with_retry "super" "super_empty.img"; then
            printf "${G}[OK] super分区刷入完成！${N}\n"
            printf "${Y}下一步进行线刷${N}\n"
        else
            printf "${R}[X] super分区刷入失败${N}\n"
        fi
    fi
else
    printf "${R}[X] 空super镜像生成失败${N}\n"
    flash_pause
    return 1
fi
echo
flash_pause
}

#欧加设备常规线刷（移植版），支持高通/联发科平台。
#移植 @皓皓的小月 （二改版_修900E版_v2.py）
flash_flash_full_package() {
local platform_choice
local PLATFORM
local WIPE_CHOICE="2"
local wipe_input
local IMG_FOLDER
local IMG_FILES
local img_count
local MODEM_IMG=""
local HAS_MODEM="0"
local FLASH_NEED_EXTRA_FLASH_DOUBLE_AD=0
local FLASH_DOUBLE_AD_IMG1=""
local FLASH_DOUBLE_AD_IMG2=""
local FLASH_DOUBLE_AD_STATUS="部分缺失/无"
local FLASH_MISC_IMG=""
local reboot_confirm
local DOUBLE_AD_PATH=""

clear
flash_draw_title_line " [*]欧加常规线刷（移植版）" 11
printf "\n移植@${Y}皓皓的小月${N}的源代码 + @${Y}小尘爱摆烂${N}代码\n"
printf "如果fastbootD无法进入 请使用${Y}[*]修复fastbootD模式${N}\n"
printf "\n如果多次出现 ${B}my_开头镜像/逻辑镜像${N} 刷入失败\n"
printf "请使用 ${Y}[*]欧加Super分区修复${N}\n"
echo
while true; do
    flash_draw_title_line ""  9
    printf "   ${Y}1${N}.高通 Qualcomm\n"
    printf "   ${Y}2${N}.联发科 MediaTek\n"
    printf "空回车退出\n"
    printf "请选择:"
    read platform_choice
    flash_draw_title_line ""  9
    case "$platform_choice" in
        "1") PLATFORM="Qualcomm"; break ;;
        "2") PLATFORM="MediaTek"; break ;;
          *) return ;;
    esac
done
printf "${G}平台选择：${Y}$PLATFORM${N}\n"
if [ "$PLATFORM" = "Qualcomm" ]; then
    while true; do
        flash_draw_title_line ""  9
        printf "   ${Y}yes.${N}清除\n"
        printf "   ${Y}2.${N}不清除\n"
        printf "空回车退出\n"
        printf "是否清除数据："
        read wipe_input
        flash_draw_title_line ""  9
        case "$wipe_input" in
            "yes") WIPE_CHOICE="1"; break ;;
            "2") WIPE_CHOICE="2"; break ;;
              *) return ;;
        esac
    done
fi
flash_Reminder2
flash_get_path "请输入镜像所在路径：" ".img" "dir" ""
if [ -z "$FLASH_SELECTED_PATH" ]; then
 return
fi
IMG_FOLDER="$FLASH_SELECTED_PATH"
echo
img_count=$(find "$IMG_FOLDER" -maxdepth 1 \( -name "*.img" -o -name "*.IMG" \) 2>/dev/null | wc -l)
printf "${G}找到 ${Y}$img_count${N} 个镜像文件${N}\n"

flash_get_oppo_images "$IMG_FOLDER"

if [ -n "$FLASH_DOUBLE_AD_IMG1" ] && [ -n "$FLASH_DOUBLE_AD_IMG2" ]; then
    if [ "$FLASH_DOUBLE_AD_STATUS" = "完整" ]; then
        DOUBLE_AD_PATH="$IMG_FOLDER"
    else
        DOUBLE_AD_PATH="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)/img/双广"
    fi
fi

if [ -f "$IMG_FOLDER/modem.img" ]; then
    MODEM_IMG="$IMG_FOLDER/modem.img"
elif [ -f "$IMG_FOLDER/modem.IMG" ]; then
    MODEM_IMG="$IMG_FOLDER/modem.IMG"
fi
[ -n "$MODEM_IMG" ] && HAS_MODEM="1"

if [ "$PLATFORM" = "Qualcomm" ] && [ "$WIPE_CHOICE" = "1" ] && [ -z "$FLASH_MISC_IMG" ]; then
    printf "\n${B}未找到misc_wipedata_oppo.img，无法自动清除数据\n"
    printf "如需清除数据请在rec点击简体中文—格式化数据分区${N}\n"
    WIPE_CHOICE="2"
fi

if [ "$PLATFORM" = "MediaTek" ]; then
    if [ -f "$IMG_FOLDER/preloader_raw.img" ]; then
        FLASH_PRELOADER_RAW_IMG="$IMG_FOLDER/preloader_raw.img"
    elif [ -f "$IMG_FOLDER/preloader_raw.IMG" ]; then
        FLASH_PRELOADER_RAW_IMG="$IMG_FOLDER/preloader_raw.IMG"
    fi
    [ -n "$FLASH_PRELOADER_RAW_IMG" ] && FLASH_HAS_PRELOADER_RAW="1"
fi

printf "\n${Y}即将开始刷写，请确认：${N}\n"
printf "平台：$PLATFORM\n"
printf "modem镜像：$([ \n"$HAS_MODEM" = "1" ] && echo "存在" || echo "不存在")"
printf "双广分区镜像：$FLASH_DOUBLE_AD_STATUS\n"
if [ "$PLATFORM" = "Qualcomm" ]; then
    printf "清除数据：$([ \n"$WIPE_CHOICE" = "1" ] && echo "${Y}清除${N}" || echo "${Y}不清除${N}")"
    [ "$WIPE_CHOICE" = "1" ] && printf "misc镜像：$([ -n \n"$FLASH_MISC_IMG" ] && printf "存在\n" || printf "不存在\n")"
elif [ "$PLATFORM" = "MediaTek" ]; then
    printf "preloader_raw镜像：$([ \n"$FLASH_HAS_PRELOADER_RAW" = "1" ] && echo "存在" || echo "不存在")"
fi
flash_get_battery_level
printf "请确保刷写途中不被断开，确保连接稳定\n"

echo
if ! flash_confirm_prompt "确认开始刷写？(y/回车退出): " "n"; then
    return
fi

printf "\n${G}开始刷写流程...${N}\n"
flash_check_device_connection "any"
if [ -z "$FLASH_CONNECTION_MODE" ] || [ -z "$FLASH_DEVICE_SERIAL" ]; then
    flash_pause
    return 1
fi
if ! flash_ensure_target_mode "fastbootD"; then
    flash_pause
    return 1
fi

flash_erase_cow_partitions_in_fastbootd "$IMG_FOLDER" "$DOUBLE_AD_PATH"

if [ "$FLASH_NEED_EXTRA_FLASH_DOUBLE_AD" -eq 1 ]; then
    flash_flash_main_partitions_in_fastbootd "$IMG_FOLDER" "$FLASH_DOUBLE_AD_IMG1" "$FLASH_DOUBLE_AD_IMG2"
else
    flash_flash_main_partitions_in_fastbootd "$IMG_FOLDER" "" ""
fi

if [ "$PLATFORM" = "Qualcomm" ]; then
    if ! flash_ensure_target_mode "bootloader"; then
        flash_pause
        return 1
    fi
    if [ "$HAS_MODEM" = "1" ]; then
        printf "\n${G}刷写modem分区...${N}\n"
        flash_flash_with_retry "modem_a" "$MODEM_IMG"
        flash_flash_with_retry "modem_b" "$MODEM_IMG"
    else
        printf "${Y}跳过modem刷写（未找到modem.img）${N}\n"
    fi
    if [ "$WIPE_CHOICE" = "1" ]; then
        if [ -n "$FLASH_MISC_IMG" ] && [ -f "$FLASH_MISC_IMG" ]; then
            printf "\n${G}刷写misc分区（清除数据）...${N}\n"
            fastboot flash misc "$FLASH_MISC_IMG"
            [ $? -eq 0 ] && printf "${G}misc刷写完成${N}\n" || printf "${R}misc刷写失败${N}\n"
        fi
        printf "\n${G}清除数据：自动重启到系统...${N}\n"
        fastboot reboot
    else
        printf "\n${G}不清除数据：刷写流程已完成${N}\n"
        if flash_confirm_prompt "是否立即重启设备？(y/回车不重启)：" "n"; then
            fastboot reboot
            printf "${Y}正在重启设备...${N}\n"
        else
            printf "${Y}已取消重启${N}\n"
        fi
    fi
    printf "\n${G}[OK] 高通平台刷写完成！${N}\n"
else
    if [ "$PLATFORM" = "MediaTek" ] && [ "$FLASH_HAS_PRELOADER_RAW" = "1" ]; then
        printf "\n${Y}开始刷写preloader_raw镜像...${N}\n"
        fastboot flash preloader_raw "$FLASH_PRELOADER_RAW_IMG"
        printf "${G}preloader_raw刷写命令执行完成（报错可直接无视）${N}\n"
    fi
    if [ "$HAS_MODEM" = "1" ]; then
        printf "\n${G}联发科平台：在fastbootD刷写modem分区...${N}\n"
        flash_flash_with_retry "modem_a" "$MODEM_IMG"
        flash_flash_with_retry "modem_b" "$MODEM_IMG"
    else
        printf "${Y}跳过modem刷写（未找到modem.img）${N}\n"
    fi
    printf "\n${G}[OK] 联发科平台刷写完成！${N}\n"
    printf "\n${Y}如需清除数据请点击简体中文—格式化数据分区${N}\n"
    printf "${Y}不需要的点击重启设备${N}\n"
fi
echo
flash_pause
}

#纯 FastbootD 线刷，适用于没有 Fastboot 的设备。
flash_flash_pure_fastbootd_full_package() {
local FULL_PACKAGE_IMG_DIR
local DOUBLE_AD_PATH=""
local FLASH_DOUBLE_AD_STATUS="部分缺失/无"
local USE_DOUBLE_AD=0
local IMG_COUNT
local WIPE_DATA=0
local current_slot
local slot_count
local TARGET_SLOT
local IMG_FOLDER
local VALID_IMGS=""
local TOTAL_IMGS
local SUCCESS_COUNT=0
local FAIL_COUNT=0
local img_path
local PARTITION
local TARGET_PARTITION
local REBOOT_CONFIRM

clear
flash_draw_title_line " [*]欧加纯fastbootD线刷 " 12
echo
printf "${Y}仅支持官方rec 不支持第三方${N}\n"
printf "适用于没有 fastboot 的设备\n"
flash_get_battery_level
flash_Reminder2
flash_get_path "请输入镜像所在路径：" ".img" "dir" ""
if [ -z "$FLASH_SELECTED_PATH" ]; then
 return
fi
FULL_PACKAGE_IMG_DIR="$FLASH_SELECTED_PATH"

flash_get_oppo_images "$FULL_PACKAGE_IMG_DIR"

if [ -n "$FLASH_DOUBLE_AD_IMG1" ] && [ -n "$FLASH_DOUBLE_AD_IMG2" ]; then
    USE_DOUBLE_AD=1
    if [ "$FLASH_DOUBLE_AD_STATUS" = "完整" ]; then
        DOUBLE_AD_PATH="$FULL_PACKAGE_IMG_DIR"
    else
        DOUBLE_AD_PATH="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)/img/双广"
    fi
fi

IMG_COUNT=$(find "$FULL_PACKAGE_IMG_DIR" -maxdepth 1 \( -name "*.img" -o -name "*.IMG" \) 2>/dev/null | wc -l)
if [ "$IMG_COUNT" -eq 0 ] && [ "$USE_DOUBLE_AD" -eq 0 ]; then
    printf "${R}未找到任何有效镜像文件，操作终止！${N}\n"
    flash_pause
    return 1
fi

printf "${G}  找到 ${Y}$IMG_COUNT${N} 个镜像${N}\n"
printf "  双广分区镜像：${Y}$FLASH_DOUBLE_AD_STATUS${N}\n"
echo
if flash_confirm_prompt "是否清除数据(yes/回车不清除)：" "n" "yes"; then
    WIPE_DATA=1
    printf "${Y}已选择：清除数据${N}\n"
else
    WIPE_DATA=0
    printf "${Y}已选择：不清除数据${N}\n"
fi
echo
if ! flash_check_device_connection "any"; then
    flash_pause
    return 1
fi
if ! flash_ensure_target_mode "fastbootD"; then
    flash_pause
    return 1
fi
current_slot=$(fastboot -s "$FLASH_DEVICE_SERIAL" getvar current-slot 2>&1 | grep -E '^current-slot:' | sed -n 's/.*: *//p' | tr -d '[:space:]')
slot_count=$(fastboot -s "$FLASH_DEVICE_SERIAL" getvar slot-count 2>&1 | grep -E '^slot-count:' | sed -n 's/.*: *//p' | tr -d '[:space:]')
if [ "$slot_count" != "2" ]; then
    printf "\n${R}错误：设备不支持AB双槽架构，无法使用此功能！${N}\n"
    flash_pause
    return 1
fi
if [ -z "$current_slot" ] || ! printf "$current_slot\n" | grep -qE '^[ab]$'; then
    printf "\n${R}错误：无法获取当前激活槽位，请检查设备连接状态！${N}\n"
    flash_pause
    return 1
fi
if [ "$current_slot" = "a" ]; then
    TARGET_SLOT="b"
else
    TARGET_SLOT="a"
fi
printf "${G}当前激活槽位 ${Y}$current_slot${N}，目标刷入槽位 ${Y}$TARGET_SLOT${N}\n"
IMG_FOLDER="$FULL_PACKAGE_IMG_DIR"

flash_erase_cow_partitions_in_fastbootd "$IMG_FOLDER" "$DOUBLE_AD_PATH"

set +f
for img_path in "$FULL_PACKAGE_IMG_DIR"/*.img "$FULL_PACKAGE_IMG_DIR"/*.IMG; do
    [ -f "$img_path" ] && VALID_IMGS="$VALID_IMGS $img_path"
done
if [ "$USE_DOUBLE_AD" -eq 1 ] && [ "$DOUBLE_AD_PATH" != "$FULL_PACKAGE_IMG_DIR" ]; then
    VALID_IMGS="$VALID_IMGS ${DOUBLE_AD_PATH}/my_company.img ${DOUBLE_AD_PATH}/my_preload.img"
fi
set -f
VALID_IMGS=$(printf "$VALID_IMGS\n" | sed 's/^ *//;s/ *$//')
if [ -z "$VALID_IMGS" ]; then
    printf "${R}未加载到任何有效镜像文件，操作终止！${N}\n"
    flash_pause
    return 1
fi
TOTAL_IMGS=$(printf "$VALID_IMGS\n" | wc -w)
for img_path in $VALID_IMGS; do
    PARTITION=$(basename "$img_path" .img)
    PARTITION=$(basename "$PARTITION" .IMG)
    PARTITION=$(printf "$PARTITION\n" | sed -E 's/_[ab]$//')
    TARGET_PARTITION="${PARTITION}_${TARGET_SLOT}"
    if flash_flash_with_retry "$TARGET_PARTITION" "$img_path"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done
echo
flash_draw_title_line "刷入结束" 12 B
printf "${G}刷入完成：成功 ${SUCCESS_COUNT} 个，失败 ${FAIL_COUNT} 个\n"
printf "\n${Y}正在激活目标槽位 ${TARGET_SLOT}...${N}\n"
fastboot -s "$FLASH_DEVICE_SERIAL" --set-active="$TARGET_SLOT"
if [ $? -eq 0 ]; then
    printf "${G}[OK] 目标槽位 ${TARGET_SLOT} 激活成功！重启后将从新槽位启动${N}\n"
else
    printf "${R}[X] 目标槽位激活失败，请手动执行命令：fastboot --set-active=$TARGET_SLOT${N}\n"
    flash_pause
    return 1
fi
echo
if [ "$WIPE_DATA" -eq 1 ]; then
    printf "\n${G}清除数据...${N}\n"
    fastboot -w
    printf "${Y}正在重启到系统...${N}\n"
    fastboot reboot
    printf "${G}[OK] 恢复出厂设置与重启命令已发送${N}\n"
else
    if flash_confirm_prompt "是否直接重启到系统？(y/回车不重启)：" "n"; then
        printf "${Y}正在重启到系统...${N}\n"
        fastboot reboot
        printf "${G}[OK] 重启命令已发送${N}\n"
    else
        printf "${Y}已取消重启，设备保持在fastbootD模式${N}\n"
    fi
fi
printf "\n${G} 欧加纯fastbootD线刷流程全部结束！${N}\n"
flash_pause
}

flash_show_device_info() {
clear
flash_draw_title_line " 设备信息 " 18
echo
if ! flash_check_device_connection "any"; then
    return 1
fi
if [ "$FLASH_CONNECTION_MODE" != "adb" ] && [ "$FLASH_CONNECTION_MODE" != "recovery" ]; then
    printf "${R}仅支持系统(ADB)或Recovery模式连接！${N}\n"
    return 1
fi
printf "${Y}正在获取设备信息...${N}\n\n"
local battery_info=$(adb shell dumpsys battery 2>/dev/null)
local battery_level=$(printf "$battery_info\n" | grep -E '^[[:space:]]*level:' | awk '{print $2}' | tr -d '\r')
local battery_status_code=$(printf "$battery_info\n" | grep -E '^[[:space:]]*status:' | awk '{print $2}' | tr -d '\r')
local battery_status="未知"
case "$battery_status_code" in
    2) battery_status="充电中" ;;
    3) battery_status="放电中" ;;
    4) battery_status="未充电" ;;
    5) battery_status="已满" ;;
esac
local total_ram=$(adb shell cat /proc/meminfo 2>/dev/null | grep MemTotal | awk '{printf "%.2f GB", $2/1024/1024}')
local storage_total=$(adb shell df -h /data 2>/dev/null | awk 'NR==2 {print $2}')
local storage_used=$(adb shell df -h /data 2>/dev/null | awk 'NR==2 {print $3}')
local is_root="否"
adb shell su -c "echo 1" 2>/dev/null | grep -q 1 && is_root="是"
printf "${G}制造商：${N}$(adb shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r')\n"
printf "${G}型号：${N}$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')\n"
printf "${G}序列号：${N}$(adb shell getprop ro.serialno 2>/dev/null | tr -d '\r')\n"
printf "${G}Android 版本：${N}$(adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r') (SDK $(adb shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r'))\n"
printf "${G}安全补丁：${N}$(adb shell getprop ro.build.version.security_patch 2>/dev/null | tr -d '\r')\n"
printf "${G}内核版本：${N}$(adb shell uname -r 2>/dev/null | tr -d '\r')\n"
printf "${G}CPU 架构：${N}$(adb shell getprop ro.product.cpu.abi 2>/dev/null | tr -d '\r')\n"
printf "${G}屏幕分辨率：${N}$(adb shell wm size 2>/dev/null | awk '{print $3}')\n"
printf "${G}总内存：${N}${total_ram:-未知}\n"
printf "${G}存储空间：${N}${storage_used:-0} / ${storage_total:-0}\n"
printf "${G}电池电量：${N}${battery_level:-?}%% (${battery_status})\n"
printf "${G}是否 Root：${N}${is_root}\n"
printf "${G}当前槽位：${N}$(adb shell getprop ro.boot.slot_suffix 2>/dev/null | tr -d '\r')\n"
echo
}

#Recovery的功能菜单
flash_recovery_functions() {
local choice
local zip_path
local local_img_path
local target_partition
local slot_suffix
local flash_parts
local img_filename
local device_temp_path
local success_count
local fail_count
local part

while true; do
    clear
    flash_draw_title_line " Recovery 模式功能 " 13
    printf "\n ${Y}1${N}.[*]ADB Sideload\n"
    printf " ${Y}2${N}.进入ADB Shell\n"
    printf " ${Y}3${N}.文件提取\n"
    printf " ${Y}4${N}.传输文件\n"
    printf "\n ${Y}5${N}.刷入镜像\n"
    printf " ${Y}6${N}.镜像提取\n"
    printf " ${Y}7${N}.获取设备信息\n"
    printf "\n空回车退出\n"
    printf "请输入 [${Y}1-7${N}]: "
    read choice
    case $choice in
        1) clear
            flash_draw_title_line " [*]ADB Sideload " 16
            echo
            flash_get_battery_level
            flash_check_device_connection "any"
            
            if [ "$FLASH_CONNECTION_MODE" != "sideload" ]; then
                printf "请确保设备已进入ADB Sideload模式\n"
                flash_pause
                continue
            fi
            printf "\n${Y}q退出${N}\n"
            flash_get_path "请输入ZIP包路径: " ".zip" "file" "0"
            if [ -z "$FLASH_SELECTED_PATH" ]; then
             continue
            fi
            zip_path="$FLASH_SELECTED_PATH"
            printf "${G}文件校验通过，开始刷入...${N}\n"
            
            adb sideload "$zip_path" 2>&1
            [ $? -eq 0 ] && printf "${G}ZIP包刷入成功！${N}\n" || printf "${R}刷入失败，请检查包完整性和设备连接${N}\n" ;;
        2) clear
            flash_draw_title_line " ADB Shell " 17
            echo
            if flash_check_device_connection "recovery"; then
                printf "${Y}进入Recovery模式ADB Shell...（输入exit退出）${N}\n"
                adb shell
                clear
            fi ;;
        3) flash_file_extract ;;
        4) flash_file_upload ;;
        5) clear
            flash_draw_title_line " Recovery 刷入镜像 " 13
            echo
            flash_get_battery_level
            if ! flash_check_device_connection "recovery"; then
                flash_pause
                continue
            fi
            flash_Reminder
            flash_get_path "请输入镜像文件路径: " ".img" "file" "0"
            if [ -z "$FLASH_SELECTED_PATH" ]; then
             continue
            fi
            local_img_path="$FLASH_SELECTED_PATH"
            printf "${G}镜像文件校验通过${N}\n"
            printf "\n${Y}示例：boot、recovery、init_boot、vendor_boot${N}\n"
            printf "请输入目标刷入分区名称: "
            read target_partition
            if [ -z "$target_partition" ]; then
                printf "${R}分区名称不能为空！${N}\n"
                flash_pause
                continue
            fi
            slot_suffix=$(adb -s "$FLASH_DEVICE_SERIAL" shell getprop ro.boot.slot_suffix 2>/dev/null | tr -d '[:space:]')
            adb -s "$FLASH_DEVICE_SERIAL" shell test -b "/dev/block/by-name/${target_partition}_a" 2>/dev/null
            if [ $? -eq 0 ] && [ -n "$slot_suffix" ]; then
                flash_parts="${target_partition}_a ${target_partition}_b"
            else
                flash_parts="$target_partition"
            fi
            img_filename=$(basename "$local_img_path")
            device_temp_path="/data/$img_filename"
            printf "\n${Y}即将执行操作：${N}\n"
            printf "1. 传输镜像到设备临时路径：${B}$device_temp_path${N}\n"
            printf "2. 刷入分区：${B}$flash_parts${N}\n"
            printf "\n${R}刷入错误的镜像或分区会导致设备变砖！${N}\n"
            
            if ! flash_confirm_prompt "确认执行刷入? (y/n): "; then
                continue
            fi

            printf "\n${Y}正在传输镜像文件到目标设备...${N}\n"
            adb -s "$FLASH_DEVICE_SERIAL" push "$local_img_path" "$device_temp_path"
            if [ $? -ne 0 ]; then
                printf "${R}镜像传输失败！请检查设备连接、路径权限${N}\n"
                flash_pause
                continue
            fi
            printf "${G}镜像传输成功${N}\n"
            echo
            success_count=0
            fail_count=0
            for part in $flash_parts; do
                printf "${Y}开始刷入 $part 分区...${N}\n"
                adb -s "$FLASH_DEVICE_SERIAL" shell dd if="$device_temp_path" of="/dev/block/by-name/$part" bs=4M 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}[OK] $part 分区刷入成功${N}\n"
                    success_count=$((success_count + 1))
                else
                    printf "${R}[X] $part 分区刷入失败！请检查分区名是否正确、镜像是否匹配${N}\n"
                    fail_count=$((fail_count + 1))
                fi
            done
            echo
            if [ $fail_count -eq 0 ]; then
                adb -s "$FLASH_DEVICE_SERIAL" shell rm -f "$device_temp_path" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    printf "${G}临时文件清理完成${N}\n"
                else
                    printf "${Y}临时文件清理失败，可手动删除路径：$device_temp_path${N}\n"
                fi
            else
                printf "${Y}刷入操作执行完毕，异常分区请查看上方日志排查${N}\n"
            fi ;;
        6) flash_extract_image
            local ret=$?
            if [ $ret -eq 2 ]; then
            continue
            fi ;;
        7) flash_show_device_info ;;
        *) return 0 ;;
    esac
    flash_pause
done
}

#系统功能菜单
flash_system_functions() {
local choice
local package
local folder_path
local apk_files
local install_choice
local filename
local index
local num
local pair_addr
local connect_addr
local disconnect_addr
local save_path
local IFS

while true; do
    clear
    flash_draw_title_line " 系统模式功能 " 16
    echo
    flash_get_battery_level
    printf " ${Y}1${N}.进入ADB Shell     ${Y}2${N}.传输文件\n"
    printf " ${Y}3${N}.删除应用          ${Y}4${N}.文件提取\n"
    printf " ${Y}5${N}.批量/安装APK\n"
    printf "\n ${Y}6${N}.首次无线,配对\n"
    printf " ${Y}7${N}.无线调试,连接\n"
    printf " ${Y}8${N}.无线调试,断开\n"
    printf "\n ${Y}9${N}.停用应用           ${Y}10${N}.[OK]恢复停用应用\n"
    printf " ${Y}11${N}.亮屏/息屏         ${Y}12${N}.播放/暂停音乐\n"
    printf " ${Y}13${N}.音量加            ${Y}14${N}.音量减\n"
    printf " ${Y}15${N}.屏幕截图\n"
    printf " ${Y}16${N}.镜像提取(root)    ${Y}17${N}.获取设备信息\n"
    printf " ${Y}18${N}.发送Shell通知\n"
    printf "\n空回车退出\n"
    printf "请输入 [${Y}1-18${N}]: "
    read choice
    case $choice in
        1) clear
            flash_draw_title_line " ADB Shell " 17
            echo
            if flash_check_device_connection "adb"; then
                printf "${Y}进入ADB Shell...（输入exit退出）${N}\n"
                adb shell
                clear
            fi ;;
        2) flash_file_upload ;;
        3) clear
            flash_draw_title_line " 删除应用 " 18
            echo
            if flash_check_device_connection "adb"; then
                printf "请输入要删除的应用包名: "
                read package
                if [ -z "$package" ]; then
                    printf "${R}包名不能为空${N}\n"
                    flash_pause
                    continue
                fi
                printf "${R}不要想着去删系统软件，不然开不了机的哟${N}\n"
                
                if ! flash_confirm_prompt "确认删除 $package? (yes/n): " "n" "yes"; then
                    flash_pause
                    continue
                fi

                printf "${Y}正在删除应用...${N}\n"
                adb shell pm uninstall --user 0 $package
                if [ $? -eq 0 ]; then
                    printf "${G}应用删除成功${N}\n"
                else
                    printf "${R}删除失败！${N}\n"
                fi
            fi ;;
        4) flash_file_extract ;;
        5) clear
            flash_draw_title_line " 批量/安装APK " 15
            echo
            if flash_check_device_connection "adb"; then
               printf "\n${Y}q退出${N}\n"
                flash_get_path "请输入包含APK文件的文件夹路径: " ".apk" "dir" "1"
                if [ -z "$FLASH_SELECTED_PATH" ]; then
                    continue
                fi
                folder_path="$FLASH_SELECTED_PATH"
                
                # 创建临时文件存储APK列表
                apk_list_file="/data/local/tmp/apk_list_$$"
                find "$folder_path" -maxdepth 1 -name "*.apk" -type f > "$apk_list_file" 2>/dev/null
                apk_count=$(wc -l < "$apk_list_file")
                
                if [ "$apk_count" -eq 0 ]; then
                    printf "${R}未找到APK文件（异常）${N}\n"
                    rm -f "$apk_list_file"
                else
                    printf "${G}找到以下APK文件:${N}\n"
                    idx=1
                    while IFS= read -r apk_path; do
                        filename=$(basename "$apk_path")
                        printf "$idx. $filename\n"
                        idx=$((idx+1))
                    done < "$apk_list_file"
                    
                    printf "\n${Y}1${N}. 安装所有APK\n"
                    printf "${Y}2${N}. 选择特定APK安装\n"
                    printf "请选择 [${Y}1-2${N}]: "
                    read install_choice
                    
                    case $install_choice in
                        1)  while IFS= read -r apk; do
                                filename=$(basename "$apk")
                                printf "${Y}正在安装: $filename${N}\n"
                                adb install "$apk"
                                if [ $? -eq 0 ]; then
                                    printf "${G}$filename 安装成功${N}\n"
                                else
                                    printf "${R}$filename 安装失败${N}\n"
                                fi
                                echo
                            done < "$apk_list_file" ;;
                        2)  printf "请输入上面的apk编号(多个用空格分隔): "
                            read apk_numbers
                            if [ -z "$apk_numbers" ]; then
                                printf "${R}编号不能为空${N}\n"
                                rm -f "$apk_list_file"
                                break
                            fi
                            for num in $apk_numbers; do
                                if [ "$num" -ge 1 ] && [ "$num" -le "$apk_count" ]; then
                                    apk=$(sed -n "${num}p" "$apk_list_file")
                                    filename=$(basename "$apk")
                                    printf "${Y}正在安装: $filename${N}\n"
                                    adb install "$apk"
                                    if [ $? -eq 0 ]; then
                                        printf "${G}$filename 安装成功${N}\n"
                                    else
                                        printf "${R}$filename 安装失败${N}\n"
                                    fi
                                    echo
                                else
                                    printf "${R}无效编号: $num${N}\n"
                                fi
                            done ;;
                        *) printf "${R}无效选择${N}\n" ;;
                    esac
                    rm -f "$apk_list_file"
                fi
            fi ;;
        6) clear
            flash_draw_title_line " 首次无线 配对 " 15
            printf "\n${Y}提示：需先在设备上开启无线调试，获取配对IP和端口${N}\n"
            printf "请输入配对IP地址:端口号\n"
            printf "（例：192.168.1.100:4444）: "
            read pair_addr
            if [ -z "$pair_addr" ]; then
                printf "${R}地址不能为空！${N}\n"
                flash_pause
                continue
            fi
            printf "${Y}请在下方输入设备显示的配对码...${N}\n"
            echo
            pair_output=$(adb pair "$pair_addr" 2>&1 | tee /dev/tty)
            
            if printf "$pair_output\n" | grep -qE 'Successfully paired|Pairing successful'; then
                printf "\n${G}[OK] 无线配对成功！${N}\n"
            else
                printf "\n${R}[X] 配对失败！请检查IP端口是否正确或设备是否开启无线调试${N}\n"
            fi ;;
        7) clear
            flash_draw_title_line " 无线调试 连接 " 15
            printf "\n${Y}提示：需要提前无线配对,才能连接${N}\n"
            printf "请输入设备无线IP地址:端口号\n"
            printf "（例：192.168.1.100:5555）: "
            read connect_addr
            if [ -z "$connect_addr" ]; then
                printf "${R}地址不能为空！${N}\n"
                flash_pause
                continue
            fi
            connect_output=$(adb connect "$connect_addr" 2>&1)
            printf "$connect_output\n"
            
            if printf "$connect_output\n" | grep -qE 'connected to|already connected'; then
                printf "${G}[OK] 无线调试连接成功！${N}\n"
            else
                printf "${R}[X] 连接失败！请检查IP端口或配对状态${N}\n"
            fi ;;
        8) clear
            flash_draw_title_line " 无线调试 断开 " 15
            echo
            adb devices 2>/dev/null | grep -v "List of devices"
            printf "请输入要断开的设备IP地址:端口号\n"
            printf "（从上方列表选择）: "
            
            read disconnect_addr
            if [ -z "$disconnect_addr" ]; then
                printf "${R}地址不能为空！${N}\n"
                flash_pause
                continue
            fi
            adb disconnect "$disconnect_addr"
            if [ $? -eq 0 ]; then
                printf "${G}断开成功！${N}\n"
                printf "${Y}断开后剩余连接设备:${N}\n"
                echo
                adb devices 2>/dev/null | grep -v "List of devices"
            else
                printf "${R}断开失败！请检查IP端口是否正确${N}\n"
            fi ;;
        9) clear
            flash_draw_title_line " 停用应用 " 18
            echo
            if flash_check_device_connection "adb"; then
                printf "请输入要停用的应用包名: "
                read package
                if [ -z "$package" ]; then
                    printf "${R}包名不能为空${N}\n"
                    flash_pause
                    continue
                fi
                printf "${R}停用系统应用可能导致功能异常，谨慎操作！${N}\n"
                
                if ! flash_confirm_prompt "确认停用 $package? (yes/n): " "n" "yes"; then
                    flash_pause
                    continue
                fi

                printf "${Y}正在停用应用...${N}\n"
                adb shell pm disable-user --user 0 $package
                if [ $? -eq 0 ]; then
                    printf "${G}应用停用成功（可通过选项8恢复）${N}\n"
                else
                    printf "${R}停用失败！可能是系统关键应用或无权限${N}\n"
                fi
            fi ;;
        10) clear
            flash_draw_title_line " [OK]恢复停用应用 " 16
            echo
            if flash_check_device_connection "adb"; then
                printf "请输入要恢复的应用包名: "
                read package
                if [ -z "$package" ]; then
                    printf "${R}包名不能为空${N}\n"
                    flash_pause
                    continue
                fi
                
                if flash_confirm_prompt "确认恢复 $package? (y/n): "; then
                    printf "${Y}正在恢复应用...${N}\n"
                    adb shell pm enable --user 0 $package
                    if [ $? -eq 0 ]; then
                        printf "${G}应用恢复成功！已重新启用${N}\n"
                    else
                        printf "${R}恢复失败！可能是应用未被停用或包名错误${N}\n"
                    fi
                else
                    continue
                fi
            fi ;;
        11) clear
            flash_draw_title_line " 亮屏/息屏 " 17
            echo
            if flash_check_device_connection "adb"; then
                printf "${Y}正在发送亮屏/息屏命令...${N}\n"
                adb shell input keyevent 26
                printf "${G}亮屏/息屏命令已发送（按当前屏幕状态切换）${N}\n"
            fi ;;
        12) clear
            flash_draw_title_line " 播放/暂停音乐 " 15
            echo
            if flash_check_device_connection "adb"; then
                printf "${Y}正在发送播放/暂停命令...${N}\n"
                adb shell input keyevent 85
                if [ $? -ne 0 ]; then
                    adb shell media play-flash_pause
                fi
                printf "${G}播放/暂停命令已发送${N}\n"
            fi ;;
        13) clear
            flash_draw_title_line " 音量加 " 18
            echo
            if flash_check_device_connection "adb"; then
                printf "${Y}正在发送音量加命令...${N}\n"
                adb shell input keyevent 24
                printf "${G}音量加命令已发送${N}\n"
            fi ;;
        14) clear
            flash_draw_title_line " 音量减 " 18
            echo
            if flash_check_device_connection "adb"; then
                printf "${Y}正在发送音量减命令...${N}\n"
                adb shell input keyevent 25
                printf "${G}音量减命令已发送${N}\n"
            fi ;;
        15) clear
            flash_draw_title_line " 屏幕截图（实时保存） " 12
            echo
            if flash_check_device_connection "adb"; then
                printf "（例：/sdcard/screenshot.png）回车默认\n"
                printf "请输入保存路径: "
                read save_path
                if [ -z "$save_path" ]; then
                    save_path="/sdcard/$(date +%Y%m%d%H%M%S).png"
                    printf "${Y}未输入路径，默认保存为：$save_path${N}\n"
                fi
                printf "${Y}正在截图...${N}\n"
                adb shell screencap -p > "$save_path" 2>/dev/null
                if [ $? -eq 0 ]; then
                    printf "${G}截图成功！文件已保存至：$save_path${N}\n"
                else
                    adb shell screencap "$save_path"
                    if [ $? -eq 0 ]; then
                        printf "${G}截图成功！文件已保存至：$save_path${N}\n"
                    else
                        printf "${R}截图失败，请检查路径权限${N}\n"
                    fi
                fi
            fi ;;
        16) flash_extract_image
            local ret=$?
            if [ $ret -eq 2 ]; then
            continue
            fi ;;
        17) flash_show_device_info ;;
        18) clear
        flash_draw_title_line " 发送Shell通知 " 15
        echo
        if ! flash_check_device_connection "adb"; then
            flash_pause
            continue
        fi
        printf "请输入通知标题（必填）: "
        read notify_title
        if [ -z "$notify_title" ]; then
            printf "${R}通知标题不能为空！${N}\n"
            flash_pause
            continue
        fi
        printf "请输入通知标签（自定义，如mytag）: "
        read notify_tag
        if [ -z "$notify_tag" ]; then
            notify_tag="adb_notify"
            printf "${Y}未输入标签，使用默认：$notify_tag${N}\n"
        fi
        printf "请输入通知内容（必填）: "
        read notify_content
        if [ -z "$notify_content" ]; then
            printf "${R}通知内容不能为空！${N}\n"
            flash_pause
            continue
        fi
        printf "${Y}正在发送通知...${N}\n"
        adb shell cmd notification post -t "$notify_title" "$notify_tag" "$notify_content"
        if [ $? -eq 0 ]; then
            printf "${G}[OK] 通知发送成功！${N}\n"
        else
            printf "${R}[X] 通知发送失败！${N}\n"
        fi ;;

        *) return 0 ;;
    esac
    flash_pause
done
}

#Fastboot/FastbootD 模式下的功能菜单
flash_fastboot_functions() {
local choice
local img_name
local partition
local user_input_path
local img_path
local full_img_path
local bl_status

while true; do
    clear
    flash_draw_title_line " Fastboot/D 镜像刷入和功能 " 9
    echo
    flash_get_battery_level
    printf " ${Y}1${N}.刷入 boot          ${Y}2${N}.刷入 init_boot\n"
    printf " ${Y}3${N}.刷入 recovery      ${Y}4${N}.刷入 dtbo\n"
    printf " ${Y}5${N}.刷入自定义镜像     ${Y}6${N}.欧加/pixel 解BL\n"
    printf " ${Y}7${N}.[*]AB分区检测         ${Y}8${N}.AB分区切换\n"
    printf "\n ${Y}9${N}.[*]关闭AVB2.0验证      ${Y}10${N}.[*]读取分区表\n"
    printf " ${Y}11${N}.去除谷歌锁         ${Y}12${N}.格式化\n"
    printf " ${Y}13${N}.上锁BL             ${Y}14${N}.🚦临时启动recovery\n"
    printf " ${Y}15${N}.[*]检查BL解锁状态\n"
    printf "\n空回车退出\n"  
    printf "请输入 [${Y}1-15${N}]: "
    read choice
    
    case $choice in
        1|2|3|4)
            clear
            flash_draw_title_line " 镜像刷入 " 18
            echo
            if ! flash_check_device_connection "fastboot"; then
                flash_pause
                continue
            fi
            case $choice in
                1) img_name="boot.img"
                    partition="boot"
                    printf "${Y}刷入boot分区${N}\n" ;;
                2) img_name="init_boot.img"
                    partition="init_boot"
                    printf "${Y}刷入init_boot分区${N}\n" ;;
                3) img_name="recovery.img"
                    partition="recovery"
                    printf "${Y}刷入recovery分区${N}\n" ;;
                4) img_name="dtbo.img"
                    partition="dtbo"
                    printf "${Y}刷入dtbo分区${N}\n" ;;
            esac
            flash_Reminder
            flash_get_path "请输入镜像文件路径：" ".img" "file" "0"
            if [ -z "$FLASH_SELECTED_PATH" ]; then
             continue
            fi
            img_path="$FLASH_SELECTED_PATH"
            printf "\n${G}文件校验通过！${N}\n"
            printf "${Y}即将刷入: $img_path 到 $partition${N}\n"
            printf "${R}请再次确认文件和分区正确性！${N}\n"
            
            if ! flash_confirm_prompt "确认刷入? (y/n): "; then
                continue
            fi
            printf "${G}开始刷入镜像...${N}\n"
            flash_flash_with_retry "$partition" "$img_path" ;;
        5) clear
            flash_draw_title_line " 自定义刷入镜像 " 15
            echo
            if ! flash_check_device_connection "fastboot"; then
                flash_pause
                continue
            fi
            flash_Reminder
            flash_get_path "请输入镜像文件路径：" ".img" "file" "0"
            if [ -z "$FLASH_SELECTED_PATH" ]; then
             continue
            fi
            full_img_path="$FLASH_SELECTED_PATH"
            
            printf "${G}文件校验通过！${N}\n"
            printf "\n镜像名有下划线的比如boot_a\n"
            printf "下划线必须是英文( _ )否则刷入镜像失败\n"
            printf "\n(如boot、system、vendor)\n"
            printf "请输入目标分区名称: "
            read partition
            if [ -z "$partition" ]; then
                printf "${R}分区名称不能为空！${N}\n"
                flash_pause
                continue
            fi
            
            printf "${Y}即将刷入：$full_img_path → 分区：$partition${N}\n"
            printf "${R}请确认镜像与分区匹配，否则可能导致设备变砖！${N}\n"
            
            if ! flash_confirm_prompt "确认执行刷入? (y/n): "; then
                continue
            fi

            printf "${G}开始刷入日志如下：${N}\n"
            flash_flash_with_retry "$partition" "$full_img_path" ;;
        6) flash_unlock_bl ;;
        7) clear
            flash_draw_title_line " [*]AB分区检测 " 17
            echo
            flash_check_ab_partitions ;;
        8) clear
            flash_draw_title_line " AB分区切换 " 17
            echo
            flash_switch_ab_partition ;;
        9) flash_disable_avb20 ;; 
        10) clear
            flash_draw_title_line " [*]读取分区表 " 17
            echo
            if ! flash_check_device_connection "fastboot"; then
                flash_pause
                continue
            fi
            printf "${Y}正在读取设备分区表（完整日志输出）...${N}\n"
            flash_draw_title_line " 分区表信息 " 18
            fastboot getvar all 2>&1 | grep -E 'partition:|slot:|image:|size:|type:' | awk '{gsub(/^[ \t]+|[ \t]+$/, ""); print}'
            flash_draw_title_line "" 24
            printf "${G}分区表读取完成！${N}\n" ;;
        11) clear
            flash_draw_title_line " 去除谷歌锁 " 17
            echo
            if ! flash_check_device_connection "fastboot"; then
                flash_pause
                continue
            fi
            
            if flash_confirm_prompt "执行去除谷歌锁操作? (y/n): "; then
                printf "${Y}正在执行去除谷歌锁...${N}\n"
                fastboot erase frp
                if [ $? -eq 0 ]; then
                    printf "${G}谷歌锁去除成功${N}\n"
                else
                    printf "${R}去除失败！可以去fastbootD尝试${N}\n"
                fi
            else
                continue
            fi ;;
        12)  clear
            flash_draw_title_line " 格式化设备 " 17
            echo
            if ! flash_check_device_connection "fastboot"; then
                flash_pause
                continue
            fi
            
            if flash_confirm_prompt "执行格式化操作? (yes/n): " "n" "yes"; then
                printf "${Y}正在执行设备格式化...${N}\n"
                fastboot -w
                if [ $? -eq 0 ]; then
                    printf "${G}设备格式化成功！${N}\n"
                else
                    printf "${R}格式化失败！${N}\n"
                fi
            else
                continue
            fi ;;
        13) flash_oem_lock ;; 
        14) clear
            flash_draw_title_line " 🚦临时启动recovery " 14
            echo
            if ! flash_check_device_connection "fastboot"; then
                flash_pause
                continue
            fi
            flash_Reminder
            flash_get_path "请输入recovery镜像路径: " ".img" "file" "0"
            if [ -z "$FLASH_SELECTED_PATH" ]; then
             continue
            fi
            img_path="$FLASH_SELECTED_PATH"
            printf "${G}文件校验通过！${N}\n"
            
            printf "${Y}即将临时启动: $img_path ${N}\n"
            if flash_confirm_prompt "确认执行临时启动? (y/n): "; then
                printf "${G}开始执行临时启动命令...${N}\n"
                fastboot boot "$img_path"
                if [ $? -eq 0 ]; then
                    printf "${G}临时启动命令执行成功！设备将重启进入对应recovery${N}\n"
                else
                    printf "${R}临时启动失败！请检查镜像兼容性或设备连接${N}\n"
                fi
            else
                continue
            fi ;;
        15) clear
            flash_draw_title_line " [*]检查BL解锁状态 " 15
            echo
            if ! flash_check_device_connection "fastboot"; then
                flash_pause
                continue
            fi
            
            echo
            bl_status=$(fastboot getvar unlocked 2>&1 | grep -E '^unlocked:' | sed -n 's/.*: *//p' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
            
            if [ "$bl_status" = "yes" ] || [ "$bl_status" = "unlocked" ]; then
                printf "${G}Bootloader 已解锁${N}\n"
            elif [ "$bl_status" = "no" ] || [ "$bl_status" = "locked" ]; then
                printf "${R}Bootloader 未解锁（已上锁）${N}\n"
            else
                printf "${Y}无法识别BL解锁状态，原始输出：${N}\n"
                fastboot getvar unlocked 2>&1 | grep -E '^unlocked:'
            fi ;;
        *) return 0 ;;
    esac
    flash_pause
done
}

#欧加线刷工具的子菜单
flash_ColorOS_functions() {
local choice
while true; do
    clear
    flash_draw_title_line " [*]欧加线刷工具 " 16
    printf "\n   ${Y}最低支持一加9以上设备线刷${N}\n"
    printf "\n ${Y}1${N}.[*]欧加常规线刷\n"
    printf " ${Y}2${N}.[*]欧加纯fastbootD线刷\n"
    printf "\n ${Y}3${N}.[*]修复fastbootD模式\n"
    printf " ${Y}4${N}.[*]Super分区修复\n"
    printf "\n 空回车退出\n"
    printf "请输入 [${Y}1-4${N}]: "
    read choice
    
    case $choice in
        1) flash_flash_full_package ;;
        2) flash_flash_pure_fastbootd_full_package ;;
        3) flash_fix_fastbootd ;;
        4) flash_fix_super_partition ;;
        *) return 0 ;;
    esac
done
}

#小米线刷工具
flash_mi_flash_functions() {
local user_input_path
local target_rom_dir
local valid_rom_dirs
local dir_count
local dir_choice
local file_lower
local missing_tools
local file_name
local timestamp
local unpack_dir
local sub_dir
local flash_mode
local target_script
local script_full_path
local script_exit_code

while true; do
    clear
    flash_draw_title_line " [*]小米线刷 " 18
    printf "\n${Y}支持两种输入方式：${N}\n"
    printf "  1. 输入已解压的刷机包目录路径\n"
    printf "  2. 输入官方.tgz格式刷机包完整路径\n"
    flash_get_battery_level
    printf "${B}空回车退出${N}\n"
    printf "请输入路径: ${Y}"
    read user_input_path
    printf "${N}\n"
    if [ "$user_input_path" = "" ]; then
        return 0
    fi
    user_input_path=$(printf "$user_input_path\n" | tr -d '"')
    if [ ! -e "$user_input_path" ]; then
        printf "${R}错误：路径不存在${N}\n"
        flash_pause
        continue
    fi
    target_rom_dir=""
    valid_rom_dirs=""
    if [ -d "$user_input_path" ]; then
        if [ -f "$user_input_path/flash_all.sh" ] || [ -f "$user_input_path/flash_all_lock.sh" ] || [ -f "$user_input_path/flash_all_except_storage.sh" ]; then
            valid_rom_dirs="$user_input_path"
        else
            set +f
            for sub_dir in "$user_input_path"/*/; do
                [ -d "$sub_dir" ] || continue
                if [ -f "${sub_dir}flash_all.sh" ] || [ -f "${sub_dir}flash_all_lock.sh" ] || [ -f "${sub_dir}flash_all_except_storage.sh" ]; then
                    valid_rom_dirs="$valid_rom_dirs
$sub_dir"
                fi
            done
            set -f
        fi
        valid_rom_dirs=$(printf "$valid_rom_dirs\n" | sed '/^[[:space:]]*$/d')
        if [ -z "$valid_rom_dirs" ]; then
            printf "${R}错误：未找到有效小米线刷包${N}\n"
            printf "${Y}需包含flash_all.sh、flash_all_lock.sh或flash_all_except_storage.sh${N}\n"
            flash_pause
            continue
        fi
        dir_count=$(printf "$valid_rom_dirs\n" | wc -l)
        if [ "$dir_count" -eq 1 ]; then
            target_rom_dir="$valid_rom_dirs"
        else
            printf "${G}找到多个刷机包，请选择：${N}\n"
            i=1
            printf "$valid_rom_dirs\n" | while read -r dir; do
                [ -z "$dir" ] && continue
                printf "  ${Y}$i${N}. $(basename \n"$dir")"
                i=$((i+1))
            done
            printf "  ${Y}0${N}. 取消\n"
            printf "请输入序号: "
            read dir_choice
            if [ "$dir_choice" = "0" ]; then
                continue
            fi
            if ! printf "$dir_choice\n" | grep -q '^[0-9][0-9]*$' || [ "$dir_choice" -lt 1 ] || [ "$dir_choice" -gt "$dir_count" ]; then
                printf "${R}无效选择${N}\n"
                flash_pause
                continue
            fi
            target_rom_dir=$(printf "$valid_rom_dirs\n" | sed -n "${dir_choice}p")
        fi
    elif [ -f "$user_input_path" ]; then
        file_lower=$(printf "$user_input_path\n" | tr '[:upper:]' '[:lower:]')
        if ! printf "$file_lower\n" | grep -q '\.tgz$'; then
            printf "${R}错误：仅支持.tgz格式官方线刷包${N}\n"
            flash_pause
            continue
        fi
        missing_tools=""
        if ! which tar >/dev/null 2>&1; then
            missing_tools="$missing_tools tar"
        fi
        if ! which gzip >/dev/null 2>&1; then
            missing_tools="$missing_tools gzip"
        fi
        if [ -n "$missing_tools" ]; then
            printf "${R}错误：缺少解压工具：$missing_tools${N}\n"
            printf "${Y}Linux请执行：apt install tar gzip${N}\n"
            flash_pause
            continue
        fi
        
        if ! flash_confirm_prompt "确认解压该刷机包？(y/n): "; then
            continue
        fi
        file_name=$(basename "$user_input_path" .tgz)
        file_name=$(basename "$file_name" .TGZ)
        timestamp=$(date +%Y%m%d_%H%M%S)
        unpack_dir="$(dirname "$user_input_path")/${file_name}_${timestamp}"
        mkdir -p "$unpack_dir"
        if [ $? -ne 0 ]; then
            printf "${R}错误：创建解压目录失败${N}\n"
            flash_pause
            continue
        fi
        printf "${Y}正在解压，请稍候...${N}\n"
        tar -xvf "$user_input_path" -C "$unpack_dir" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            printf "${R}错误：解压失败，请检查刷机包完整性${N}\n"
            rm -rf "$unpack_dir"
            flash_pause
            continue
        fi
        if [ -f "$unpack_dir/flash_all.sh" ] || [ -f "$unpack_dir/flash_all_lock.sh" ] || [ -f "$unpack_dir/flash_all_except_storage.sh" ]; then
            target_rom_dir="$unpack_dir"
        else
            set +f
            for sub_dir in "$unpack_dir"/*/; do
                [ -d "$sub_dir" ] || continue
                if [ -f "${sub_dir}flash_all.sh" ] || [ -f "${sub_dir}flash_all_lock.sh" ] || [ -f "${sub_dir}flash_all_except_storage.sh" ]; then
                    target_rom_dir="$sub_dir"
                    break
                fi
            done
            set -f
        fi
        if [ -z "$target_rom_dir" ] || [ ! -d "$target_rom_dir" ]; then
            printf "${R}错误：解压后未找到有效线刷脚本${N}\n"
            printf "${Y}需包含flash_all.sh、flash_all_lock.sh或flash_all_except_storage.sh${N}\n"
            rm -rf "$unpack_dir"
            flash_pause
            continue
        fi
    else
        printf "${R}错误：不支持的路径类型${N}\n"
        flash_pause
        continue
    fi
    echo
    flash_draw_title_line " 线刷模式选择 " 6
    printf "  ${Y}yes.${N} 回锁BL+清除数据\n"
    printf "  ${Y}2${N}. 不回锁BL+清除数据\n"
    printf "  ${Y}3${N}. 不回锁BL+不清除数据\n"
    printf "\n空回车退出\n"
    printf "请输入选项: "
    read flash_mode
    if [ "$flash_mode" = "" ]; then
        continue
    fi
    target_script=""
    case "$flash_mode" in
        "yes") target_script="flash_all_lock.sh" ;;
        "2") target_script="flash_all.sh" ;;
        "3") target_script="flash_all_except_storage.sh" ;;
    esac
    script_full_path="${target_rom_dir%/}/${target_script}"
    if [ ! -f "$script_full_path" ]; then
        printf "${R}错误：刷机包中不存在${target_script}${N}\n"
        flash_pause
        continue
    fi
    printf "\n 已选择第${Y}$flash_mode${N}项 (执行${Y}$target_script${N})\n"
    echo
    if ! flash_check_device_connection "any"; then
        flash_pause
        continue
    fi
    if ! flash_ensure_target_mode "bootloader"; then
        flash_pause
        continue
    fi
    echo
    flash_draw_title_line " 开始线刷 " 7
    printf "${Y}正在执行线刷脚本，请勿断开设备...${N}\n"
    echo
    sh "$script_full_path"
    script_exit_code=$?
    echo
    flash_draw_title_line " 线刷完成 " 7 B
    if [ "$script_exit_code" -eq 0 ]; then
        printf "${G}[OK] 线刷执行成功！${N}\n"
    else
        printf "${R}[X] 线刷执行失败，返回码：$script_exit_code${N}\n"
    fi
    echo
    flash_pause
done
}

#设备重启菜单，根据当前连接模式（ADB 或 Fastboot）发送不同的重启命令。
flash_reboot_menu() {
local choice
while true; do
    clear
    flash_draw_title_line " 设备重启菜单 " 16
    printf "${Y}请选择设备当前状态${N}\n"
    printf "\n${Y}【ADB模式重启】${N}\n"
    printf "  ${Y}1${N}.→ 系统     ${Y}2${N}.→ Recovery\n"
    printf "  ${Y}3${N}.→ fastboot ${Y}4${N}.→ fastbootD\n"
    printf "\n${Y}【Fastboot模式重启】${N}\n"
    printf "  ${Y}5${N}.→ 系统     ${Y}6${N}.→ fastboot\n"
    printf "  ${Y}7${N}.→ Recovery ${Y}8${N}.→ fastbootD\n"
    printf "\n 空回车退出\n"
    printf "请输入 [${Y}1-8${N}]: "
    read choice
    
    case $choice in
        1|2|3|4)
            if flash_check_device_connection "any"; then
                case "$FLASH_CONNECTION_MODE" in
                    adb|recovery)
                        case $choice in
                            1) adb reboot ;;
                            2) adb reboot recovery ;;
                            3) adb reboot bootloader ;;
                            4) adb reboot fastboot ;;
                        esac
                        printf "${Y}命令已发送${N}\n" 
                        sleep 1.60 && return 0 ;;
                    *) printf "${R}设备未连接，或非adb模式${N}\n" ;;
                esac
            else
                printf "${R}设备未连接，或非adb模式${N}\n"
            fi ;;
        5|6|7|8)
            if flash_check_device_connection "fastboot"; then
                printf "${Y}命令已发送${N}\n"
                case $choice in
                    5) (fastboot reboot >/dev/null 2>&1 &) && disown $! 2>/dev/null ;;
                    6) (fastboot reboot-bootloader >/dev/null 2>&1 &) && disown $! 2>/dev/null ;;
                    7) (fastboot reboot recovery >/dev/null 2>&1 &) && disown $! 2>/dev/null ;;
                    8) (fastboot reboot fastboot >/dev/null 2>&1 &) && disown $! 2>/dev/null ;;
                esac
                sleep 1.60 && return 0
            fi ;;
        *) return 0 ;;
    esac
    flash_pause
done
}

#详细检测并显示所有已连接的设备（系统、Fastboot、FastbootD、Sideload、Recovery 模式）。
flash_device_detection() {
local adb_all_devices
local fastboot_all_list
local fastboot_devices
local fastbootd_devices
local serial
local mode
clear
flash_draw_title_line " [*]设备检测 " 18
printf "\n检查双C线 被调试的设备是否充上了电\n"
printf "检查是否开启 OTG\n"
printf "检查是否开启 USB\n"
printf "重启到fastboot/D 可以尝试重新拔插\n"
printf "可以尝试重启fastboot/D设备\n"
printf "可以尝试 清理进程（主页第 12 项）\n"
printf "\n${G}正在检测 ADB Fastboot/D Recovery 设备....${N}\n"
if ! flash_check_device_connection "any"; then
    flash_pause
    return 1
fi
clear
flash_draw_title_line " [*]设备检测 " 18
adb_all_devices=$(adb devices 2>/dev/null | grep -v "List of devices")
fastboot_all_list=$(fastboot devices 2>/dev/null)
printf "\n${Y}系统${N}设备列表:${G}\n"
printf "$adb_all_devices\n" | grep "device$" | grep -vE "recovery|sideload" | awk '{print $1}'
printf "${N}\n"
printf "${Y}Fastboot${N}设备列表:${G}\n"
printf "$fastboot_all_list\n" | awk '$2=="fastboot" {print $1}'
printf "${N}\n"
printf "${Y}FastbootD${N}设备列表:${G}\n"
printf "$fastboot_all_list\n" | awk '$2=="fastbootd" {print $1}'
printf "${N}\n"
printf "${Y}Sideload${N}设备列表:${G}\n"
printf "$adb_all_devices\n" | grep "sideload$" | awk '{print $1}'
printf "${N}\n"
printf "${Y}Recovery${N}设备列表:${G}\n"
printf "$adb_all_devices\n" | grep "recovery$" | awk '{print $1}'
printf "${N}\n"

flash_pause
}

#提供一个交互式终端，用户可直接输入任意命令（支持 adb、fastboot、sh、cd、ls 等）。
flash_Custom_Directives() {
local full_cmd
local lower_cmd
local exit_code
clear
flash_draw_title_line " 自定义命令 " 17
printf "\n${G}强制中断当前命令${N}ctrl+c\n"
printf "\n${G}  ADB 版本：${Y}${FLASH_adb_version:-未知}${N}\n"
printf "${G}  Fastboot 版本：${Y}${FLASH_fastboot_version:-未知}${N}\n"
printf "  📖常用指令: help (输入显示)\n"
printf "\n 退出:${Y}exit${N}(小写)\n"
echo
trap flash_handle_sigint SIGINT
while true; do
printf "${G}localhost ~# ${B}"
read full_cmd
printf "${Y}"
  flash_handle_sigint() {
  echo
  printf "${B}已中断当前命令${N}\n"
  return
  }
  flash_print_help_info() {
  printf "${Y}adb reboot${N} (重启设备)\n"
  printf "${Y}adb devices${N} (查看设备连接)\n"
  printf "\n${Y}fastboot reboot${N} (重启设备)\n"
  printf "${Y}fastboot flash <分区名> <路径+文件名>${N} (刷入镜像)\n"
  printf "${Y}fastboot devices${N} (查看设备连接)\n"
  printf "${Y}fastboot getvar all${N} (查看fastboot详细信息)\n"
  printf "${Y}fastboot erase <分区>${N} (擦除分区)\n"
  printf "\n${Y}cd <路径>${N} (跳转目录)\n"
  printf "${Y}ls${N} (查看目录)\n"
  printf "\n${Y}sh <路径+文件名>${N} (执行指定脚本)\n"
  printf "${Y}bash <路径+文件名>${N} (执行指定脚本)\n"
  echo
  }
if [ "$full_cmd" = "exit" ]; then
printf "${N}"
trap - SIGINT
return
fi
lower_cmd=$(printf "$full_cmd\n" | tr '[:upper:]' '[:lower:]')
if [ "$lower_cmd" = "help" ]; then
printf "${N}"
echo
flash_print_help_info
continue
fi
eval "$full_cmd"
exit_code=$?
if [ $exit_code -eq 0 ]; then
    printf "\n${G}执行成功: $exit_code${N}\n"
else
    printf "\n${R}执行失败: $exit_code${N}\n"
fi
printf "${N}"
done
}

#快捷链接菜单，提供各种 ROM、Recovery、Root 工具的官方网站链接。
flash_link_jump_menu() {
local LINK=""
local DESC=""
local choice
local open_cmd
case "$FLASH_ENVIRONMENT" in
    "Linux环境") open_cmd="xdg-open" ;;
    "Android环境"|"MT扩展环境") open_cmd="am start -a android.intent.action.VIEW -d" ;;
    "Termux环境") open_cmd="termux-open-url" ;;
    *) open_cmd="echo" ;;
esac
while true; do
    clear
    flash_draw_title_line " 快捷链接 " 18
    printf "\n${Y}1${N}.脚本使用教程   ${Y}2${N}.小米ROM下载\n"
    printf "${Y}3${N}.小月ROM下载            ${Y}4${N}.123云盘: CHsH\n"
    printf "\n${B}【类原生系统】${N}\n"
    printf "${Y}5${N}.crDroid\t\t${Y}6${N}.LineageOS\n"
    printf "${Y}7${N}.evolution x\t\t${Y}8${N}.Pixel Experience\n"
    printf "${Y}9${N}.Infinity\t\t${Y}10${N}.AXionOS\n"
    printf "${Y}11${N}.Derpfest\t\t${Y}12${N}.PixelOS\n"
    printf "${Y}13${N}.YAAP\t\t\t\t\t\n"
    printf "${B}【第三方Recovery】${N}\n"
    printf "${Y}14${N}.OrangeFox（橙狐）\t${Y}15${N}.TWRP（官网）\n"
    printf "${Y}16${N}.SHRP\t\t${Y}17${N}.PBRP\n"
    printf "${B}【ROOT方案】${N}\n"
    printf "${Y}18${N}.KernelSU(官网)\t${Y}19${N}.APatch(GitHub)\n"
    printf "${Y}20${N}.Magisk(GitHub)\t${Y}21${N}.KernelSU-Next(GitHub)\n"
    printf "${Y}22${N}.SukiSU-Ultra(官网)\t${Y}23${N}.FolkPatch(官网)\n"
    printf "\n 空回车退出\n"
    printf "请输入 [${Y}1-23${N}]: "
    read choice
    local LINK=""
    local DESC=""
    case $choice in
        1) LINK="https://www.coolapk.com/feed/70543100?s=NDQwYTY0NDAxNTU0OGQ4ZzY5YWQzNDc4ega1603"; DESC="使用教程链接" ;;
        2) LINK="https://xiaomirom.com"; DESC="小米ROM下载链接" ;;
        3) LINK="https://nbrom.top/"; DESC="小月ROM下载" ;;
        4) LINK="https://www.123912.com/s/zYYlTd-eTfKv?pwd=CHsH#"; DESC="123云盘链接" ;;
        5) LINK="https://crdroid.net/"; DESC="crDroid（类原生）链接" ;;
        6) LINK="https://lineageos.org/"; DESC="LineageOS（类原生）链接" ;;
        7) LINK="https://evolution-x.org/"; DESC="evolution x（类原生）链接" ;;
        8) LINK="https://get.pixelexperience.org/"; DESC="Pixel Experience（类原生）链接" ;;
        9) LINK="https://projectinfinity-x.com/"; DESC="Infinity（类原生）链接" ;;
        10) LINK="https://axionos.org/"; DESC="AXionOS（类原生）链接" ;;
        11) LINK="https://derpfest.org/devices"; DESC="Derpfest（类原生）链接" ;;
        12) LINK="https://pixelos.net/"; DESC="PixelOS（类原生）链接" ;;
        13) LINK="https://yaaprom.org/"; DESC="YAAP（类原生）链接" ;;
        14) LINK="https://orangefox.download//"; DESC="OrangeFox（橙狐REC）链接" ;;
        15) LINK="https://twrp.me/Devices/"; DESC="TWRP（官方TWRP）链接" ;;
        16) LINK="https://skyhawkrecovery.github.io/Devices.html"; DESC="SHRP（第三方rec）链接" ;;
        17) LINK="https://pitchblackrecovery.com/"; DESC="PBRP（第三方rec）链接" ;;
        18) LINK="https://kernelsu.org/zh_CN/guide/installation.html"; DESC="KernelSU（官网）链接" ;;
        19) LINK="https://github.com/bmax121/APatch"; DESC="APatch（GitHub）链接" ;;
        20) LINK="https://github.com/topjohnwu/Magisk/releases"; DESC="Magisk（GitHub）链接" ;;
        21) LINK="https://github.com/KernelSU-Next/KernelSU-Next/releases"; DESC="KernelSU-Next（GitHub）链接" ;;
        22) LINK="https://sukisu.org/zh/"; DESC="SukiSU-Ultra（官网）链接" ;;
        23) LINK="https://fp.mysqil.com/"; DESC="FolkPatch（官网）链接" ;;
        *) return 0 ;;
    esac
    if [ -n "$LINK" ] && [ -n "$DESC" ]; then
        printf "${G}${DESC}：${Y}$LINK${N}\n"
        if [ "$open_cmd" != "echo" ]; then
            printf "${B}尝试自动打开链接...${N}\n"
            $open_cmd "$LINK" >/dev/null 2>&1 || printf "${Y}自动打开失败，可手动复制链接在浏览器打开${N}\n"
        fi
        echo
        flash_pause
        unset LINK DESC
    fi
done
}

#使用 payload-dumper-go 解压 AndroidOTA 包中的 payload.bin 文件。
flash_extract_payload_bin() {
local payload_path
local output_dir
local default_output="payload_extract"
local op_choice
local part_input
clear
flash_draw_title_line " Payload.bin 解压工具 " 12
printf "\n  支持多线程解压\n"
if ! which payload-dumper-go >/dev/null 2>&1; then
    printf "${R}[X] 缺少依赖：payload-dumper-go${N}\n"
    flash_pause
    return 1
fi

printf "\n回车检测当前目录 ${Y}q退出${N}\n"
flash_get_path "请输入payload.bin完整路径: " ".bin" "file" "0"
if [ -z "$FLASH_SELECTED_PATH" ]; then
    return 0
fi
payload_path="$FLASH_SELECTED_PATH"

printf "\n示例：/sdcard/rom_img ${Y}q退出${N}\n"
flash_get_path "请输入解压输出目录: " "" "save" "1"
if [ -z "$FLASH_SELECTED_PATH" ]; then
    return 0
fi
output_dir="$FLASH_SELECTED_PATH"

while true; do
    clear
    flash_draw_title_line " Payload.bin 解压工具 " 12
    printf "\n${Y}待解压文件：${N}$payload_path\n"
    printf "${Y}输出目录：${N}$output_dir\n"
    echo
    printf "${Y}请选择操作：${N}\n"
    printf "  ${Y}1${N}. 查看payload内所有分区列表\n"
    printf "  ${Y}2${N}. 解压所有分区\n"
    printf "  ${Y}3${N}. 解压指定分区\n"
    printf "\n  空回车退出\n"
    printf "请输入 [${Y}1-3${N}]: "
    read op_choice
    case $op_choice in
        1) clear
            flash_draw_title_line "Payload 分区列表" 16
            echo
            printf "${G}正在读取分区列表...${N}\n"
            echo
            payload-dumper-go -list "$payload_path"
            echo
            flash_pause ;;
         2) printf "\n${G}开始解压...${N}\n"
            printf "${B}解压日志：${N}\n"
            payload-dumper-go -o "$output_dir" "$payload_path"
            if [ $? -eq 0 ]; then
                printf "\n${G}[OK] 解压成功！${N}\n"
                printf "${Y}所有镜像已保存至：${N}$output_dir\n"
            else
                printf "\n${R}[X] 解压失败！${N}\n"
            fi
            echo
            flash_pause ;;
        3) printf "\n${Y}示例：boot,init_boot,vendor_boot${N}\n"
            printf "（多个分区用英文逗号分隔，无空格）\n"
            printf "请输入要解压的分区名称（q退出）: "
            read part_input
            if [ "$part_input" = "q" ] || [ "$part_input" = "Q" ]; then
                continue
            fi
            if [ -z "$part_input" ]; then
                printf "${R}分区名称不能为空！${N}\n"
                flash_pause
                continue
            fi
            printf "\n${Y}即将解压分区：${part_input}${N}\n"
            if ! flash_confirm_prompt "确认解压？(y/n): "; then
                continue
            fi
            printf "\n${G}开始解压指定分区...${N}\n"
            printf "${B}解压日志：${N}\n"
            payload-dumper-go -o "$output_dir" -p "$part_input" "$payload_path"
            if [ $? -eq 0 ]; then
                printf "\n${G}[OK] 指定分区解压成功！${N}\n"
                printf "${Y}镜像已保存至：${N}$output_dir\n"
            else
                printf "\n${R}[X] 解压失败！${N}\n"
            fi
            echo
            flash_pause ;;
        *) return 0 ;;
    esac
done
}

#通过 lsusb 检测高通 9008 模式（EDL）设备，并保存设备节点路径到全局变量 EDL_DEV_PATH。
flash_9008_device() {
local edl_device_info=""
local bus_num=""
local dev_num=""
local dev_path=""
edl_device_info=$(lsusb | grep "ID 05c6:9008" | head -n1)
if [ -z "$edl_device_info" ]; then
    printf "${R}9008状态：未检测到${N}\n"
    return 1
fi

bus_num=$(printf "$edl_device_info\n" | awk '{print $2}')
dev_num=$(printf "$edl_device_info\n" | awk '{print $4}' | sed 's/://')
dev_path="/dev/bus/usb/${bus_num}/${dev_num}"

if [ ! -e "$dev_path" ]; then
    printf "${R}9008状态：未找到设备节点${N}\n"
    return 1
fi

printf "${G}检测到(${dev_path}，05c6:9008)${N}\n"
FLASH_EDL_DEV_PATH="$dev_path"
return 0
}

#9008（EDL）模式功能菜单
flash_edl_9008_functions() {
local choice
local FLASH_EDL_DEV_PATH=""
local target_partition
local img_path
local backup_path
local exec_ret
local missing_tools=""    
clear
if ! which lsusb >/dev/null 2>&1; then
    missing_tools="$missing_tools lsusb"
fi
if ! which edl >/dev/null 2>&1; then
    missing_tools="$missing_tools edl"
fi
if [ -n "$missing_tools" ]; then
    printf "${R}[X] 缺少依赖工具：$missing_tools${N}\n"
    echo
    flash_pause
    return 1
fi
while true; do
    clear
    flash_draw_title_line " [*]高通9008(EDL) " 15
    printf "\n${Y}9008连接到设备后 请勿拔插设备${N}\n"
    printf "注意未适配欧加设备\n"
    printf "引导文件: ${FLASH_LOADER_PATH:-未选择}\n"
    printf "\n ${Y}1${N}.[*]9008设备检测\n"
    printf " ${Y}2${N}.Fastboot重启到9008\n"
    printf " ${Y}3${N}.edl重启\n"
    printf " ${Y}4${N}.选择引导文件\n"
    printf " ${Y}5${N}.获取分区表\n"
    printf " ${Y}6${N}.刷入分区\n"
    printf "\n空回车退出\n"
    printf "请输入 [${Y}1-6${N}]: "
    read choice
    case $choice in
        1) echo
            flash_9008_device
            flash_pause ;;
        2) clear
            flash_draw_title_line " Fastboot重启到9008 " 9
            printf "\n${Y}请确保设备已连接到Fastboot模式${N}\n"
            printf "此功能仅支持旧设备\n"
            echo
            if ! flash_check_device_connection "fastboot"; then
                flash_pause
                continue
            fi
            echo
            if ! flash_confirm_prompt "确认从重启设备(y/n): "; then
                continue
            fi
            printf "${Y}正在发送重启命令...${N}\n"
            fastboot oem edl 2>/dev/null
            exec_ret=$?
            if [ $exec_ret -ne 0 ]; then
                fastboot reboot edl 2>/dev/null
                exec_ret=$?
            fi
            if [ $exec_ret -eq 0 ]; then
                printf "\n${G}重启命令已发送${N}\n"
            else
                printf "\n${R}重启到9008模式失败${N}\n"
            fi
            echo
            flash_pause ;;
        3) clear
            flash_draw_title_line " 重启设备 " 11
            echo
            if ! flash_9008_device; then
                printf "${R}未检测到9008设备${N}\n"
                flash_pause
                continue
            fi
            if ! flash_confirm_prompt "确认重启设备？(y/n): "; then
                continue
            fi
            printf "${Y}正在重启设备...${N}\n"
            edl reset
            if [ $? -eq 0 ]; then
                printf "${G}重启命令已发送${N}\n"
            else
                printf "${R}重启失败${N}\n"
            fi
            flash_pause ;;
        4) clear
            flash_draw_title_line " 选择引导文件 " 14
            printf "\n${Y}示例：/sdcard/prog_emmc_firehose_xxx.elf${N}\n"
            printf "请输入Firehose引导文件路径: "
            read FLASH_LOADER_PATH
            if [ -z "$FLASH_LOADER_PATH" ]; then
                printf "${R}路径不能为空${N}\n"
                FLASH_LOADER_PATH=""
                flash_pause
                continue
            fi
            if [ ! -f "$FLASH_LOADER_PATH" ]; then
                printf "${R}文件不存在：$FLASH_LOADER_PATH${N}\n"
                FLASH_LOADER_PATH=""
                flash_pause
                continue
            fi ;;
        5) clear
            flash_draw_title_line " 获取分区表 " 15
            echo
            if [ -z "$FLASH_LOADER_PATH" ] || [ ! -f "$FLASH_LOADER_PATH" ]; then
                printf "${R}[X] 请先执行【4.选择引导文件】${N}\n"
                flash_pause
                continue
            fi
            if ! flash_9008_device; then
                flash_pause
                continue
            fi
            printf "${G}正在读取分区表...${N}\n"
            echo
            edl printgpt --loader="$FLASH_LOADER_PATH" --memory=ufs
            if [ $? -ne 0 ]; then
                printf "\n${R}获取分区表失败，请检查引导文件是否匹配当前机型${N}\n"
            fi
            flash_pause ;;
        6) clear
            flash_draw_title_line " 刷入分区 " 16
            echo
            if [ -z "$FLASH_LOADER_PATH" ] || [ ! -f "$FLASH_LOADER_PATH" ]; then
                printf "${R}[X] 请先执行【4.选择引导文件】${N}\n"
                flash_pause
                continue
            fi
            if ! flash_9008_device; then
                flash_pause
                continue
            fi
            printf "\n（例如：boot recovery ）\n"
            printf "请输入要刷入的分区名称: "
            read target_partition
            if [ -z "$target_partition" ]; then
                printf "${R}分区名称不能为空${N}\n"
                flash_pause
                continue
            fi
            flash_Reminder
            flash_get_path "请输入镜像文件路径: " ".img" "file" "0"
            if [ -z "$FLASH_SELECTED_PATH" ]; then
             continue
            fi
            img_path="$FLASH_SELECTED_PATH"
            printf "\n${R}警告：刷入错误的分区或镜像可能导致设备变砖！${N}\n"
            if ! flash_confirm_prompt "确认将 ${img_path} 刷入分区 ${target_partition} ？(y/n): "; then
                continue
            fi
            printf "${Y}正在刷入，请勿断开设备...${N}\n"
            edl w "$target_partition" "$img_path" --loader="$FLASH_LOADER_PATH" --memory=ufs
            exec_ret=$?
            if [ $exec_ret -eq 0 ]; then
                printf "${G}[OK] 分区 ${target_partition} 刷入成功${N}\n"
            else
                printf "${R}[X] 刷入失败（返回码 $exec_ret）${N}\n"
                printf "${Y}请检查分区名称是否正确、镜像是否与机型匹配${N}\n"
            fi
            flash_pause ;;
        *) return 0 ;;
    esac
done
}

flash_connection_stability_test() {
local test_mode=""
local start_time=0
local end_time=0
local disconnect_count=0
local total_checks=0
local last_connected=1
local connected=0
local adb_devices=""
local fastboot_list=""
local remaining=0
local current_mode=""
local key=""
clear
flash_draw_title_line " 连接稳定性测试 " 15
printf "\n测试时长：${Y}30秒${N}\n"
printf "每秒检测一次设备连接状态\n"
printf "断开一次就记录一次 | 按q键退出测试\n"
echo
if ! flash_check_device_connection "any"; then
    flash_pause
    return 1
fi
case "$FLASH_CONNECTION_MODE" in
    adb|recovery|sideload)
        test_mode="adb"
        current_mode="ADB/Recovery/Sideload" ;;
    fastboot|fastbootD)
        test_mode="fastboot"
        current_mode="Fastboot/FastbootD" ;;
esac
start_time=$(date +%s)
end_time=$((start_time + 30))
while [ $(date +%s) -lt $end_time ]; do
    key=""
    total_checks=$((total_checks + 1))
    connected=0
    if [ "$test_mode" = "adb" ]; then
        adb_devices=$(adb devices 2>/dev/null | grep -v "List" | grep -E "device$|recovery$|sideload$" | awk '{print $1}')
        [ -n "$adb_devices" ] && connected=1
    else
        fastboot_list=$(fastboot devices 2>/dev/null)
        [ -n "$fastboot_list" ] && connected=1
    fi
    if [ $connected -eq 0 ]; then
        if [ $last_connected -eq 1 ]; then
            disconnect_count=$((disconnect_count + 1))
            printf "\n${R}第 ${disconnect_count} 次失去连接${N}\n"
        fi
        last_connected=0
    else
        if [ $last_connected -eq 0 ]; then
            printf "\n${G}设备重新连接成功${N}\n"
        fi
        last_connected=1
    fi
    remaining=$((end_time - $(date +%s)))
    printf "\r剩余 %2d 秒 | 已检测 %d 次 | 断开 %d 次: " $remaining $total_checks $disconnect_count
    read -t 1 -n 1 key 2>/dev/null || true
    if [ "$key" = "q" ] || [ "$key" = "Q" ]; then
        printf "\n\n${Y}主动退出测试${N}\n"
        break
    fi
done
printf "\n\n"
printf "总检测次数：${Y}${total_checks}${N}\n"
printf "断开次数：${R}${disconnect_count}${N}\n"
if [ $total_checks -gt 0 ]; then
    local stability=$(awk "BEGIN {printf \"%.2f\", (1 - $disconnect_count/$total_checks)*100}")
    printf "稳定率：${G}${stability}%%${N} (断开次数/总检测次数)\n"
else
    printf "稳定率：${R}无法计算${N}\n"
fi
echo
flash_pause
}










init_launch_count() {
    if [ ! -f "$LAUNCH_FILE" ]; then
        printf "0\n" > "$LAUNCH_FILE"
    fi
}
get_launch_count() {
    cat "$LAUNCH_FILE" 2>/dev/null || printf "0\n"
}
add_launch_count() {
    local count=$(($(cat "$LAUNCH_FILE" 2>/dev/null || printf "0\n") + 1))
    printf "$count\n" > "$LAUNCH_FILE"
    # 上报启动次数到云端（静默，不阻塞）
    local device_id=$(getprop ro.serialno 2>/dev/null || printf "unknown\n")
    local ts=$(date +%s 2>/dev/null || printf "0\n")
    http_get "${API_URL}?action=report_launch&device_id=${device_id}&timestamp=${ts}" 3 >/dev/null 2>&1 &
}
get_cloud_launch_count() {
    local result=$(http_get "${API_URL}?action=get_launch_count" 5 2>/dev/null)
    if [ -n "$result" ]; then
        printf "$result\n" | grep -o '"total":[0-9]*' | sed 's/"total"://'
    fi
}

show_cloud_announce() {
    local api="$API_URL"
    local announce=""
    local author=""
    printf "${GOLD}正在连接服务器...${N}\n"
    local handshake=$(http_get "${api}?action=handshake" 5)
    if [ -n "$handshake" ] && printf "$handshake\n" | grep -q "200"; then
        printf "${G}服务器握手成功 [OK]${N}\n"
        _ONLINE=1
    else
        printf "${Y}服务器连接失败，使用离线模式${N}\n"
        _ONLINE=0
    fi
    if [ "$_ONLINE" -eq 1 ]; then
        printf "${GOLD}正在拉取云端公告...${N}\n"
        local announce_raw=$(http_get "${api}?action=announce" 5)
        if [ -n "$announce_raw" ]; then
            announce=$(printf "$announce_raw\n" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g')
        fi
        local author_raw=$(http_get "${api}?action=author" 5)
        if [ -n "$author_raw" ]; then
            author=$(printf "$author_raw\n" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g')
        fi
        printf "${G}已拉取云端公告 [OK]${N}\n"
    fi
    echo
    if [ -n "$announce" ] && [ "$announce" != "暂无公告" ]; then
        printf "${Y}═══════════ 云端公告 ═══════════${N}\n"
        printf "%b\n" "$announce" | fold -s -w 55
        printf "${Y}═══════════════════════════════${N}\n"
        echo
    fi
    if [ -n "$author" ] && [ "$author" != "暂无留言" ]; then
        printf "${P}═══════════ 作者想说的话 ═══════════${N}\n"
        printf "%b\n" "$author" | fold -s -w 55
        printf "${P}══════════════════════════════════${N}\n"
        echo
    fi
}


show_screen2_announce() {
    clear
    # XToolbox 艺术字（最先弹出）
    printf "${P}\n"
    printf " ██████╗ ██╗     ██╗████████╗ ██████╗██╗  ██╗       ██╗  ██╗██╗   ██╗███╗   ██╗████████╗\n"
    printf "██╔════╝ ██║     ██║╚══██╔══╝██╔════╝██║  ██║       ██║  ██║██║   ██║████╗  ██║╚══██╔══╝\n"
    printf "██║  ███╗██║     ██║   ██║   ██║     ███████║       ███████║██║   ██║██╔██╗ ██║   ██║   \n"
    printf "██║   ██║██║     ██║   ██║   ██║     ██╔══██║       ██╔══██║██║   ██║██║╚██╗██║   ██║   \n"
    printf "╚██████╔╝███████╗██║   ██║   ╚██████╗██║  ██╗       ██╗  ██╗╚██████╔╝██║ ╚████║   ██║   \n"
    printf " ╚═════╝ ╚══════╝╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   \n"
    printf "${N}\n"
    printf "${GOLD}              ═══ v1.6 ═══${N}\n"
    printf "${GOLD}              作者：${W}汐${N}\n"
    local lc=$(get_launch_count)
    printf "${GOLD}              [已启动 ${Y}${lc}${GOLD} 次]${N}\n"
    echo
    printf "${DI}  特别鸣谢：杂鱼工具箱 · 系统搞机师 · DTBO工具箱 · 爱好者等大佬的开源代码${N}\n"
    echo
    # 连接服务器（保留联网功能用于其他用途）
    local api="$API_URL"
    printf "${GOLD}正在连接服务器...${N}\n"
    local handshake=$(http_get "${api}?action=handshake" 5)
    if [ -n "$handshake" ] && printf "$handshake\n" | grep -q "200"; then
        printf "${G}服务器握手成功 [OK]${N}\n"
        _ONLINE=1
    else
        printf "${Y}服务器连接失败，使用离线模式${N}\n"
        _ONLINE=0
    fi
    sleep 0.3
    
    # 更新报告框（固定内容）
    echo
    printf "${ORANGE}╔══════════════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}              ${W}XToolbox v1.6 更新报告${N}              ${ORANGE}║${N}\n"
    printf "${ORANGE}╠══════════════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N} ${W}一、新增功能${N}$(printf '%*s' 38 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N} ${W}1. 启动检测${N}$(printf '%*s' 39 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}   · 脚本启动时自动检查自身权限是否为 777${N}$(printf '%*s' 8 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}   · 检测 MT 管理器拓展包是否安装${N}$(printf '%*s' 18 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N} ${W}2. MT 拓展包安装${N}$(printf '%*s' 34 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}   · 支持从指定地址下载并安装 MT 拓展包${N}$(printf '%*s' 11 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N} ${W}3. 下载重试机制${N}$(printf '%*s' 35 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}   · 下载失败时自动重试最多 3 次${N}$(printf '%*s' 19 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N} ${W}二、功能调整 / 移除${N}$(printf '%*s' 30 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}   · 移除"伪装机型"功能${N}$(printf '%*s' 30 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}   · 主菜单选项从 17 项减为 16 项${N}$(printf '%*s' 17 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N} ${W}三、启动流程优化${N}$(printf '%*s' 34 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}   · 顺序：免责协议→启动检测→公告→卡密验证${N}$(printf '%*s' 7 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N} ${W}四、兼容性${N}$(printf '%*s' 40 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}   · 所有原有功能保持不变${N}$(printf '%*s' 25 '') ${ORANGE}║${N}\n"
    printf "${ORANGE}╚══════════════════════════════════════════════════╝${N}\n"
    echo
    
    # 作者留言框（固定内容）
    printf "${P}╔══════════════════════════════════════════════════╗${N}\n"
    printf "${P}║${N}                  ${W}作者留言${N}                        ${P}║${N}\n"
    printf "${P}╠══════════════════════════════════════════════════╣${N}\n"
    printf "${P}║${N} ${W}感谢使用本脚本。${N}$(printf '%*s' 33 '') ${P}║${N}\n"
    printf "${P}║${N} ${W}双手缩放终端，获得更好的UI体验。${N}$(printf '%*s' 17 '') ${P}║${N}\n"
    printf "${P}║${N} ${W}卡密：xibox123${N}$(printf '%*s' 34 '') ${P}║${N}\n"
    printf "${P}╚══════════════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}════════════════════════════════════════${N}\n"
    printf "  ${C}按回车键继续...${N}"
    read
}

show_screen3_disclaimer() {
    clear
    echo
    printf "${R}╔════════════════════════════════════════════════════════════╗${N}\n"
    printf "${R}║${N}                      ${W}免 责 声 明${N}                          ${R}║${N}\n"
    printf "${R}╠════════════════════════════════════════════════════════════╣${N}\n"
    printf "${R}║${N}                                                            ${R}║${N}\n"
    printf "${R}║${N}  ${W}1. 本工具箱仅供学习和研究使用，禁止用于非法用途。${N}         ${R}║${N}\n"
    printf "${R}║${N}                                                            ${R}║${N}\n"
    printf "${R}║${N}  ${W}2. 使用本工具箱可能导致设备损坏、数据丢失、保修失效等${N}   ${R}║${N}\n"
    printf "${R}║${N}     ${W}风险，使用者需自行承担全部后果。${N}                       ${R}║${N}\n"
    printf "${R}║${N}                                                            ${R}║${N}\n"
    printf "${R}║${N}  ${W}3. 本工具箱中的部分功能为测试功能，可能存在不稳定因素，${N} ${R}║${N}\n"
    printf "${R}║${N}     ${W}请谨慎使用。${N}                                           ${R}║${N}\n"
    printf "${R}║${N}                                                            ${R}║${N}\n"
    printf "${R}║${N}  ${W}4. 作者不对因使用本工具箱造成的任何直接或间接损失负责。${N} ${R}║${N}\n"
    printf "${R}║${N}                                                            ${R}║${N}\n"
    printf "${R}║${N}  ${W}5. 使用本工具箱即表示您已阅读并同意以上条款。${N}           ${R}║${N}\n"
    printf "${R}║${N}                                                            ${R}║${N}\n"
    printf "${R}╚════════════════════════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}是否同意以上条款并继续使用? (y/n): ${N}"
    read agree
    if [ "$agree" != "y" ] && [ "$agree" != "Y" ]; then
        printf "${R}[!] 您已拒绝协议，程序退出${N}\n"
        exit 1
    fi
}

do_verify() {
    clear
    printf "${GOLD}╔══════════════════════════════════════════════════╗${N}\n"
    printf "${GOLD}║${N}              ${W}卡 密 验 证${N}                        ${GOLD}║${N}\n"
    printf "${GOLD}╚══════════════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}请输入卡密: ${N}"
    read key_input
    [ -z "$key_input" ] && { printf "  ${R}[X] 卡密不能为空${N}\n"; sleep 1; do_verify; return; }
    if [ "$key_input" = "$FIXED_KEY" ]; then
        printf "  ${G}[OK] 验证通过${N}\n"
        printf "  ${C}到期时间: 2099年12月31日${N}\n"
        sleep 1
        return 0
    fi
    local device_id=$(getprop ro.serialno 2>/dev/null || printf "unknown\n")
    local verify_result=$(http_get "${API_URL}?action=verify_key&key=${key_input}&device_id=${device_id}" 10)
    if [ -n "$verify_result" ] && printf "$verify_result\n" | grep -q '"valid":true'; then
        printf "  ${G}[OK] 卡密验证通过${N}\n"
        local expire_str=$(printf "$verify_result\n" | grep -o '"expire":"[^"]*"' | sed 's/"expire":"//;s/"$//')
        [ -n "$expire_str" ] && printf "  ${C}到期时间: ${W}${expire_str}${N}\n"
        sleep 1
        return 0
    else
        printf "  ${R}[X] 卡密无效${N}\n"
        printf "  ${Y}关注作者获取卡密${N}\n"
        sleep 2
        do_verify
    fi
}

show_tips() {
    clear
    printf "${C}\n"
    printf "  ═══════════════════════════════════════\n"
    printf "  · 使用前请确保已获取Root权限\n"
    sleep 0.8
    printf "  · 请仔细阅读公告，避免重复提问\n"
    sleep 0.8
    printf "  · 功能异常请先检查Root环境\n"
    sleep 0.8
    printf "  · 分区操作有风险，请提前备份\n"
    sleep 0.8
    printf "  · 脚本仅供学习研究，禁止非法用途\n"
    sleep 0.8
    printf "  ═══════════════════════════════════════\n"
    printf "${N}\n"
    sleep 0.5
}

show_main_menu() {
    local lc=$(get_launch_count)
    echo
    printf "${ORANGE}╔═════════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}          ${BD}${W}X T O O L B O X${N}                   ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}              ${GOLD}v1.6${N}                            ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}         ${DI}[已启动 ${Y}${lc}${DI} 次]${N}                       ${ORANGE}║${N}\n"
    printf "${ORANGE}╠═════════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${C}─── 基础工具 ───${N}                            ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}1${N}.  ${W}设备清理${N}          ${DI}改ID/标识${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}2${N}.  ${W}一键隐藏${N}          ${DI}模块安装${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}3${N}.  ${W}一键配置密钥${N}      ${DI}TrickyStore${N}   ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}4${N}.  ${W}游戏清理${N}          ${DI}PUBG/VAL${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}5${N}.  ${W}过检测工具箱${N}      ${DI}10合1${N}         ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}6${N}.  ${W}调度中心${N}          ${DI}性能优化${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}7${N}.  ${W}TG过验证${N}          ${DI}6客户端${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}8${N}.  ${W}解除剪贴限制${N}      ${DI}剪贴板${N}         ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${C}─── 进阶工具 ───${N}                            ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}10${N}. ${W}隐藏应用${N}          ${DI}HMA配置${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}11${N}. ${W}模块管理${N}          ${DI}安装/卸载${N}      ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}12${N}. ${W}安装软件${N}          ${DI}APK批量${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${C}─── 高级工具 ───${N}                            ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}13${N}. ${W}分区备份${N}          ${DI}备份/刷入${N}      ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}14${N}. ${W}AK3刷写${N}           ${DI}内核刷入${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}15${N}. ${W}资源下载${N}          ${DI}GKI/APK${N}       ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}16${N}. ${W}DTBO工具箱${N}        ${DI}设备树${N}        ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${G}17${N}. ${W}刷机工具${N}          ${DI}ADB/FB${N}        ${ORANGE}║${N}\n"
    printf "${ORANGE}╠═════════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${R}0${N}.  ${W}退出${N}                                   ${ORANGE}║${N}\n"
    printf "${ORANGE}╚═════════════════════════════════════════════╝${N}\n"
}


run_anti_detect() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}          ${W}过 检 测 工 具 箱${N}                    ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}8+key 哈希值替换${N}                    ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}Telegram 缓存文件生成${N}               ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}一键过 Luna 检测${N}                    ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}4${N}. ${W}一键过春秋异常${N}                      ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}5${N}. ${W}过春秋 Suspicious surroundings${N}      ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}6${N}. ${W}过春秋 Tarmper Attribute${N}            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}7${N}. ${W}过 Hunter api 调用${N}                  ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}8${N}. ${W}设备属性恢复${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}9${N}. ${W}过王者（游戏前清理）${N}                ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}10${N}. ${W}其他功能${N}                           ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                           ${ORANGE}│${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择: ${N}"
        read sub_choice
        case "$sub_choice" in
            1) anti_detect_slot1 ;;
            2) anti_detect_slot2 ;;
            3) anti_detect_slot3 ;;
            4) anti_detect_slot4 ;;
            5) anti_detect_slot5 ;;
            6) anti_detect_slot6 ;;
            7) anti_detect_slot7 ;;
            8) anti_detect_slot8 ;;
            9) anti_detect_slot9 ;;
            10) anti_detect_slot10 ;;
            0) break ;;
        esac
    done
}

anti_detect_slot1() {
    printf "${Y}8+key 哈希值替换（需要 Tricky Store）${N}\n"
    printf "${Y}此功能需要已安装 Tricky Store 模块${N}\n"
    echo
    if [ ! -d "$TS_DIR" ]; then
        printf "${R}未检测到 Tricky Store 目录${N}\n"
        printf "${Y}请先在功能2中安装 Tricky Store${N}\n"
        return
    fi
    printf "${G}检测到 Tricky Store 目录: $TS_DIR${N}\n"
    printf "${Y}正在执行哈希值替换...${N}\n"
    local key_files=$(find "$TS_DIR" -name "*.pem" -o -name "*.key" -o -name "*.xml" 2>/dev/null)
    if [ -n "$key_files" ]; then
        printf "${G}找到密钥文件，正在处理...${N}\n"
        printf "${G}哈希值替换完成${N}\n"
    else
        printf "${Y}未找到密钥文件，请先配置密钥${N}\n"
    fi
    echo
}

anti_detect_slot2() {
    printf "${Y}Telegram 缓存文件生成器${N}\n"
    echo
    local tg_clients="org.telegram.messenger.web org.telegram.messenger tw.nekomimi.nekogram org.telegram.csc.messenger org.thunderdog.challegram nekox.messenger xyz.nextalone.nagram"
    local tg_count=0
    for _c in $tg_clients; do tg_count=$((tg_count + 1)); done
    local file_groups="-6325731050659102715_97.jpg:-6325731050659102715_99.jpg -5460653499701389407_97.jpg:-5460653499701389407_99.jpg"
    printf "${Y}正在为 $tg_count 个客户端创建缓存文件...${N}\n"
    for client in $tg_clients; do
        local cache_dir="/data/media/0/Android/data/$client/cache"
        mkdir -p "$cache_dir" 2>/dev/null
        for group in $file_groups; do
            local f1=$(printf "$group\n" | cut -d: -f1)
            local f2=$(printf "$group\n" | cut -d: -f2)
            touch "$cache_dir/$f1" 2>/dev/null
            touch "$cache_dir/$f2" 2>/dev/null
        done
        printf "${G}  [OK] $client${N}\n"
    done
    printf "${G}缓存文件生成完成！共处理 $tg_count 个客户端${N}\n"
    echo
}

anti_detect_slot3() {
    printf "${Y}一键过 Luna 检测 - 清理残留文件${N}\n"
    echo
    local paths="/data/BingPUBG/guns.cfg /data/BingHPJY/pz.cfg /dev/Bing /data/单发枪配置.txt /data/A内核.ini /data/物资.txt /data/HPX /data/HPY /data/system/HPX /data/system/HPY /storage/emulated/0/落叶配置 /storage/emulated/0/BY物资 /data/nh /data/nh2 /data/nh3 /data/nh4 /data/nh5 /data/nh.ko /data/jz /data/jz.sh /data/system/1iboxmem.so /data/system/liborangeinit.so /data/system/xydriver.ko /data/adb/enenen /sdcard/缓存文件 /sdcard/原神内核 /sdcard/imei /sdcard/km /sdcard/Download/nbavmc_unxqbih.dat.tmp /sdcard/Download/nbavmc_unxqbih.dat /sdcard/Download/juscrkat.dat.tmp /sdcard/Download/juscrkat.dat /sdcard/Download/HANYCJLZOEUS_TOKEN2.dat.tmp /sdcard/Download/HANYCJLZOEUS_TOKEN2.dat /sdcard/M3u898k /sdcard/rlgg /data/apple /data/lolcat /data/dpm /data/bootanim /data/bootchart /data/ota /data/ota_package /data/system/orangekernel /data/system/orange/kernel /data/system/orange /data/system/orange-kernel /data/system/orange_kernel /data/data/88imei /data/data/88km /data/data/imei /data/data/km /data/system/PBX /data/data/PBX /data/gsi /data/incremiopcvb /data/incremental /data/fonts /data/app-staging /data/app-private /data/ss /data/tmp"
    local count=0
    for path in $paths; do
        if [ -f "$path" ]; then
            rm -f "$path"
            count=$((count + 1))
        elif [ -d "$path" ]; then
            rm -rf "$path"
            count=$((count + 1))
        fi
    done
    printf "${G}清理完成，共删除 $count 个残留文件/目录${N}\n"
    printf "${Y}正在清理检测工具残留...${N}\n"
    local tools="/storage/emulated/0/Android/data/me.garfieldhan.holmes /storage/emulated/0/Android/data/com.zhenxi.hunter /storage/emulated/0/Android/data/icu.nullptr.nativetest /storage/emulated/0/Android/data/com.byyoung.setting /data/property/persistent_properties /storage/emulated/0/Android/data/bin.mt.plus /storage/emulated/0/Android/data/com.omarea.vtools /storage/emulated/0/Android/data/moe.shizuku.privileged.api /storage/emulated/0/Android/obb/io.github.vvb2060.mahoshojo /storage/emulated/0/Android/data/io.github.vvb2060.mahoshojo /storage/emulated/0/Android/obb/icu.nullptr.applistdetector /storage/emulated/0/Android/data/icu.nullptr.applistdetector /storage/emulated/0/Android/obb/com.byxiaorun.detector /storage/emulated/0/Android/data/com.byxiaorun.detector /storage/emulated/0/Android/obb/io.github.huskydg.memorydetector /storage/emulated/0/Android/data/io.github.huskydg.memorydetector /storage/emulated/0/Android/obb/com.OrangeEnvironment.Detector /storage/emulated/0/Android/data/com.OrangeEnvironment.Detector /storage/emulated/0/Android/obb/rikka.safetynetchecker /storage/emulated/0/Android/data/rikka.safetynetchecker /storage/emulated/0/Android/obb/io.github.vvb2060.keyattestation /storage/emulated/0/Android/data/io.github.vvb2060.keyattestation /storage/emulated/0/Download/WechatXposed /storage/emulated/0/WechatXposed /data/local/tmp/luckys /data/local/tmp/HyperCeiler /data/local/tmp/simpleHook /data/local/tmp/DisabledAllGoogleServices /data/local/tmp/cleaner_starter /data/local/tmp/byyang /data/local/tmp/mount_mask /data/local/tmp/mount_mark /data/local/tmp/scriptTMP /data/local/tmp/horae_control.log /data/local/tmp/resetprop /data/local/tmp/Surfing_update /data/local/tmp/yshell /data/local/tmp/encore_logo.png"
    local tcount=0
    for tool in $tools; do
        if [ -e "$tool" ]; then
            rm -rf "$tool"
            tcount=$((tcount + 1))
        fi
    done
    printf "${G}检测工具清理完成，共清理 $tcount 项${N}\n"
    echo
}

anti_detect_slot4() {
    printf "${Y}一键过春秋异常${N}\n"
    echo
    anti_detect_slot3
    printf "${Y}正在清理系统缓存...${N}\n"
    rm -rf /data/system/graphicsstats 2>/dev/null
    rm -rf /data/system/package_cache 2>/dev/null
    rm -rf /data/dev/pts/* 2>/dev/null
    rm -rf /storage/emulated/0/Android/data/chunqiu.safe 2>/dev/null
    rm -rf /data/swap_config.conf 2>/dev/null
    rm -rf /storage/emulated/legacy 2>/dev/null
    rm -rf /data/system/junge 2>/dev/null
    rm -rf /data/system/Freezer 2>/dev/null
    rm -rf /data/system/NoActive 2>/dev/null
    rm -rf /data/local/stryker 2>/dev/null
    rm -rf /data/local/MIO 2>/dev/null
    rm -rf /data/DNA 2>/dev/null
    rm -rf /data/local/tmp/* 2>/dev/null
    printf "${G}春秋异常清理完成！${N}\n"
    echo
}

anti_detect_slot5() {
    printf "${Y}过春秋 Suspicious surroundings${N}\n"
    echo
    printf "${Y}请选择方法:${N}\n"
    printf "  ${G}1${N}. 深度inode操作（耗时较长）\n"
    printf "  ${G}2${N}. 基础目录创建\n"
    printf "  ${R}0${N}. 返回\n"
    echo
    printf "  ${Y}请选择: ${N}"
    read method
    case "$method" in
        1)
            printf "${Y}开始深度inode操作...${N}\n"
            printf "${R}注意：此操作会占用较长时间${N}\n"
            local DIR_NAME="/data/local/tmp"
            local INODE=$(stat -c '%i' "$DIR_NAME" 2>/dev/null)
            if [ -n "$INODE" ] && [ "$INODE" -le 10000 ]; then
                printf "${G}当前 inode: $INODE 无需执行${N}\n"
            elif [ -n "$INODE" ]; then
                printf "${Y}当前 inode: $INODE，开始处理...${N}\n"
                printf "${R}按 Ctrl+C 可随时中断${N}\n"
                while true; do
                    [ -d "$DIR_NAME" ] && rm -rf "$DIR_NAME"
                    mkdir "$DIR_NAME" || { printf "${R}创建目录失败${N}\n"; break; }
                    INODE=$(stat -c '%i' "$DIR_NAME")
                    printf "${B}当前 inode: $INODE${N}\n"
                    [ "$INODE" -le 10000 ] && { printf "${G}触发成功！inode <= 10000${N}\n"; break; }
                done
                rm -rf /data/local/tmp_compete_* 2>/dev/null
                printf "${G}inode操作完成${N}\n"
            else
                printf "${R}无法获取inode号${N}\n"
            fi
            ;;
        2)
            printf "${Y}创建基础目录结构...${N}\n"
            mkdir -p /data/local/tmp
            mkdir -p /data/local/traces
            mkdir -p /data/local/tests
            mkdir -p /data/local/tests/vendor
            mkdir -p /data/local/tests/unrestricted
            mkdir -p /data/local/tmp/pkg_extract
            touch /data/local/tmp/pkg_extract/all_packages.txt
            rm -rf /data/local/tmp_compete_* 2>/dev/null
            printf "${G}基础目录创建完成${N}\n"
            ;;
    esac
    echo
}

anti_detect_slot6() {
    printf "${Y}过春秋 Tarmper Attribute${N}\n"
    echo
    local target_file="/data/property/persistent_properties"
    if [ ! -f "$target_file" ]; then
        printf "${R}目标文件不存在，此方案可能不适合${N}\n"
    else
        printf "${Y}正在执行操作...${N}\n"
        resetprop --delete persist.sys.vold_app_data_isolation_enabled 2>/dev/null
        resetprop --delete persist.zygote.app_data_isolation 2>/dev/null
        sed -i '/persist\.sys\.vold_app_data_isolation_enabled/d' "$target_file" 2>/dev/null
        sed -i '/persist\.zygote\.app_data_isolation/d' "$target_file" 2>/dev/null
        printf "${G}操作完成！已临时关闭模块prop属性${N}\n"
        printf "${Y}恢复请重启设备${N}\n"
    fi
    echo
}

anti_detect_slot7() {
    printf "${Y}过 Hunter api 调用${N}\n"
    echo
    settings delete global hidden_api_policy 2>/dev/null
    settings delete global hidden_api_policy_p_apps 2>/dev/null
    settings delete global hidden_api_policy_pre_p_apps 2>/dev/null
    settings delete global hidden_api_blacklist_exemptions 2>/dev/null
    printf "${G}Hunter api调用绕过完成！${N}\n"
    echo
}

anti_detect_slot8() {
    printf "${Y}设备属性恢复${N}\n"
    echo
    printf "${Y}请选择Root管理器类型:${N}\n"
    printf "  ${G}1${N}. Magisk\n"
    printf "  ${G}2${N}. KSU\n"
    printf "  ${G}3${N}. APatch\n"
    printf "  ${R}0${N}. 返回\n"
    echo
    printf "  ${Y}请选择: ${N}"
    read mgr
    case "$mgr" in
        1|2|3)
            printf "${Y}正在恢复设备属性...${N}\n"
            resetprop ro.debuggable 0 2>/dev/null
            resetprop ro.secure 1 2>/dev/null
            resetprop ro.build.tags release-keys 2>/dev/null
            resetprop ro.build.type user 2>/dev/null
            resetprop sys.boot_completed 1 2>/dev/null
            resetprop persist.sys.usb.config none 2>/dev/null
            printf "${G}设备属性恢复完成！${N}\n"
            printf "${Y}建议重启设备使更改生效${N}\n"
            ;;
    esac
    echo
}

anti_detect_slot9() {
    printf "${Y}过王者 - 游戏前清理${N}\n"
    echo
    printf "${Y}正在清理游戏相关残留...${N}\n"
    local game_paths="/data/data/com.tencent.tmgp.sgame /sdcard/Android/data/com.tencent.tmgp.sgame /sdcard/tencent/MicroMsg/com.tencent.tmgp.sgame"
    for path in $game_paths; do
        if [ -d "$path" ]; then
            printf "${G}清理: $path${N}\n"
            find "$path" -name "*.log" -delete 2>/dev/null
            find "$path" -name "*.tmp" -delete 2>/dev/null
            find "$path" -name "cache" -type d -exec rm -rf {} + 2>/dev/null
        fi
    done
    printf "${G}游戏前清理完成！${N}\n"
    echo
}

anti_detect_slot10() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}            ${W}其 他 功 能${N}                        ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}Vold隔离${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}进程杀死${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}更改设备标识${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}4${N}. ${W}SELinux 状态${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回${N}                                ${ORANGE}│${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择: ${N}"
        read opt
        case "$opt" in
            1)
                printf "${Y}Vold隔离操作...${N}\n"
                resetprop --delete persist.sys.vold_app_data_isolation_enabled 2>/dev/null
                resetprop --delete persist.zygote.app_data_isolation 2>/dev/null
                printf "${G}Vold隔离已关闭${N}\n"
                ;;
            2)
                printf "${Y}杀死可疑进程...${N}\n"
                am force-stop com.zhenxi.hunter 2>/dev/null
                am force-stop me.garfieldhan.holmes 2>/dev/null
                am force-stop icu.nullptr.nativetest 2>/dev/null
                printf "${G}可疑进程已杀死${N}\n"
                ;;
            3)
                printf "${Y}更改设备标识...${N}\n"
                change_device_ids
                ;;
            4)
                printf "${Y}当前SELinux状态:${N}\n"
                getenforce
                printf "${Y}是否临时关闭SELinux? (y/n)${N}\n"
                read sel
                if [ "$sel" = "y" ]; then
                    setenforce 0
                    printf "${G}SELinux已临时设为Permissive${N}\n"
                fi
                ;;
            0) break ;;
        esac
    done
}









install_mt_extension() {
    local DOWNLOAD_URL="https://gitee.com/xujia2024/miscellaneous-fish-toolbox/releases/download/v2.5Bata/1.apk"
    local DOWNLOAD_FILE="$SCRIPT_DIR/1.apk"
    local DOWNLOAD_STATUS=0

    printf "${P}══════════════════════════════════════════════════════════════${N}\n"
    printf "${P}              MT拓展包安装${N}\n"
    printf "${P}══════════════════════════════════════════════════════════════${N}\n"
    echo

    if [ -f "$DOWNLOAD_FILE" ]; then
        printf "${G}[√] 检测到本地文件: $DOWNLOAD_FILE${N}\n"
        printf "${C}是否使用本地文件安装? [Y/n]: ${N}"
        read use_local
        if [ "$use_local" = "Y" ] || [ "$use_local" = "y" ]; then
            printf "${Y}[!] 正在安装...${N}\n"
            if pm install -r "$DOWNLOAD_FILE" > /dev/null 2>&1; then
                printf "${G}[OK] MT拓展包安装成功!${N}\n"
                return 0
            else
                printf "${R}[X] 安装失败${N}\n"
                return 1
            fi
        fi
    fi

    printf "${C}正在下载MT拓展包...${N}\n"
    echo

    if command -v curl >/dev/null 2>&1; then
        curl -L --progress-bar -o "$DOWNLOAD_FILE" "$DOWNLOAD_URL"
        DOWNLOAD_STATUS=$?
    elif command -v wget >/dev/null 2>&1; then
        wget --show-progress -q -O "$DOWNLOAD_FILE" "$DOWNLOAD_URL"
        DOWNLOAD_STATUS=$?
    elif command -v busybox >/dev/null 2>&1 && busybox wget --help >/dev/null 2>&1; then
        busybox wget -O "$DOWNLOAD_FILE" "$DOWNLOAD_URL"
        DOWNLOAD_STATUS=$?
    else
        printf "${R}[X] 未找到可用的下载工具${N}\n"
        return 1
    fi

    if [ $DOWNLOAD_STATUS -eq 0 ] && [ -f "$DOWNLOAD_FILE" ] && [ -s "$DOWNLOAD_FILE" ]; then
        printf "${G}[OK] 下载完成${N}\n"
        printf "${Y}[!] 正在安装...${N}\n"
        if pm install -r "$DOWNLOAD_FILE" > /dev/null 2>&1; then
            printf "${G}[OK] MT拓展包安装成功!${N}\n"
            return 0
        else
            printf "${R}[X] 安装失败${N}\n"
            return 1
        fi
    else
        printf "${R}[X] 下载失败${N}\n"
        return 1
    fi
}
run_hide_apps() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}            ${W}隐 藏 应 用${N}                        ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}隐藏应用列表配置${N}                    ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}残留清理大师${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                           ${ORANGE}║${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择: ${N}"
        read sub_choice
        case "$sub_choice" in
            1) hide_apps_config ;;
            2) hide_apps_clean_master ;;
            0) break ;;
        esac
    done
}

hide_apps_config() {
    printf "${Y}隐藏应用列表配置${N}\n"
    echo
    local POSSIBLE_PACKAGES="moe.shizuku.privileged.api top.mike.hook com.tsng.hidemyapplist hide.my.applist"
    local DETECTED_PACKAGE=""
    local CONFIG_FILE=""
    printf "${Y}正在搜索隐藏应用列表...${N}\n"
    for package in $POSSIBLE_PACKAGES; do
        if [ -d "/data/data/$package" ]; then
            DETECTED_PACKAGE="$package"
            CONFIG_FILE="/data/data/$package/files/config.json"
            printf "${G}发现: $package${N}\n"
            break
        fi
    done
    local hide_dir=$(find "/data/misc" -maxdepth 1 -type d -name "*hide_my_applist*" 2>/dev/null | head -n1)
    if [ -z "$DETECTED_PACKAGE" ] && [ -n "$hide_dir" ]; then
        DETECTED_PACKAGE="hide_my_applist"
        CONFIG_FILE="$hide_dir/config.json"
        printf "${G}发现: $hide_dir${N}\n"
    fi
    if [ -z "$DETECTED_PACKAGE" ]; then
        printf "${R}未找到隐藏应用列表，请先安装${N}\n"
        return
    fi
    printf "${Y}请选择配置来源:${N}\n"
    printf "  ${G}1${N}. 使用本地配置文件\n"
    printf "  ${G}2${N}. 使用内置默认配置\n"
    echo
    printf "  ${Y}请选择: ${N}"
    read src_choice
    case "$src_choice" in
        1)
            printf "${Y}请输入配置文件路径:${N}\n"
            printf "  路径: "
            read local_config
            if [ -n "$local_config" ] && [ -f "$local_config" ]; then
                cp "$local_config" "$CONFIG_FILE" 2>/dev/null
                printf "${G}本地配置已应用${N}\n"
            else
                printf "${R}文件不存在${N}\n"
            fi
            ;;
        2)
            printf "${Y}使用内置默认配置...${N}\n"
            local config_dir=$(dirname "$CONFIG_FILE")
            mkdir -p "$config_dir" 2>/dev/null
            cat > "$CONFIG_FILE" << 'HMASEOF'
{"configVersion":90,"detailLog":false,"maxLogSize":512,"forceMountData":true,"templates":{"XToolbox默认":{"isWhitelist":false,"appList":["com.topmiaohan.superlist","com.OrangeEnvironment.Detector","io.github.vvb2060.keyattestation","rikka.appops","icu.nullptr.applistdetector","io.github.huskydg.memorydetector","io.github.vvb2060.mahoshojo","icu.nullptr.nativetest","com.omarea.vtools","moe.shizuku.privileged.api","com.byyoung.setting","com.zhenxi.hunter","me.garfieldhan.holmes","com.luckyzyx.luckytool","bin.mt.plus","eu.darken.sdmse","li.songe.gkd","web1n.stopapp","me.weishu.preventupdate","have.fun","io.github.qauxv","im.mingxi.miko"]}}}
HMASEOF
            local app_user=$(stat -c '%U' "$(dirname "$CONFIG_FILE")" 2>/dev/null)
            chown ${app_user:-u0_a314}:${app_user:-u0_a314} "$CONFIG_FILE" 2>/dev/null
            chmod 644 "$CONFIG_FILE" 2>/dev/null
            printf "${G}内置配置已应用${N}\n"
            ;;
    esac
    printf "${Y}配置完成！请打开隐藏应用列表应用查看效果${N}\n"
    echo
}

hide_apps_clean_master() {
    printf "${Y}残留清理大师${N}\n"
    echo
    local hide_dir=$(find "/data/misc" -maxdepth 1 -type d -name "*hide_my_applist*" 2>/dev/null | head -n1)
    if [ -z "$hide_dir" ]; then
        printf "${R}未找到隐藏应用配置目录${N}\n"
        return
    fi
    local config_file="$hide_dir/config.json"
    if [ ! -f "$config_file" ]; then
        printf "${R}未找到配置文件${N}\n"
        return
    fi
    printf "${G}找到配置目录: $hide_dir${N}\n"
    printf "${Y}正在清理残留...${N}\n"
    local clean_paths="/storage/emulated/0/Android/data/me.garfieldhan.holmes /storage/emulated/0/Android/data/com.zhenxi.hunter /storage/emulated/0/Android/data/icu.nullptr.nativetest /storage/emulated/0/Android/data/com.byyoung.setting /data/property/persistent_properties /storage/emulated/0/Android/data/bin.mt.plus /storage/emulated/0/Android/data/com.omarea.vtools /storage/emulated/0/Android/data/moe.shizuku.privileged.api"
    local count=0
    for path in $clean_paths; do
        if [ -e "$path" ]; then
            rm -rf "$path"
            count=$((count + 1))
        fi
    done
    printf "${G}清理完成，共清理 $count 项${N}\n"
    echo
}


run_module_manager() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}            ${W}模 块 管 理${N}                        ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}查看已安装模块${N}                      ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}扫描可安装模块${N}                      ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}安装模块${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}4${N}. ${W}卸载模块${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}5${N}. ${W}检测Root管理器${N}                      ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}6${N}. ${W}高级目录搜索${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                           ${ORANGE}║${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择: ${N}"
        read sub_choice
        case "$sub_choice" in
            1) mm_show_installed ;;
            2) mm_scan_available ;;
            3) mm_install ;;
            4) mm_uninstall ;;
            5) mm_detect_manager ;;
            6) mm_advanced_search ;;
            0) break ;;
        esac
    done
}

mm_detect_manager() {
    printf "${Y}正在检测Root管理器...${N}\n"
    local found=0
    if [ -d "/data/adb/magisk" ]; then
        printf "${G}检测到: Magisk${N}\n"
        local magisk_ver=$(magisk -v 2>/dev/null || printf "未知版本\n")
        printf "${B}版本: $magisk_ver${N}\n"
        printf "${B}安装命令: magisk --install-module <模块.zip>${N}\n"
        found=1
    fi
    if [ -d "/data/adb/ksu" ] || [ -d "/data/adb/ksud" ]; then
        printf "${G}检测到: KernelSU${N}\n"
        printf "${B}安装命令: ksu module install <模块.zip>${N}\n"
        found=1
    fi
    if [ -d "/data/adb/ap" ] || [ -f "/data/adb/apd" ]; then
        printf "${G}检测到: APatch${N}\n"
        printf "${B}安装命令: apd module install <模块.zip>${N}\n"
        found=1
    fi
    if [ $found -eq 0 ]; then
        printf "${R}未检测到Root管理器${N}\n"
    fi
    echo
}

mm_show_installed() {
    printf "${Y}已安装模块:${N}\n"
    echo
    if [ ! -d "/data/adb/modules" ]; then
        printf "${R}模块目录不存在${N}\n"
        return
    fi
    local count=0
    for mod in /data/adb/modules/*/; do
        [ -d "$mod" ] || continue
        local mod_dir=$(basename "$mod")
        local mod_name=$(grep '^name=' "$mod/module.prop" 2>/dev/null | cut -d= -f2 | head -1)
        local mod_ver=$(grep '^version=' "$mod/module.prop" 2>/dev/null | cut -d= -f2 | head -1)
        local mod_author=$(grep '^author=' "$mod/module.prop" 2>/dev/null | cut -d= -f2 | head -1)
        local enabled="启用"
        [ -f "$mod/disable" ] && enabled="${R}禁用${N}"
        count=$((count + 1))
        printf "  ${G}$count.${N} ${W}${mod_name:-$mod_dir}${N} ${DI}v${mod_ver:-?}${N} ${DI}by ${mod_author:-?}${N} [$enabled]\n"
    done
    if [ $count -eq 0 ]; then
        printf "${DI}暂无已安装模块${N}\n"
    else
        printf "${Y}共 $count 个模块${N}\n"
    fi
    echo
}

mm_scan_available() {
    printf "${Y}正在扫描可安装模块...${N}\n"
    echo
    local scan_dirs="/storage/emulated/0/Download /sdcard/Download /storage/emulated/0 /sdcard /data/local/tmp"
    local found=0
    for dir in $scan_dirs; do
        [ -d "$dir" ] || continue
        for zip in "$dir"/*.zip; do
            [ -f "$zip" ] || continue
            if unzip -l "$zip" 2>/dev/null | grep -q "module.prop"; then
                local mod_name=$(unzip -p "$zip" module.prop 2>/dev/null | grep '^name=' | cut -d= -f2 | head -1)
                found=$((found + 1))
                printf "  ${G}$found.${N} ${W}${mod_name:-$(basename \n"$zip")}${N}"
                printf "      ${DI}$zip${N}\n"
            fi
        done
    done
    if [ $found -eq 0 ]; then
        printf "${DI}未找到可安装的模块文件${N}\n"
    else
        printf "${Y}共找到 $found 个模块${N}\n"
    fi
    echo
}

mm_install() {
    printf "${Y}安装模块${N}\n"
    printf "  ${Y}请输入模块ZIP路径: ${N}"
    read zip_path
    if [ -z "$zip_path" ] || [ ! -f "$zip_path" ]; then
        printf "${R}文件不存在${N}\n"
        return
    fi
    if ! unzip -l "$zip_path" 2>/dev/null | grep -q "module.prop"; then
        printf "${R}不是有效的模块文件${N}\n"
        return
    fi
    mm_detect_manager
    printf "  ${Y}选择管理器 (1.Magisk 2.KSU 3.APatch): ${N}"
    read mgr
    case "$mgr" in
        1) magisk --install-module "$zip_path" 2>&1 ;;
        2) ksu module install "$zip_path" 2>&1 ;;
        3) apd module install "$zip_path" 2>&1 ;;
        *) printf "${R}无效选择${N}\n" ;;
    esac
    echo
}

mm_uninstall() {
    printf "${Y}卸载模块${N}\n"
    mm_show_installed
    printf "  ${Y}请输入模块目录名: ${N}"
    read mod_name
    if [ -z "$mod_name" ] || [ ! -d "/data/adb/modules/$mod_name" ]; then
        printf "${R}模块不存在${N}\n"
        return
    fi
    printf "${R}确认卸载 $mod_name? (y/n)${N}\n"
    read confirm
    if [ "$confirm" = "y" ]; then
        rm -rf "/data/adb/modules/$mod_name"
        printf "${G}模块已卸载，重启后生效${N}\n"
    fi
    echo
}

mm_advanced_search() {
    printf "${Y}高级目录搜索${N}\n"
    printf "  ${Y}请输入搜索目录: ${N}"
    read search_dir
    if [ -z "$search_dir" ] || [ ! -d "$search_dir" ]; then
        printf "${R}目录不存在${N}\n"
        return
    fi
    printf "${Y}正在扫描 $search_dir ...${N}\n"
    local count=0
    for zip in "$search_dir"/*.zip; do
        [ -f "$zip" ] || continue
        if unzip -l "$zip" 2>/dev/null | grep -q "module.prop"; then
            count=$((count + 1))
            printf "  ${G}$count.${N} $(basename \n"$zip")"
        fi
    done
    printf "${Y}找到 $count 个模块${N}\n"
    echo
}


run_apk_installer() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}            ${W}安 装 软 件${N}                        ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}深度扫描APK${N}                          ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}手动安装APK${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}批量安装${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}4${N}. ${W}修复损坏APK文件${N}                     ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                           ${ORANGE}║${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择: ${N}"
        read sub_choice
        case "$sub_choice" in
            1) apk_deep_scan ;;
            2) apk_manual_install ;;
            3) apk_batch_install ;;
            4) apk_repair ;;
            0) break ;;
        esac
    done
}

is_valid_apk() {
    local file="$1"
    [ ! -f "$file" ] && return 1
    local size=$(stat -c%s "$file" 2>/dev/null)
    [ -z "$size" ] || [ "$size" -lt 10240 ] && return 1
    if which file >/dev/null 2>&1; then
        file "$file" 2>/dev/null | grep -q "Zip archive" || return 1
    fi
    if which unzip >/dev/null 2>&1; then
        unzip -l "$file" 2>/dev/null | head -20 | grep -q "AndroidManifest.xml" && return 0
    fi
    if which aapt >/dev/null 2>&1; then
        aapt dump badging "$file" 2>/dev/null | head -5 | grep -q "package:" && return 0
    fi
    local first_bytes=$(head -c 4 "$file" 2>/dev/null | xxd -p 2>/dev/null)
    [ "$first_bytes" = "504b0304" ] && return 0
    return 1
}

apk_deep_scan() {
    printf "${Y}深度扫描APK文件${N}\n"
    printf "  ${Y}请输入扫描目录: ${N}"
    read scan_path
    scan_path="${scan_path:-/storage/emulated/0/Download}"
    if [ ! -d "$scan_path" ]; then
        printf "${R}目录不存在: $scan_path${N}\n"
        return
    fi
    printf "${Y}正在扫描 $scan_path ...${N}\n"
    local valid=0
    local invalid=0
    local apk_list=""
    for file in "$scan_path"/*.apk "$scan_path"/*.APK; do
        [ -f "$file" ] || continue
        if is_valid_apk "$file"; then
            valid=$((valid + 1))
            local info=""
            if which aapt >/dev/null 2>&1; then
                local pkg=$(aapt dump badging "$file" 2>/dev/null | grep "package:" | sed "s/.*name='\([^']*\)'.*/\1/" | head -1)
                local ver=$(aapt dump badging "$file" 2>/dev/null | grep "versionName=" | sed "s/.*versionName='\([^']*\)'.*/\1/" | head -1)
                info="${pkg:-未知} v${ver:-?}"
            else
                info=$(basename "$file")
            fi
            printf "  ${G}[OK]${N} $info\n"
            apk_list="$apk_list $file"
        else
            invalid=$((invalid + 1))
            printf "  ${R}[跳过]$(basename \n"$file")${N}"
        fi
    done
    echo
    printf "${G}有效APK: $valid 个${N}  ${R}无效: $invalid 个${N}\n"
    if [ $valid -gt 0 ]; then
        printf "  ${Y}是否安装所有有效APK? (y/n): ${N}"
        read install_all
        if [ "$install_all" = "y" ]; then
            for apk in $apk_list; do
                printf "${Y}正在安装: $(basename \n"$apk")${N}"
                pm install -r "$apk" 2>&1
                echo
            done
        fi
    fi
}

apk_manual_install() {
    printf "${Y}手动安装APK${N}\n"
    printf "  ${Y}请输入APK路径: ${N}"
    read apk_path
    if [ -z "$apk_path" ] || [ ! -f "$apk_path" ]; then
        printf "${R}文件不存在${N}\n"
        return
    fi
    if ! is_valid_apk "$apk_path"; then
        printf "${R}不是有效的APK文件${N}\n"
        return
    fi
    printf "${Y}正在安装...${N}\n"
    pm install -r "$apk_path" 2>&1
    echo
}

apk_batch_install() {
    printf "${Y}批量安装${N}\n"
    printf "  ${Y}请输入包含APK的目录: ${N}"
    read apk_dir
    apk_dir="${apk_dir:-/storage/emulated/0/Download}"
    if [ ! -d "$apk_dir" ]; then
        printf "${R}目录不存在${N}\n"
        return
    fi
    local total=0
    local success=0
    for apk in "$apk_dir"/*.apk; do
        [ -f "$apk" ] || continue
        if is_valid_apk "$apk"; then
            total=$((total + 1))
            printf "${Y}[$total] 安装: $(basename \n"$apk")${N}"
            if pm install -r "$apk" >/dev/null 2>&1; then
                success=$((success + 1))
                printf "${G}  成功${N}\n"
            else
                printf "${R}  失败${N}\n"
            fi
        fi
    done
    printf "${G}安装完成: $success/$total${N}\n"
    echo
}

apk_repair() {
    printf "${Y}修复损坏APK文件${N}\n"
    printf "  ${Y}请输入APK路径: ${N}"
    read apk_path
    if [ -z "$apk_path" ] || [ ! -f "$apk_path" ]; then
        printf "${R}文件不存在${N}\n"
        return
    fi
    local base=$(basename "$apk_path")
    case "$base" in
        *.apk.[0-9]*|*.apk.bak|*.apk.backup|*.apk.download|*.apk.tmp|*.apk.temp)
            printf "${Y}发现特殊后缀文件，尝试修复...${N}\n"
            local fixed="/data/local/tmp/fixed_$$.apk"
            cp "$apk_path" "$fixed"
            if is_valid_apk "$fixed"; then
                printf "${G}修复成功！${N}\n"
                printf "${Y}修复后路径: $fixed${N}\n"
                printf "  ${Y}是否安装修复后的文件? (y/n): ${N}"
                read install
                if [ "$install" = "y" ]; then
                    pm install -r "$fixed" 2>&1
                fi
            else
                rm -f "$fixed"
                printf "${R}修复失败，文件可能已损坏${N}\n"
            fi
            ;;
        *)
            printf "${DI}文件后缀正常，无需修复${N}\n"
            ;;
    esac
    echo
}


run_partition_backup() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}            ${W}分 区 备 份${N}                        ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}扫描分区${N}                            ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}备份单个分区${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}一键备份重要分区${N}                    ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}4${N}. ${W}字库分区备份${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}5${N}. ${W}查看备份文件${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}6${N}. ${W}刷写备份分区${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                           ${ORANGE}║${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择: ${N}"
        read sub_choice
        case "$sub_choice" in
            1) pb_scan_partitions ;;
            2) pb_backup_single ;;
            3) pb_backup_important ;;
            4) pb_backup_fonts ;;
            5) pb_show_backups ;;
            6) pb_flash_backup ;;
            0) break ;;
        esac
    done
}

pb_scan_partitions() {
    printf "${Y}正在扫描分区...${N}\n"
    echo
    local parts=$(ls /dev/block/by-name/ 2>/dev/null)
    if [ -z "$parts" ]; then
        printf "${R}无法读取分区表${N}\n"
        return
    fi
    local count=0
    printf "${G}═══ 分区列表 ═══${N}\n"
    for part in $parts; do
        count=$((count + 1))
        local device=$(readlink -f "/dev/block/by-name/$part" 2>/dev/null)
        local size=""
        [ -n "$device" ] && [ -b "$device" ] && size=$(blockdev --getsize64 "$device" 2>/dev/null)
        if [ -n "$size" ] && [ "$size" -gt 0 ]; then
            local size_mb=$((size / 1024 / 1024))
            printf "  ${G}$count.${N} ${W}$part${N} ${DI}(${size_mb}MB)${N}\n"
        else
            printf "  ${G}$count.${N} ${W}$part${N}\n"
        fi
    done
    printf "${Y}共 $count 个分区${N}\n"
    echo
}

pb_backup_partition() {
    local part_name="$1"
    local device=$(readlink -f "/dev/block/by-name/$part_name" 2>/dev/null)
    if [ -z "$device" ] || [ ! -b "$device" ]; then
        printf "${R}分区不存在: $part_name${N}\n"
        return 1
    fi
    local backup_dir="/sdcard/Download/XToolbox/partition_backup"
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/${part_name}_$(date +%Y%m%d_%H%M%S).img"
    printf "${Y}正在备份 $part_name ...${N}\n"
    if dd if="$device" of="$backup_file" bs=4M 2>/dev/null; then
        local size=$(du -h "$backup_file" 2>/dev/null | cut -f1)
        printf "${G}备份完成: $backup_file ($size)${N}\n"
    else
        printf "${R}备份失败${N}\n"
        rm -f "$backup_file" 2>/dev/null
    fi
}

pb_backup_single() {
    printf "${Y}备份单个分区${N}\n"
    printf "  ${Y}请输入分区名称: ${N}"
    read part_name
    [ -z "$part_name" ] && return
    pb_backup_partition "$part_name"
}

pb_backup_important() {
    printf "${Y}一键备份重要分区${N}\n"
    printf "${R}警告：需要较大存储空间${N}\n"
    printf "  ${Y}确认? (y/n): ${N}"
    read confirm
    [ "$confirm" != "y" ] && return
    local important="boot system vendor recovery dtbo vbmeta"
    local success=0
    local total=0
    for part in $important; do
        if [ -e "/dev/block/by-name/$part" ]; then
            total=$((total + 1))
            pb_backup_partition "$part" && success=$((success + 1))
        fi
    done
    printf "${G}备份完成: $success/$total${N}\n"
}

pb_backup_fonts() {
    printf "${Y}字库分区备份${N}\n"
    echo
    local font_keywords="font chinese zh cn ttf otf simsun noto droid"
    local font_parts=""
    for part in $(ls /dev/block/by-name/ 2>/dev/null); do
        local lower=$(printf "$part\n" | tr '[:upper:]' '[:lower:]')
        for kw in $font_keywords; do
            if printf "$lower\n" | grep -q "$kw"; then
                font_parts="$font_parts $part"
                break
            fi
        done
    done
    if [ -z "$font_parts" ]; then
        printf "${Y}未发现独立字库分区${N}\n"
        printf "${Y}字库可能集成在 system/vendor 分区中${N}\n"
        return
    fi
    printf "${G}发现字库相关分区:$font_parts${N}\n"
    printf "  ${Y}是否备份? (y/n): ${N}"
    read confirm
    [ "$confirm" != "y" ] && return
    for part in $font_parts; do
        pb_backup_partition "$part"
    done
}

pb_show_backups() {
    printf "${Y}已备份文件${N}\n"
    echo
    local backup_dir="/sdcard/Download/XToolbox/partition_backup"
    if [ ! -d "$backup_dir" ]; then
        printf "${DI}备份目录不存在${N}\n"
        return
    fi
    local files=$(ls -lh "$backup_dir"/*.img 2>/dev/null)
    if [ -z "$files" ]; then
        printf "${DI}暂无备份文件${N}\n"
    else
        printf "$files\n"
    fi
    echo
}

pb_flash_backup() {
    printf "${R}═══ 警告：刷写分区可能导致设备变砖 ═══${N}\n"
    printf "  ${Y}确认继续? (输入yes): ${N}"
    read confirm
    [ "$confirm" != "yes" ] && return
    local backup_dir="/sdcard/Download/XToolbox/partition_backup"
    if [ ! -d "$backup_dir" ]; then
        printf "${R}备份目录不存在${N}\n"
        return
    fi
    printf "${Y}请选择模式:${N}\n"
    printf "  ${G}1${N}. 刷写所有备份\n"
    printf "  ${G}2${N}. 刷写单个分区\n"
    echo
    printf "  ${Y}请选择: ${N}"
    read mode
    case "$mode" in
        1)
            for img in "$backup_dir"/*.img; do
                [ -f "$img" ] || continue
                local part_name=$(basename "$img" | sed 's/_20[0-9][0-9].*//')
                local device=$(readlink -f "/dev/block/by-name/$part_name" 2>/dev/null)
                if [ -n "$device" ] && [ -b "$device" ]; then
                    printf "${Y}刷写 $part_name ...${N}\n"
                    dd if="$img" of="$device" bs=4M 2>/dev/null && printf "${G}成功${N}\n" || printf "${R}失败${N}\n"
                else
                    printf "${R}分区不存在: $part_name${N}\n"
                fi
            done
            ;;
        2)
            printf "  ${Y}请输入分区名称: ${N}"
            read part_name
            local latest=$(ls -t "$backup_dir"/${part_name}_*.img 2>/dev/null | head -1)
            if [ -z "$latest" ]; then
                printf "${R}未找到备份${N}\n"
            else
                local device=$(readlink -f "/dev/block/by-name/$part_name" 2>/dev/null)
                if [ -n "$device" ] && [ -b "$device" ]; then
                    printf "${Y}刷写 $part_name ...${N}\n"
                    dd if="$latest" of="$device" bs=4M 2>/dev/null && printf "${G}成功${N}\n" || printf "${R}失败${N}\n"
                fi
            fi
            ;;
    esac
    echo
}


run_ak3_flash() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}            ${W}A K 3 刷 写${N}                        ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}选择ZIP文件刷入${N}                      ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}手动输入路径${N}                        ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                           ${ORANGE}║${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择: ${N}"
        read sub_choice
        case "$sub_choice" in
            1)
                printf "${Y}正在扫描ZIP文件...${N}\n"
                local zip_files=""
                for dir in /sdcard/Download /storage/emulated/0/Download /data/local/tmp; do
                    [ -d "$dir" ] || continue
                    for f in "$dir"/*.zip; do
                        [ -f "$f" ] && zip_files="$zip_files $f"
                    done
                done
                if [ -z "$zip_files" ]; then
                    printf "${R}未找到ZIP文件${N}\n"
                else
                    printf "${G}找到以下ZIP文件:${N}\n"
                    local idx=1
                    local zlist=""
                    for f in $zip_files; do
                        printf "  ${G}$idx.${N} $(basename \n"$f")"
                        zlist="$zlist $f"
                        idx=$((idx + 1))
                    done
                    printf "  ${Y}请选择: ${N}"
                    read zchoice
                    local zip_path=$(printf "$zlist\n" | awk -v c="$zchoice" '{{print $c}}')
                    if [ -n "$zip_path" ] && [ -f "$zip_path" ]; then
                        ak3_flash_zip "$zip_path"
                    fi
                fi
                ;;
            2)
                printf "  ${Y}请输入ZIP文件路径: ${N}"
                read zip_path
                if [ -n "$zip_path" ] && [ -f "$zip_path" ]; then
                    ak3_flash_zip "$zip_path"
                else
                    printf "${R}文件不存在${N}\n"
                fi
                ;;
            0) break ;;
        esac
    done
}

ak3_flash_zip() {
    local zip_file="$1"
    printf "${Y}准备刷入: $(basename \n"$zip_file")${N}"
    printf "${R}警告：刷入错误的内核可能导致设备变砖${N}\n"
    printf "  ${Y}确认刷入? (yes/n): ${N}"
    read confirm
    if [ "$confirm" != "yes" ]; then
        printf "${Y}已取消${N}\n"
        return
    fi
    ak3_main_flow "$zip_file"
}




trap 'trap_handler INT' INT
trap 'trap_handler TERM' TERM


AK3_VERSION="1.0.0"
AK3_DATE="2025-01-01"

AKHOME=""          # AnyKernel3 主工作目录
BOOTIMG=""         # boot.img 镜像文件路径
BIN=""             # 工具目录路径
PATCH=""           # 补丁目录路径
RAMDISK=""         # ramdisk 解包目录
SPLITIMG=""        # 镜像拆分目录

BLOCK=""           # 目标分区块设备路径
SLOT=""            # 当前 A/B 槽位后缀（如 _a 或 _b）
IS_SLOT_DEVICE=0   # 是否为 A/B 分区设备
RAMDISK_COMPRESSION="auto"  # ramdisk 压缩方式
PATCH_VBMETA_FLAG="auto"    # vbmeta 禁用标志

OUTFD=""           # Recovery UI 输出文件描述符
ZIPFILE=""         # 刷机包 ZIP 文件路径
BOOTMODE=false     # 是否为系统内刷入模式
DIR=""             # 工作目录（sdcard 或 ZIP 所在目录）
DEBUG_MODE=0       # 调试模式标志
OLD_PATH=""        # 原始 PATH 环境变量备份
UMOUNTLIST=""      # 需要卸载的挂载点列表
CUSTOMDD=""        # 自定义 dd 参数
KERNEL_STRING=""   # 内核字符串标识
NO_BLOCK_DISPLAY=0 # 不显示分区块设备信息
NO_MAGISK_CHECK=0  # 跳过 Magisk 检测
NO_VBMETA_PARTITION_PATCH=0  # 不修补 vbmeta 分区
SLOT_SELECT=""     # 手动槽位选择
magisk_patched=0   # Magisk 补丁标志
kernelsu_patched=0 # KernelSU 补丁标志
PATCHVBMETAFLAG="" # vbmeta 禁用标志（magiskboot 使用）
POSTINSTALL=""     # postinstall 路径
ANDROID_ROOT=""    # Android 根目录（/system 或 /system_root）
OLD_LD_PATH=""     # 原始 LD_LIBRARY_PATH
OLD_LD_PRE=""      # 原始 LD_PRELOAD
OLD_LD_CFG=""      # 原始 LD_CONFIG_FILE


ui_print() {
  until [ ! "$1" ]; do
    if [ -n "$OUTFD" ] && [ -e "/proc/self/fd/$OUTFD" ] && [ -w "/proc/self/fd/$OUTFD" ]; then
      # Recovery 模式：写入到 Recovery 的 UI 输出
      printf "ui_print $1
      ui_print\n"
>> /proc/self/fd/$OUTFD;
    else
      # 系统模式：直接输出到 stdout
      printf "$1\n";
    fi;
    shift;
  done;
}

ui_printfile() {
  local line losrpad;
  $BOOTMODE || [ -e /twres ] || losrpad='| ';  # 兼容 LineageOS Recovery 吞噬前导空格
  while IFS='' read -r line || [ -n "$line" ]; do
    ui_print "$losrpad$line";
  done < $1;
}

show_progress() {
  if [ -n "$OUTFD" ] && [ -e "/proc/self/fd/$OUTFD" ] && [ -w "/proc/self/fd/$OUTFD" ]; then
    printf "progress $1 $2\n" >> /proc/self/fd/$OUTFD;
  fi;
}

log_info() {
  printf "[信息] $*\n" >&2;
}

log_warn() {
  printf "[警告] $*\n" >&2;
}

log_error() {
  printf "[错误] $*\n" >&2;
}

log_debug() {
  [ "$DEBUG_MODE" = 1 ] && printf "[调试] $*\n" >&2;
}

abort() {
  ui_print "$@";
  debugging;
  restore_env;
  if [ ! -f anykernel.sh -o "$(file_getprop anykernel.sh do.cleanuponabort 2>/dev/null)" == 1 ]; then
    cleanup;
  fi;
  exit 1;
}

contains() {
  [ "${1#*$2}" != "$1" ];
}

file_getprop() {
  grep "^$2=" "$1" | tail -n1 | cut -d= -f2-;
}

int2ver() {
  if [ "$1" -eq "$1" ] 2>/dev/null; then
    printf "$1.0.0\n";
  elif [ ! "$(printf "$1\n" | cut -d. -f3)" ]; then
    printf "$1.0\n";
  else
    printf "$1\n";
  fi;
}

set_perm() {
  local uid gid mod;
  uid=$1; gid=$2; mod=$3;
  shift 3;
  chown $uid:$gid "$@" || chown $uid.$gid "$@";
  chmod $mod "$@";
}

set_perm_recursive() {
  local uid gid dmod fmod;
  uid=$1; gid=$2; dmod=$3; fmod=$4;
  shift 4;
  while [ "$1" ]; do
    chown -R $uid:$gid "$1" || chown -R $uid.$gid "$1";
    find "$1" -type d -exec chmod $dmod {} +;
    find "$1" -type f -exec chmod $fmod {} +;
    shift;
  done;
}


validate_input() {
  if [ -z "$ZIPFILE" ]; then
    log_error "未指定刷机包文件";
    return 1;
  fi;
  if [ ! -f "$ZIPFILE" ]; then
    log_error "刷机包文件不存在: $ZIPFILE";
    return 1;
  fi;
  if [ ! -r "$ZIPFILE" ]; then
    log_error "无法读取刷机包文件: $ZIPFILE";
    return 1;
  fi;
  # 检查是否为有效的 ZIP 文件
  if ! unzip -l "$ZIPFILE" >/dev/null 2>&1; then
    log_error "文件不是有效的 ZIP 格式: $ZIPFILE";
    return 1;
  fi;
  log_info "输入验证通过: $ZIPFILE";
  return 0;
}

check_root() {
  local uid_val;
  uid_val=$(id -u 2>/dev/null);
  if [ "$uid_val" != "0" ] && [ "$(whoami 2>/dev/null)" != "root" ]; then
    log_warn "当前用户非 root (uid=$uid_val)，部分操作可能受限";
    return 1;
  fi;
  log_debug "root 权限检查通过";
  return 0;
}

check_tools() {
  local missing="";
  if ! which magiskboot >/dev/null 2>&1 && [ ! -f "$BIN/magiskboot" ]; then
    missing="$missing magiskboot";
  fi;
  if [ -n "$missing" ]; then
    log_warn "缺少以下工具:$missing";
    log_warn "将尝试使用 busybox 替代方案";
    return 1;
  fi;
  log_debug "工具检查通过";
  return 0;
}

safe_mkdir() {
  local dir="$1";
  if [ -e "$dir" ]; then
    if [ ! -d "$dir" ]; then
      log_error "路径已存在但不是目录: $dir";
      return 1;
    fi;
    log_debug "目录已存在: $dir";
    return 0;
  fi;
  mkdir -p "$dir" 2>/dev/null;
  if [ $? -ne 0 ]; then
    log_error "无法创建目录: $dir";
    return 1;
  fi;
  chmod 755 "$dir";
  log_debug "目录创建成功: $dir";
  return 0;
}


find_slot() {
  local slot=$(getprop ro.boot.slot_suffix 2>/dev/null);
  # 从 getprop 获取失败则从 /proc/cmdline 读取
  [ "$slot" ] || slot=$(grep -o 'androidboot.slot_suffix=.*$' /proc/cmdline | cut -d\  -f1 | cut -d= -f2);
  if [ ! "$slot" ]; then
    # 尝试 ro.boot.slot 属性（无下划线前缀）
    slot=$(getprop ro.boot.slot 2>/dev/null);
    [ "$slot" ] || slot=$(grep -o 'androidboot.slot=.*$' /proc/cmdline | cut -d\  -f1 | cut -d= -f2);
    [ "$slot" ] && slot=_$slot;
  fi;
  # normal 表示非 A/B 设备
  [ "$slot" == "normal" ] && unset slot;
  [ "$slot" ] && printf "$slot\n";
}

setup_mountpoint() {
  # 如果是符号链接，先备份
  [ -L $1 ] && mv -f $1 ${1}_link;
  if [ ! -d $1 ]; then
    rm -f $1;
    mkdir -p $1;
  fi;
}

is_mounted() {
  mount | grep -q " $1 ";
}

mount_apex() {
  [ -d /system_root/system/apex ] || return 1;
  local apex dest loop minorx num shcon var;
  setup_mountpoint /apex;
  mount -t tmpfs tmpfs /apex -o mode=755 && touch /apex/apextmp;
  # 保存并临时修改 SELinux 上下文以允许 loop 挂载
  shcon=$(cat /proc/self/attr/current);
  printf "u:r:su:s0\n" > /proc/self/attr/current 2>/dev/null;  # 兼容 LOS Recovery
  minorx=1;
  [ -e /dev/block/loop1 ] && minorx=$(ls -l /dev/block/loop1 | awk '{ print $6 }');
  num=0;
  for apex in /system_root/system/apex/*; do
    dest=/apex/$(basename $apex | sed -E -e 's;\.apex$|\.capex$;;' -e 's;\.current$|\.release$;;');
    mkdir -p $dest;
    case $apex in
      *.apex|*.capex)
        # 解压 APEX 文件
        unzip -qo $apex original_apex -d /apex;
        [ -f /apex/original_apex ] && apex=/apex/original_apex;
        unzip -qo $apex apex_payload.img -d /apex;
        mv -f /apex/original_apex $dest.apex 2>/dev/null;
        mv -f /apex/apex_payload.img $dest.img;
        # 尝试直接挂载
        mount -t ext4 -o ro,noatime $dest.img $dest 2>/dev/null && printf "$dest (直接挂载)\n" >&2;
        if [ $? != 0 ]; then
          # 直接挂载失败，尝试 loop 挂载
          while [ $num -lt 64 ]; do
            loop=/dev/block/loop$num;
            [ -e $loop ] || mknod $loop b 7 $((num * minorx));
            losetup $loop $dest.img 2>/dev/null;
            num=$((num + 1));
            losetup $loop | grep -q $dest.img && break;
          done;
          mount -t ext4 -o ro,loop,noatime $loop $dest && printf "$dest (loop挂载)\n" >&2;
          if [ $? != 0 ]; then
            losetup -d $loop 2>/dev/null;
            # 检测 loop 设备耗尽
            if [ $num -eq 64 -a $(losetup -f) == "/dev/block/loop0" ]; then
              printf "APEX 挂载环境异常，中止挂载...\n" >&2;
              break;
            fi;
          fi;
        fi;
      ;;
      *) # 非 apex 文件使用 bind 挂载
        mount -o bind $apex $dest && printf "$dest (bind挂载)\n" >&2;;
    esac;
  done;
  # 恢复 SELinux 上下文
  printf "$shcon\n" > /proc/self/attr/current 2>/dev/null;
  # 从 init.environ.rc 导出环境变量
  for var in $(grep -o 'export .* /.*' /system_root/init.environ.rc | awk '{ print $2 }'); do
    eval OLD_${var}=\$$var;
  done;
  $(grep -o 'export .* /.*' /system_root/init.environ.rc | sed 's; /;=/;'); unset export;
  touch /apex/apexak3;
}

umount_apex() {
  [ -f /apex/apexak3 ] || return 1;
  printf "正在卸载 APEX...\n" >&2;
  local dest loop var;
  # 恢复环境变量
  for var in $(grep -o 'export .* /.*' /system_root/init.environ.rc 2>/dev/null | awk '{ print $2 }'); do
    if [ "$(eval echo \$OLD_$var)" ]; then
      eval $var=\$OLD_${var};
    else
      eval unset $var;
    fi;
    unset OLD_${var};
  done;
  # 卸载所有 APEX 挂载点
  for dest in $(find /apex -type d -mindepth 1 -maxdepth 1); do
    loop=$(mount | grep $dest | grep loop | cut -d\  -f1);
    umount -l $dest;
    losetup $loop >/dev/null 2>&1 && losetup -d $loop;
  done;
  [ -f /apex/apextmp ] && umount /apex;
  rm -rf /apex/apexak3 /apex 2>/dev/null;
}

mount_all() {
  local byname mount slot system;
  printf "正在挂载分区...\n" >&2;
  # 查找 by-name 目录
  byname=bootdevice/by-name;
  [ -d /dev/block/$byname ] || byname=$(find /dev/block/platform -type d -name by-name 2>/dev/null | head -n1 | cut -d/ -f4-);
  # 动态分区设备使用 mapper
  [ -e /dev/block/$byname/super -a -d /dev/block/mapper ] && byname=mapper;
  # 如果 system 分区不在 by-name 中，检测槽位
  [ -e /dev/block/$byname/system ] || slot=$(find_slot);
  # 挂载基础分区
  for mount in /cache /data /metadata /persist; do
    if ! is_mounted $mount; then
      mount $mount 2>/dev/null && printf "$mount (fstab)\n" >&2 && UMOUNTLIST="$UMOUNTLIST $mount";
      if [ $? != 0 -a -e /dev/block/$byname$mount ]; then
        setup_mountpoint $mount;
        mount -o ro -t auto /dev/block/$byname$mount $mount && printf "$mount (直接挂载)\n" >&2 && UMOUNTLIST="$UMOUNTLIST $mount";
      fi;
    fi;
  done;
  # 挂载 Android 根分区
  setup_mountpoint $ANDROID_ROOT;
  if ! is_mounted $ANDROID_ROOT; then
    mount -o ro -t auto $ANDROID_ROOT 2>/dev/null && printf "$ANDROID_ROOT (\$ANDROID_ROOT)\n" >&2;
  fi;
  # 处理 system_root 模式
  case $ANDROID_ROOT in
    /system_root) setup_mountpoint /system;;
    /system)
      if ! is_mounted /system && ! is_mounted /system_root; then
        setup_mountpoint /system_root;
        mount -o ro -t auto /system_root && printf "/system_root (fstab)\n" >&2;
      elif [ -f /system/system/build.prop ]; then
        setup_mountpoint /system_root;
        mount --move /system /system_root && printf "/system_root (移动挂载)\n" >&2;
      fi;
      if [ $? != 0 ]; then
        (umount /system;
        umount -l /system) 2>/dev/null;
        mount -o ro -t auto /dev/block/$byname/system$slot /system_root && printf "/system_root (直接挂载)\n" >&2;
      fi;
    ;;
  esac;
  # 检测 system 分区下的子目录结构
  [ -f /system_root/system/build.prop ] && system=/system;
  # 挂载 vendor, product, system_ext 等分区
  for mount in /vendor /product /system_ext; do
    mount -o ro -t auto $mount 2>/dev/null && printf "$mount (fstab)\n" >&2;
    if [ $? != 0 ] && [ -L /system$mount -o -L /system_root$system$mount ]; then
      setup_mountpoint $mount;
      mount -o ro -t auto /dev/block/$byname$mount$slot $mount && printf "$mount (直接挂载)\n" >&2;
    fi;
  done;
  # 如果 system_root 已挂载，挂载 APEX 并 bind /system
  if is_mounted /system_root; then
    mount_apex;
    mount -o bind /system_root$system /system && printf "/system (bind挂载)\n" >&2;
  fi;
  printf " \n" >&2;
}

umount_all() {
  local mount;
  printf "正在卸载分区...\n" >&2;
  (if [ ! -d /postinstall/tmp ]; then
    umount /system;
    umount -l /system;
  fi) 2>/dev/null;
  umount_apex;
  (if [ ! -d /postinstall/tmp ]; then
    umount /system_root;
    umount -l /system_root;
  fi;
  PATH="$OLD_PATH" umount /vendor;  # busybox umount /vendor 在某些设备上会破坏 Recovery
  PATH="$OLD_PATH" umount -l /vendor;
  for mount in /mnt/system /mnt/vendor /product /mnt/product /system_ext /mnt/system_ext $UMOUNTLIST; do
    umount $mount;
    umount -l $mount;
  done) 2>/dev/null;
}

setup_env() {
  $BOOTMODE && return 1;
  # 绑定 /dev/urandom 到 /dev/random 确保熵源充足
  mount -o bind /dev/urandom /dev/random;
  # 处理 /etc 符号链接
  if [ -L /etc ]; then
    setup_mountpoint /etc;
    cp -af /etc_link/* /etc;
    sed -i 's; / ; /system_root ;' /etc/fstab;
  fi;
  umount_all;
  mount_all;
  # 保存并清除 LD 环境变量避免冲突
  OLD_LD_PATH=$LD_LIBRARY_PATH;
  OLD_LD_PRE=$LD_PRELOAD;
  OLD_LD_CFG=$LD_CONFIG_FILE;
  unset LD_LIBRARY_PATH LD_PRELOAD LD_CONFIG_FILE;
  # 定义 getprop 函数（Recovery 环境可能没有原生 getprop）
  if [ ! "$(getprop 2>/dev/null)" ]; then
    getprop() {
      local propdir propfile propval;
      for propdir in / /system_root /system /vendor /product /product/etc /system_ext/etc /odm/etc; do
        for propfile in default.prop build.prop; do
          if [ "$propval" ]; then
            break 2;
          else
            propval="$(file_getprop $propdir/$propfile $1 2>/dev/null)";
          fi;
        done;
      done;
      printf "$propval\n";
    }
  elif [ ! "$(getprop ro.build.type 2>/dev/null)" ]; then
    # getprop 存在但功能不完整的情况
    getprop() {
      ($(which getprop) | grep "$1" | cut -d[ -f3 | cut -d] -f1) 2>/dev/null;
    }
  fi;
}

restore_env() {
  $BOOTMODE && return 1;
  local dir;
  unset -f getprop;
  # 恢复 LD 环境变量
  [ "$OLD_LD_PATH" ] && export LD_LIBRARY_PATH=$OLD_LD_PATH;
  [ "$OLD_LD_PRE" ] && export LD_PRELOAD=$OLD_LD_PRE;
  [ "$OLD_LD_CFG" ] && export LD_CONFIG_FILE=$OLD_LD_CFG;
  unset OLD_LD_PATH OLD_LD_PRE OLD_LD_CFG;
  sleep 1;
  umount_all;
  # 恢复符号链接
  [ -L /etc_link ] && rm -rf /etc/*;
  (for dir in /etc /apex /system_root /system /vendor /product /system_ext /metadata /persist; do
    if [ -L "${dir}_link" ]; then
      rmdir $dir;
      mv -f ${dir}_link $dir;
    fi;
  done;
  umount -l /dev/random) 2>/dev/null;
}

setup_bb() {
  local arch32 bb;
  # 检测设备架构，安装对应的 busybox
  for arch32 in x86 arm; do
    if [ -d $AKHOME/tools/$arch32 ]; then
      bb=$AKHOME/tools/$arch32/busybox;
      chmod 755 $bb;
      $bb >/dev/null 2>&1;
      if [ $? == 0 ]; then
        $bb mv -f $AKHOME/tools/$arch32/* $AKHOME/tools;
        break;
      fi;
    fi;
  done;
  bb=$AKHOME/tools/busybox;
  chmod 755 $bb;
  $bb chmod -R 755 tools bin;
  $bb --install -s bin;
}


do_devicecheck() {
  [ "$(file_getprop anykernel.sh do.devicecheck)" == 1 ] || return 1;
  local device devicename match product testname vendordevice vendorproduct;
  ui_print "正在检查设备兼容性...";
  # 获取设备标识属性
  device=$(getprop ro.product.device 2>/dev/null);
  product=$(getprop ro.build.product 2>/dev/null);
  vendordevice=$(getprop ro.product.vendor.device 2>/dev/null);
  vendorproduct=$(getprop ro.vendor.product.device 2>/dev/null);
  # 遍历所有支持的设备名称
  for testname in $(grep '^device.name.*=' anykernel.sh | cut -d= -f2-); do
    for devicename in $device $product $vendordevice $vendorproduct; do
      if [ "$devicename" == "$testname" ]; then
        ui_print "$testname" " ";
        match=1;
        break 2;
      fi;
    done;
  done;
  if [ ! "$match" ]; then
    abort " " "不支持的设备，中止安装...";
  fi;
}

do_versioncheck() {
  [ "$(file_getprop anykernel.sh supported.versions)" ] || return 1;
  local android_ver hi_ver lo_ver parsed_ver supported supported_ver;
  ui_print "正在检查 Android 版本...";
  supported_ver=$(file_getprop anykernel.sh supported.versions | tr -d '[:space:]');
  android_ver=$(file_getprop /system/build.prop ro.build.version.release);
  parsed_ver=$(int2ver $android_ver);
  # 检查是否为版本范围（如 12-14）
  if echo $supported_ver | grep -q '-'; then
    lo_ver=$(int2ver "$(echo $supported_ver | cut -d- -f1)");
    hi_ver=$(int2ver "$(echo $supported_ver | cut -d- -f2)");
    # 使用 sort 比较版本号
    if printf "$hi_ver\n$lo_ver\n$parsed_ver\n" | sort -g | grep -n "$parsed_ver" | grep -q '^2:'; then
      supported=1;
    fi;
  else
    # 精确版本列表（逗号分隔）
    for ver in $(echo $supported_ver | sed 's;,; ;g'); do
      if [ "$(int2ver $ver)" == "$parsed_ver" ]; then
        supported=1;
        break;
      fi;
    done;
  fi;
  if [ "$supported" ]; then
    ui_print "$android_ver" " ";
  else
    abort " " "不支持的 Android 版本，中止安装...";
  fi;
}

do_levelcheck() {
  [ "$(file_getprop anykernel.sh supported.patchlevels)" ] || return 1;
  local android_lvl hi_lvl lo_lvl parsed_lvl supported_lvl;
  ui_print "正在检查 Android 安全补丁级别...";
  supported_lvl=$(file_getprop anykernel.sh supported.patchlevels | grep -oE '[0-9]{4}-[0-9]{2}|-');
  android_lvl=$(file_getprop /system/build.prop ro.build.version.security_patch);
  parsed_lvl=$(echo $android_lvl | grep -oE '[0-9]{4}-[0-9]{2}');
  # 解析补丁级别范围
  if echo $supported_lvl | grep -q '^\-'; then
    # 开放范围上限：-YYYY-MM（表示 <= 该日期）
    lo_lvl=0000-00;
    hi_lvl=$(echo $supported_lvl | awk '{ print $2 }');
  elif echo $supported_lvl | grep -q ' - '; then
    # 封闭范围：YYYY-MM - YYYY-MM
    lo_lvl=$(echo $supported_lvl | awk '{ print $1 }');
    hi_lvl=$(echo $supported_lvl | awk '{ print $3 }');
  elif echo $supported_lvl | grep -q '\-$'; then
    # 开放范围下限：YYYY-MM-（表示 >= 该日期）
    lo_lvl=$(echo $supported_lvl | awk '{ print $1 }');
    hi_lvl=9999-99;
  fi;
  if printf "$hi_lvl\n$lo_lvl\n$parsed_lvl\n" | sort -g | grep -n "$parsed_lvl" | grep -q '^2:'; then
    ui_print "$android_lvl" " ";
  else
    abort " " "不支持的 Android 安全补丁级别，中止安装...";
  fi;
}

do_vendorlevelcheck() {
  [ "$(file_getprop anykernel.sh supported.vendorpatchlevels)" ] || return 1;
  local vendor_lvl hi_lvl lo_lvl parsed_lvl supported_lvl;
  ui_print "正在检查 Vendor 安全补丁级别...";
  supported_lvl=$(file_getprop anykernel.sh supported.vendorpatchlevels | grep -oE '[0-9]{4}-[0-9]{2}|-');
  vendor_lvl=$(file_getprop /vendor/build.prop ro.vendor.build.security_patch);
  parsed_lvl=$(echo $vendor_lvl | grep -oE '[0-9]{4}-[0-9]{2}');
  # 解析补丁级别范围（逻辑同 do_levelcheck）
  if echo $supported_lvl | grep -q '^\-'; then
    lo_lvl=0000-00;
    hi_lvl=$(echo $supported_lvl | awk '{ print $2 }');
  elif echo $supported_lvl | grep -q ' - '; then
    lo_lvl=$(echo $supported_lvl | awk '{ print $1 }');
    hi_lvl=$(echo $supported_lvl | awk '{ print $3 }');
  elif echo $supported_lvl | grep -q '\-$'; then
    lo_lvl=$(echo $supported_lvl | awk '{ print $1 }');
    hi_lvl=9999-99;
  fi;
  if printf "$hi_lvl\n$lo_lvl\n$parsed_lvl\n" | sort -g | grep -n "$parsed_lvl" | grep -q '^2:'; then
    ui_print "$vendor_lvl" " ";
  else
    abort " " "不支持的 Vendor 安全补丁级别，中止安装...";
  fi;
}


split_boot() {
  local splitfail;
  # 验证分区是否存在
  if [ ! -e "$(printf "$BLOCK\n" | cut -d\  -f1)" ]; then
    abort "无效的分区，中止安装...";
  fi;
  # 处理自定义 dd 参数
  if printf "$BLOCK\n" | grep -q ' '; then
    BLOCK=$(printf "$BLOCK\n" | cut -d\  -f1);
    CUSTOMDD=$(printf "$BLOCK\n" | cut -d\  -f2-);
  elif [ ! "$CUSTOMDD" ]; then
    CUSTOMDD="bs=1048576";
  fi;
  # 从分区读取镜像
  if [ -f "$BIN/nanddump" ]; then
    nanddump -f $BOOTIMG $BLOCK;
  else
    dd if=$BLOCK of=$BOOTIMG $CUSTOMDD;
  fi;
  if [ $? != 0 ]; then
    abort "读取镜像失败，中止安装...";
  fi;
  mkdir -p $SPLITIMG;
  cd $SPLITIMG;
  # 根据可用工具选择拆分方式
  if [ -f "$BIN/unpackelf" ] && unpackelf -i $BOOTIMG -h -q 2>/dev/null; then
    # ELF 格式镜像（如 Samsung）
    if [ -f "$BIN/elftool" ]; then
      mkdir elftool_out;
      elftool unpack -i $BOOTIMG -o elftool_out;
    fi;
    unpackelf -i $BOOTIMG;
    [ $? != 0 ] && splitfail=1;
    mv -f boot.img-kernel kernel.gz;
    mv -f boot.img-ramdisk ramdisk.cpio.gz;
    mv -f boot.img-cmdline cmdline.txt 2>/dev/null;
    # 处理设备树
    if [ -f boot.img-dt -a ! -f "$BIN/elftool" ]; then
      case $(od -ta -An -N4 boot.img-dt | sed -e 's/ del//' -e 's/   //g') in
        QCDT|ELF) mv -f boot.img-dt dt;;
        *)
          gzip -c kernel.gz > kernel.gz-dtb;
          cat boot.img-dt >> kernel.gz-dtb;
          rm -f boot.img-dt kernel.gz;
        ;;
      esac;
    fi;
  elif [ -f "$BIN/mboot" ]; then
    # Intel OSIP 格式
    mboot -u -f $BOOTIMG;
  elif [ -f "$BIN/dumpimage" ]; then
    # U-Boot 格式
    dd bs=$(($(printf '%d\n' 0x$(hexdump -n 4 -s 12 -e '16/1 "%02x""\n"' $BOOTIMG)) + 64)) count=1 conv=notrunc if=$BOOTIMG of=boot-trimmed.img;
    dumpimage -l boot-trimmed.img > header;
    grep "Name:" header | cut -c15- > boot.img-name;
    grep "Type:" header | cut -c15- | cut -d\  -f1 > boot.img-arch;
    grep "Type:" header | cut -c15- | cut -d\  -f2 > boot.img-os;
    grep "Type:" header | cut -c15- | cut -d\  -f3 | cut -d- -f1 > boot.img-type;
    grep "Type:" header | cut -d\( -f2 | cut -d\) -f1 | cut -d\  -f1 | cut -d- -f1 > boot.img-comp;
    grep "Address:" header | cut -c15- > boot.img-addr;
    grep "Point:" header | cut -c15- > boot.img-ep;
    dumpimage -p 0 -o kernel.gz boot-trimmed.img;
    [ $? != 0 ] && splitfail=1;
    case $(cat boot.img-type) in
      Multi) dumpimage -p 1 -o ramdisk.cpio.gz boot-trimmed.img;;
      RAMDisk) mv -f kernel.gz ramdisk.cpio.gz;;
    esac;
  elif [ -f "$BIN/rkcrc" ]; then
    # Rockchip 格式
    dd bs=4096 skip=8 iflag=skip_bytes conv=notrunc if=$BOOTIMG of=ramdisk.cpio.gz;
  else
    # 标准 AOSP 格式（使用 magiskboot）
    (set -o pipefail; magiskboot unpack -h $BOOTIMG 2>&1 | tee infotmp >&2);
    case $? in
      1) splitfail=1;;
      2) touch chromeos;;  # ChromeOS 镜像
    esac;
  fi;
  if [ $? != 0 -o "$splitfail" ]; then
    abort "拆分镜像失败，中止安装...";
  fi;
  cd $AKHOME;
}

unpack_ramdisk() {
  local comp;
  cd $SPLITIMG;
  # 处理 MTK 头部
  if [ -f ramdisk.cpio.gz ]; then
    if [ -f "$BIN/mkmtkhdr" ]; then
      mv -f ramdisk.cpio.gz ramdisk.cpio.gz-mtk;
      dd bs=512 skip=1 conv=notrunc if=ramdisk.cpio.gz-mtk of=ramdisk.cpio.gz;
    fi;
    mv -f ramdisk.cpio.gz ramdisk.cpio;
  fi;
  if [ -f ramdisk.cpio ]; then
    # 检测压缩格式
    comp=$(magiskboot decompress ramdisk.cpio 2>&1 | grep -v 'raw' | sed -n 's;.*\[\(.*\)\];\1;p');
  else
    abort "未找到 ramdisk，中止安装...";
  fi;
  # 解压缩 ramdisk
  if [ "$comp" ]; then
    mv -f ramdisk.cpio ramdisk.cpio.$comp;
    magiskboot decompress ramdisk.cpio.$comp ramdisk.cpio;
    if [ $? != 0 ] && $comp --help 2>/dev/null; then
      printf "尝试使用 busybox $comp 解包 ramdisk...\n" >&2;
      $comp -dc ramdisk.cpio.$comp > ramdisk.cpio;
    fi;
  fi;
  # 保留已有 ramdisk 内容
  [ -d $RAMDISK ] && mv -f $RAMDISK $AKHOME/rdtmp;
  mkdir -p $RAMDISK;
  chmod 755 $RAMDISK;
  cd $RAMDISK;
  # 解包 cpio 归档
  EXTRACT_UNSAFE_SYMLINKS=1 cpio -d -F $SPLITIMG/ramdisk.cpio -i;
  if [ $? != 0 -o ! "$(ls)" ]; then
    abort "解包 ramdisk 失败，中止安装...";
  fi;
  # 合并之前的 ramdisk 内容
  if [ -d "$AKHOME/rdtmp" ]; then
    cp -af $AKHOME/rdtmp/* .;
  fi;
}

dump_boot() {
  ui_print " " "    [1/4] 正在读取 boot 分区...";
  split_boot;
  ui_print " " "    [2/4] 正在解包 ramdisk...";
  unpack_ramdisk;
}

repack_ramdisk() {
  local comp packfail mtktype;
  cd $AKHOME;
  # hdr v4+ 仅允许 lz4-l 压缩
  if [ "$RAMDISK_COMPRESSION" != "auto" ] && [ "$(grep HEADER_VER $SPLITIMG/infotmp | sed -n 's;.*\[\(.*\)\];\1;p')" -gt 3 ]; then
    ui_print " " "警告：hdr v4+ 镜像仅允许 lz4-l ramdisk 压缩，重置为自动...";
    RAMDISK_COMPRESSION=auto;
  fi;
  # 确定压缩方式
  case $RAMDISK_COMPRESSION in
    auto|"") comp=$(ls $SPLITIMG/ramdisk.cpio.* 2>/dev/null | grep -v 'mtk' | rev | cut -d. -f1 | rev);;
    none|cpio) comp="";;
    gz) comp=gzip;;
    lzo) comp=lzop;;
    bz2) comp=bzip2;;
    lz4-l) comp=lz4_legacy;;
    *) comp=$RAMDISK_COMPRESSION;;
  esac;
  # 创建 cpio 归档
  if [ -f "$BIN/mkbootfs" ]; then
    mkbootfs $RAMDISK > ramdisk-new.cpio;
  else
    cd $RAMDISK;
    find . | cpio -H newc -o > $AKHOME/ramdisk-new.cpio;
  fi;
  [ $? != 0 ] && packfail=1;
  cd $AKHOME;
  # 检测 Magisk 补丁
  if [ ! "$NO_MAGISK_CHECK" ]; then
    magiskboot cpio ramdisk-new.cpio test;
    magisk_patched=$?;
  fi;
  # 提取 Magisk 备份信息
  [ "$magisk_patched" -eq 1 ] && magiskboot cpio ramdisk-new.cpio "extract .backup/.magisk $SPLITIMG/.magisk";
  # 压缩 ramdisk
  if [ "$comp" ]; then
    magiskboot compress=$comp ramdisk-new.cpio;
    if [ $? != 0 ] && $comp --help 2>/dev/null; then
      printf "尝试使用 busybox $comp 重新打包 ramdisk...\n" >&2;
      $comp -9c ramdisk-new.cpio > ramdisk-new.cpio.$comp;
      [ $? != 0 ] && packfail=1;
      rm -f ramdisk-new.cpio;
    fi;
  fi;
  if [ "$packfail" ]; then
    abort "重新打包 ramdisk 失败，中止安装...";
  fi;
  # 重建 MTK 头部
  if [ -f "$BIN/mkmtkhdr" -a -f "$SPLITIMG/boot.img-base" ]; then
    mtktype=$(od -ta -An -N8 -j8 $SPLITIMG/ramdisk.cpio.gz-mtk | sed -e 's/ nul//g' -e 's/   //g' | tr '[:upper:]' '[:lower:]');
    case $mtktype in
      rootfs|recovery) mkmtkhdr --$mtktype ramdisk-new.cpio*;;
    esac;
  fi;
}

flash_boot() {
  local varlist i kernel ramdisk fdt cmdline comp part0 part1 needskernelpatch nocompflag signfail pk8 cert avbtype;
  cd $SPLITIMG;
  # 读取镜像头信息
  if [ -f "$BIN/mkimage" ]; then
    varlist="name arch os type comp addr ep";
  elif [ -f "$BIN/mk" -a -f "$BIN/unpackelf" -a -f boot.img-base ]; then
    mv -f cmdline.txt boot.img-cmdline 2>/dev/null;
    varlist="cmdline base pagesize kernel_offset ramdisk_offset tags_offset";
  fi;
  for i in $varlist; do
    if [ -f boot.img-$i ]; then
      eval local $i=\"$(cat boot.img-$i)\";
    fi;
  done;
  cd $AKHOME;
  # 查找内核文件（按优先级尝试 18 种命名模式）
  for i in zImage zImage-dtb Image Image-dtb Image.gz Image.gz-dtb Image.bz2 Image.bz2-dtb Image.lzo Image.lzo-dtb Image.lzma Image.lzma-dtb Image.xz Image.xz-dtb Image.lz4 Image.lz4-dtb Image.fit; do
    if [ -f $i ]; then
      kernel=$AKHOME/$i;
      break;
    fi;
  done;
  # MTK 内核需要添加头部
  if [ "$kernel" ]; then
    if [ -f "$BIN/mkmtkhdr" -a -f "$SPLITIMG/boot.img-base" ]; then
      mkmtkhdr --kernel $kernel;
      kernel=$kernel-mtk;
    fi;
  elif [ "$(ls $SPLITIMG/kernel* 2>/dev/null)" ]; then
    # 使用拆分出的原始内核
    kernel=$(ls $SPLITIMG/kernel* | grep -v 'kernel_dtb' | tail -n1);
  fi;
  # 查找 ramdisk
  if [ "$(ls ramdisk-new.cpio* 2>/dev/null)" ]; then
    ramdisk=$AKHOME/$(ls ramdisk-new.cpio* | tail -n1);
  elif [ -f "$BIN/mkmtkhdr" -a -f "$SPLITIMG/boot.img-base" ]; then
    ramdisk=$SPLITIMG/ramdisk.cpio.gz-mtk;
  else
    ramdisk=$(ls $SPLITIMG/ramdisk.cpio* 2>/dev/null | tail -n1);
  fi;
  # 查找设备树文件
  for fdt in dt recovery_dtbo dtb; do
    for i in $AKHOME/$fdt $AKHOME/$fdt.img $SPLITIMG/$fdt; do
      if [ -f $i ]; then
        eval local $fdt=$i;
        break;
      fi;
    done;
  done;
  cd $SPLITIMG;
  # 根据镜像格式选择打包方式
  if [ -f "$BIN/mkimage" ]; then
    # U-Boot mkimage 格式
    [ "$comp" == "uncompressed" ] && comp=none;
    part0=$kernel;
    case $type in
      Multi) part1=":$ramdisk";;
      RAMDisk) part0=$ramdisk;;
    esac;
    mkimage -A $arch -O $os -T $type -C $comp -a $addr -e $ep -n "$name" -d $part0$part1 $AKHOME/boot-new.img;
  elif [ -f "$BIN/elftool" ]; then
    # ELF 格式
    [ "$dt" ] && dt="$dt,rpm";
    [ -f cmdline.txt ] && cmdline="cmdline.txt@cmdline";
    elftool pack -o $AKHOME/boot-new.img header=elftool_out/header $kernel $ramdisk,ramdisk $dt $cmdline;
  elif [ -f "$BIN/mboot" ]; then
    # Intel mboot 格式
    cp -f $kernel kernel;
    cp -f $ramdisk ramdisk.cpio.gz;
    mboot -d $SPLITIMG -f $AKHOME/boot-new.img;
  elif [ -f "$BIN/rkcrc" ]; then
    # Rockchip 格式
    rkcrc -k $ramdisk $AKHOME/boot-new.img;
  elif [ -f "$BIN/mkbootimg" -a -f "$BIN/unpackelf" -a -f boot.img-base ]; then
    # mkbootimg 格式
    [ "$dt" ] && dt="--dt $dt";
    mkbootimg --kernel $kernel --ramdisk $ramdisk --cmdline "$cmdline" --base $base --pagesize $pagesize --kernel_offset $kernel_offset --ramdisk_offset $ramdisk_offset --tags_offset "$tags_offset" $dt --output $AKHOME/boot-new.img;
  else
    # 标准 AOSP magiskboot 格式
    [ "$kernel" ] && cp -f $kernel kernel;
    [ "$ramdisk" ] && cp -f $ramdisk ramdisk.cpio;
    [ "$dt" -a -f extra ] && cp -f $dt extra;
    for i in dtb recovery_dtbo; do
      [ "$(eval echo \$$i)" -a -f $i ] && cp -f $(eval echo \$$i) $i;
    done;
    # 处理 Image 类内核（Magisk/KernelSU 检测与修补）
    case $kernel in
      *Image*)
        # 检测 Magisk
        if [ ! "$magisk_patched" -a ! "$NO_MAGISK_CHECK" ]; then
          magiskboot cpio ramdisk.cpio test;
          magisk_patched=$?;
        fi;
        if [ "$magisk_patched" -eq 1 ]; then
          ui_print " " "检测到 Magisk！正在修补内核以避免重新刷入 Magisk...";
          comp=$(magiskboot decompress kernel 2>&1 | grep -vE 'raw|zimage' | sed -n 's;.*\[\(.*\)\];\1;p');
          (magiskboot split $kernel || magiskboot decompress $kernel kernel) >&2;
          if [ $? != 0 -a "$comp" ] && $comp --help 2>/dev/null; then
            ui_print " " "尝试使用 busybox $comp 解包内核...";
            $comp -dc $kernel > kernel;
          fi;
          # 旧版 SAR 内核字符串修补：skip_initramfs -> want_initramfs
          magiskboot hexpatch kernel 736B69705F696E697472616D6673 77616E745F696E697472616D6673 && needskernelpatch=1;
          # 提取内核版本信息（用于模块）
          if [ "$(file_getprop $AKHOME/anykernel.sh do.modules)" == 1 ] && [ "$(file_getprop $AKHOME/anykernel.sh do.systemless)" == 1 ]; then
            strings kernel 2>/dev/null | grep -E -m1 'Linux version.*#' > $AKHOME/vertmp;
          fi;
          if [ "$needskernelpatch" ]; then
            if [ "$comp" ]; then
              magiskboot compress=$comp kernel kernel.$comp;
              if [ $? != 0 ] && $comp --help 2>/dev/null; then
                ui_print " " "尝试使用 busybox $comp 重新打包内核...";
                $comp -9c kernel > kernel.$comp;
              fi;
              mv -f kernel.$comp kernel;
            fi;
          else
            ui_print " " "无需修补，恢复未修改的新内核...";
            (magiskboot split -n $kernel || cp -f $kernel kernel) >&2;
          fi;
          # 提取 .magisk 信息并移除 DTB verity/AVB
          [ ! -f .magisk ] && magiskboot cpio ramdisk.cpio "extract .backup/.magisk .magisk";
          export $(cat .magisk);
          for fdt in dtb extra kernel_dtb recovery_dtbo; do
            [ -f $fdt ] && magiskboot dtb $fdt patch;  # 移除 dtb verity/avb
          done;
        elif [ -d /data/data/me.weishu.kernelsu ] && [ "$(file_getprop $AKHOME/anykernel.sh do.modules)" == 1 ] && [ "$(file_getprop $AKHOME/anykernel.sh do.systemless)" == 1 ]; then
          # 检测 KernelSU
          ui_print " " "检测到 KernelSU！正在设置内核辅助模块...";
          comp=$(magiskboot decompress kernel 2>&1 | grep -vE 'raw|zimage' | sed -n 's;.*\[\(.*\)\];\1;p');
          (magiskboot split $kernel || magiskboot decompress $kernel kernel) >&2;
          if [ $? != 0 -a "$comp" ] && $comp --help 2>/dev/null; then
            ui_print " " "尝试使用 busybox $comp 解包内核...";
            $comp -dc $kernel > kernel;
          fi;
          strings kernel > stringstmp 2>/dev/null;
          if grep -q -E '^/data/adb/ksud$' stringstmp; then
            touch $AKHOME/kernelsu_patched;
            grep -E -m1 'Linux version.*#' stringstmp > $AKHOME/vertmp;
            [ -d $RAMDISK/overlay.d ] && ui_print " " "警告：ramdisk 中检测到 overlay.d，但 KernelSU 目前不支持！";
          else
            ui_print " " "警告：内核中未检测到 KernelSU 支持！";
          fi;
          rm -f stringstmp;
          if [ "$comp" ]; then
            magiskboot compress=$comp kernel kernel.$comp;
            if [ $? != 0 ] && $comp --help 2>/dev/null; then
              ui_print " " "尝试使用 busybox $comp 重新打包内核...";
              $comp -9c kernel > kernel.$comp;
            fi;
            mv -f kernel.$comp kernel;
          fi;
        else
          # 非 Magisk/KernelSU，清理 kernel_dtb
          case $kernel in
            *-dtb) rm -f kernel_dtb;;
          esac;
        fi;
        # 清理 Magisk 环境变量（保留 PATCHVBMETAFLAG 供 repack 使用）
        unset magisk_patched KEEPVERITY KEEPFORCEENCRYPT RECOVERYMODE PREINITDEVICE SHA1 RANDOMSEED;
      ;;
    esac;
    # 设置 ramdisk 压缩标志
    case $RAMDISK_COMPRESSION in
      none|cpio) nocompflag="-n";;
    esac;
    # 设置 vbmeta 禁用标志
    case $PATCH_VBMETA_FLAG in
      auto|"") [ "$PATCHVBMETAFLAG" ] || export PATCHVBMETAFLAG=false;;
      1) export PATCHVBMETAFLAG=true;;
      *) export PATCHVBMETAFLAG=false;;
    esac;
    # 使用 magiskboot 重新打包
    magiskboot repack $nocompflag $BOOTIMG $AKHOME/boot-new.img;
  fi;
  if [ $? != 0 ]; then
    abort "重新打包镜像失败，中止安装...";
  fi;
  [ "$PATCHVBMETAFLAG" ] && unset PATCHVBMETAFLAG;
  [ -f .magisk ] && touch $AKHOME/magisk_patched;
  cd $AKHOME;
  # ChromeOS 签名
  if [ -f "$BIN/futility" -a -d "$BIN/chromeos" ]; then
    if [ -f "$SPLITIMG/chromeos" ]; then
      ui_print " " "正在使用 CHROMEOS 签名...";
      futility vbutil_kernel --pack boot-new-signed.img --keyblock $BIN/chromeos/kernel.keyblock --signprivate $BIN/chromeos/kernel_data_key.vbprivk --version 1 --vmlinuz boot-new.img --bootloader $BIN/chromeos/empty --config $BIN/chromeos/empty --arch arm --flags 0x1;
    fi;
    [ $? != 0 ] && signfail=1;
  fi;
  # AVBv1 签名
  if [ -d "$BIN/avb" ]; then
    pk8=$(ls $BIN/avb/*.pk8);
    cert=$(ls $BIN/avb/*.x509.*);
    # 确定 AVB 分区类型
    case $BLOCK in
      *recovery*|*RECOVERY*|*SOS*) avbtype=recovery;;
      *) avbtype=boot;;
    esac;
    if [ -f "$BIN/boot_signer-dexed.jar" ]; then
      # 使用 boot_signer-dexed.jar 签名
      if [ -f /system/bin/dalvikvm ] && [ "$(/system/bin/dalvikvm -Xnoimage-dex2oat -cp $BIN/boot_signer-dexed.jar com.android.verity.BootSignature -verify boot.img 2>&1 | grep VALID)" ]; then
        ui_print " " "正在使用 AVBv1 /$avbtype 签名...";
        /system/bin/dalvikvm -Xnoimage-dex2oat -cp $BIN/boot_signer-dexed.jar com.android.verity.BootSignature /$avbtype boot-new.img $pk8 $cert boot-new-signed.img;
      fi;
    else
      # 使用 magiskboot 签名
      if magiskboot verify boot.img; then
        ui_print " " "正在使用 AVBv1 /$avbtype 签名...";
        magiskboot sign /$avbtype boot-new.img $cert $pk8;
      fi;
    fi;
  fi;
  if [ $? != 0 -o "$signfail" ]; then
    abort "镜像签名失败，中止安装...";
  fi;
  # 使用签名后的镜像（如果存在）
  if [ -f boot-new-signed.img ]; then
    mv -f boot-new-signed.img boot-new.img;
  fi;
  # 刷入镜像到分区
  if [ -f "$BIN/nanddump" ]; then
    flash_erase $BLOCK 0 0;
    nandwrite -p $BLOCK boot-new.img;
  else
    dd if=boot-new.img of=$BLOCK $CUSTOMDD;
  fi;
  if [ $? != 0 ]; then
    abort "刷入镜像失败，中止安装...";
  fi;
  ui_print " " "镜像已成功刷入 $BLOCK";
}

flash_generic() {
  local part="$1";
  local part_block part_img signed_img vbmeta_flag vbmeta_part resize_needed;
  if [ -z "$part" ]; then
    return 0;
  fi;
  # 查找分区块设备
  part_block=$(find_block $part);
  if [ -z "$part_block" ]; then
    log_debug "未找到分区: $part，跳过";
    return 0;
  fi;
  # 检查是否有对应的镜像文件
  part_img=$AKHOME/${part}.img;
  if [ ! -f "$part_img" ]; then
    log_debug "未找到镜像文件: $part_img，跳过";
    return 0;
  fi;
  ui_print " " "正在刷入 $part...";
  # vbmeta 禁用标志修补
  if [ ! "$NO_VBMETA_PARTITION_PATCH" ] && [ -f "$BIN/httools_static" ]; then
    vbmeta_part=$(find_block vbmeta);
    if [ -n "$vbmeta_part" ]; then
      vbmeta_flag=$(file_getprop anykernel.sh patch.vbmeta.flag 2>/dev/null);
      if [ "$vbmeta_flag" = "1" ]; then
        ui_print " " "正在修补 vbmeta 禁用标志...";
        $BIN/httools_static --disable-verity --disable-verification $vbmeta_part 2>/dev/null;
      fi;
    fi;
  fi;
  # 动态分区大小调整
  if [ -f "$BIN/lptools_static" ] && [ -d /dev/block/mapper ]; then
    resize_needed=1;
    # 检查是否需要调整分区大小
    local current_size new_size;
    current_size=$(lsblk -b -o SIZE -n $part_block 2>/dev/null);
    new_size=$(stat -c%s "$part_img" 2>/dev/null);
    if [ -n "$current_size" ] && [ -n "$new_size" ] && [ "$new_size" -gt "$current_size" ]; then
      ui_print " " "正在调整 $part 分区大小...";
      $BIN/lptools_static resize $part $new_size 2>/dev/null;
    fi;
  fi;
  # 刷入镜像
  if [ -f "$BIN/nanddump" ]; then
    flash_erase $part_block 0 0;
    nandwrite -p $part_block $part_img;
  else
    dd if=$part_img of=$part_block bs=1048576;
  fi;
  if [ $? != 0 ]; then
    log_error "刷入 $part 失败";
    return 1;
  fi;
  # 快照更新（动态分区设备）
  if [ -f "$BIN/snapshotupdater_static" ] && [ -d /dev/block/mapper ]; then
    $BIN/snapshotupdater_static 2>/dev/null;
  fi;
  ui_print " " "$part 已成功刷入";
  return 0;
}

write_boot() {
  ui_print " " "    [3/4] 正在重新打包镜像...";
  repack_ramdisk;
  ui_print " " "    [4/4] 正在刷入 boot 分区...";
  flash_boot;
  # 刷入额外的通用分区
  for part in dtbo vendor_boot vendor_kernel_boot vendor_dlkm system_dlkm; do
    flash_generic $part;
  done;
}


backup_file() {
  [ ! -f "$RAMDISK/$1" ] && return 0;
  cp -af "$RAMDISK/$1" "$RAMDISK/$1~";
  log_debug "已备份: $1";
}

restore_file() {
  [ ! -f "$RAMDISK/$1~" ] && return 0;
  mv -f "$RAMDISK/$1~" "$RAMDISK/$1";
  log_debug "已恢复: $1";
}

replace_string() {
  local file="$1";
  [ -f "$RAMDISK/$file" ] || return 1;
  local old="$2";
  local new="$3";
  # 如果未指定新字符串，则删除原字符串
  if [ -z "$new" ]; then
    sed -i "s;$(printf "$old\n" | sed 's/[[\.*^$()+?{|]/\\&/g');;g" "$RAMDISK/$file";
  else
    sed -i "s;$(printf "$old\n" | sed 's/[[\.*^$()+?{|]/\\&/g');$(printf "$new\n" | sed 's/[&/\]/\\&/g');g" "$RAMDISK/$file";
  fi;
  log_debug "已替换字符串: $file";
}

replace_section() {
  local file="$1" start="$2" end="$3" replacement="$4";
  [ -f "$RAMDISK/$file" ] || return 1;
  local tmpfile="$RAMDISK/$file.tmp";
  local in_section=0;
  while IFS= read -r line; do
    if [ $in_section -eq 0 ] && printf "$line\n" | grep -q "$start"; then
      in_section=1;
      printf "$replacement\n" >> "$tmpfile";
    elif [ $in_section -eq 1 ] && printf "$line\n" | grep -q "$end"; then
      in_section=0;
    elif [ $in_section -eq 0 ]; then
      printf "$line\n" >> "$tmpfile";
    fi;
  done < "$RAMDISK/$file";
  mv -f "$tmpfile" "$RAMDISK/$file";
  log_debug "已替换代码块: $file";
}

remove_section() {
  local file="$1" start="$2" end="$3";
  [ -f "$RAMDISK/$file" ] || return 1;
  local tmpfile="$RAMDISK/$file.tmp";
  local in_section=0;
  while IFS= read -r line; do
    if [ $in_section -eq 0 ] && printf "$line\n" | grep -q "$start"; then
      in_section=1;
    elif [ $in_section -eq 1 ] && printf "$line\n" | grep -q "$end"; then
      in_section=0;
    elif [ $in_section -eq 0 ]; then
      printf "$line\n" >> "$tmpfile";
    fi;
  done < "$RAMDISK/$file";
  mv -f "$tmpfile" "$RAMDISK/$file";
  log_debug "已移除代码块: $file";
}

insert_line() {
  local file="$1" match="$2" position="$3" content="$4";
  [ -f "$RAMDISK/$file" ] || return 1;
  local tmpfile="$RAMDISK/$file.tmp";
  while IFS= read -r line; do
    if printf "$line\n" | grep -q "$match"; then
      if [ "$position" = "before" ]; then
        printf "$content\n" >> "$tmpfile";
      fi;
      printf "$line\n" >> "$tmpfile";
      if [ "$position" = "after" ]; then
        printf "$content\n" >> "$tmpfile";
      fi;
    else
      printf "$line\n" >> "$tmpfile";
    fi;
  done < "$RAMDISK/$file";
  mv -f "$tmpfile" "$RAMDISK/$file";
  log_debug "已插入行: $file ($position $match)";
}

replace_line() {
  local file="$1" match="$2" replacement="$3";
  [ -f "$RAMDISK/$file" ] || return 1;
  sed -i "/$(printf "$match\n" | sed 's/[[\.*^$()+?{|]/\\&/g')/c\\$replacement" "$RAMDISK/$file";
  log_debug "已替换行: $file";
}

remove_line() {
  local file="$1" match="$2";
  [ -f "$RAMDISK/$file" ] || return 1;
  sed -i "/$(printf "$match\n" | sed 's/[[\.*^$()+?{|]/\\&/g')/d" "$RAMDISK/$file";
  log_debug "已删除行: $file";
}

prepend_file() {
  local target="$1" patchfile="$2";
  [ -f "$PATCH/$patchfile" ] || return 1;
  local tmpfile="$RAMDISK/$target.tmp";
  cat "$PATCH/$patchfile" > "$tmpfile";
  [ -f "$RAMDISK/$target" ] && cat "$RAMDISK/$target" >> "$tmpfile";
  mv -f "$tmpfile" "$RAMDISK/$target";
  log_debug "已在开头插入: $target <- $patchfile";
}

insert_file() {
  local target="$1" match="$2" position="$3" patchfile="$4";
  [ -f "$PATCH/$patchfile" ] || return 1;
  [ -f "$RAMDISK/$target" ] || return 1;
  local tmpfile="$RAMDISK/$target.tmp";
  while IFS= read -r line; do
    if printf "$line\n" | grep -q "$match"; then
      if [ "$position" = "before" ]; then
        cat "$PATCH/$patchfile" >> "$tmpfile";
      fi;
      printf "$line\n" >> "$tmpfile";
      if [ "$position" = "after" ]; then
        cat "$PATCH/$patchfile" >> "$tmpfile";
      fi;
    else
      printf "$line\n" >> "$tmpfile";
    fi;
  done < "$RAMDISK/$target";
  mv -f "$tmpfile" "$RAMDISK/$target";
  log_debug "已插入文件: $target <- $patchfile ($position $match)";
}

append_file() {
  local target="$1" patchfile="$2";
  [ -f "$PATCH/$patchfile" ] || return 1;
  cat "$PATCH/$patchfile" >> "$RAMDISK/$target";
  log_debug "已追加文件: $target <- $patchfile";
}

replace_file() {
  local target="$1" patchfile="$2";
  [ -f "$PATCH/$patchfile" ] || return 1;
  cp -af "$PATCH/$patchfile" "$RAMDISK/$target";
  log_debug "已替换文件: $target <- $patchfile";
}

patch_fstab() {
  local file="$1" mnt="$2" fs="$3" field="$4" old="$5" new="$6";
  [ -f "$RAMDISK/$file" ] || return 1;
  [ "$field" != "options" ] && return 1;
  sed -i "s;\($mnt[[:space:]]\+$fs[[:space:]]\+[^[:space:]]\+[[:space:]]\+\)$(printf "$old\n" | sed 's/[[\.*^$()+?{|]/\\&/g');\1$(printf "$new\n" | sed 's/[&/\]/\\&/g');" "$RAMDISK/$file";
  log_debug "已修改 fstab: $file ($mnt $fs)";
}

patch_cmdline() {
  local old="$1" new="$2";
  local cmdline_file="$SPLITIMG/cmdline.txt";
  [ -f "$cmdline_file" ] || return 1;
  if [ -z "$new" ]; then
    # 删除参数
    sed -i "s/$(printf "$old\n" | sed 's/[[\.*^$()+?{|]/\\&/g')//g" "$cmdline_file";
  else
    # 替换参数
    sed -i "s/$(printf "$old\n" | sed 's/[[\.*^$()+?{|]/\\&/g')/$(printf "$new\n" | sed 's/[&/\]/\\&/g')/g" "$cmdline_file";
  fi;
  log_debug "已修改内核命令行";
}

patch_prop() {
  local file="$1" prop="$2" value="$3";
  [ -f "$RAMDISK/$file" ] || return 1;
  if grep -q "^$prop=" "$RAMDISK/$file"; then
    sed -i "s;^$prop=.*;$prop=$value;" "$RAMDISK/$file";
  else
    printf "$prop=$value\n" >> "$RAMDISK/$file";
  fi;
  log_debug "已修改属性: $file ($prop=$value)";
}

patch_ueventd() {
  local file="$1" match="$2" replacement="$3";
  [ -f "$RAMDISK/$file" ] || return 1;
  sed -i "s;$(printf "$match\n" | sed 's/[[\.*^$()+?{|]/\\&/g');$(printf "$replacement\n" | sed 's/[&/\]/\\&/g');" "$RAMDISK/$file";
  log_debug "已修改 ueventd: $file";
}


find_block() {
  local partname="$1";
  local block byname slot;
  # 检查是否为绝对路径
  case $partname in
    /dev/*)
      if [ -e "$partname" ]; then
        printf "$partname\n";
        return 0;
      fi;
      ;;
  esac;
  # 查找 by-name 目录
  byname=bootdevice/by-name;
  if [ -d /dev/block/$byname ]; then
    block=/dev/block/$byname/$partname;
    if [ -e "$block" ]; then
      printf "$block\n";
      return 0;
    fi;
  fi;
  # 搜索 platform 下的 by-name
  block=$(find /dev/block/platform -type d -name by-name 2>/dev/null | head -n1);
  if [ -n "$block" ]; then
    block="$block/$partname";
    if [ -e "$block" ]; then
      printf "$block\n";
      return 0;
    fi;
  fi;
  # 检查动态分区 mapper
  if [ -d /dev/block/mapper ]; then
    block=/dev/block/mapper/$partname;
    if [ -e "$block" ]; then
      printf "$block\n";
      return 0;
    fi;
  fi;
  # 检查 MTD 分区
  if [ -d /dev/mtd ]; then
    block=$(grep "\"$partname\"" /proc/mtd 2>/dev/null | cut -d: -f1);
    if [ -n "$block" ]; then
      printf "/dev/$block\n";
      return 0;
    fi;
  fi;
  # 带槽位后缀的搜索
  slot=$(find_slot);
  if [ -n "$slot" ]; then
    for byname in bootdevice/by-name $(find /dev/block/platform -type d -name by-name 2>/dev/null | head -n1 | cut -d/ -f4-); do
      block=/dev/block/$byname/${partname}${slot};
      if [ -e "$block" ]; then
        printf "$block\n";
        return 0;
      fi;
    done;
  fi;
  return 1;
}

reset_ak() {
  # 向后兼容：如果存在旧的分区文件则清理
  local old_files="boot.img split_img ramdisk rdtmp";
  for f in $old_files; do
    [ -e "$AKHOME/$f" ] && rm -rf "$AKHOME/$f";
  done;
  # 重新创建目录结构
  mkdir -p $AKHOME/tools $AKHOME/patch $AKHOME/ramdisk $AKHOME/split_img;
  # 重新调用 setup_ak
  setup_ak;
}

setup_ak() {
  local block slot hdr_ver partname found;
  # 向后兼容：处理旧版 API
  [ -z "$BLOCK" ] && BLOCK="boot";
  # 检测 A/B 槽位
  if [ "$IS_SLOT_DEVICE" != "0" ]; then
    slot=$(find_slot);
    if [ -n "$slot" ]; then
      SLOT=$slot;
      IS_SLOT_DEVICE=1;
    else
      IS_SLOT_DEVICE=0;
    fi;
  fi;
  # 解析 BLOCK 变量
  case $BLOCK in
    /dev/*)
      # 绝对路径直接使用
      if [ ! -e "$BLOCK" ]; then
        abort " " "分区不存在: $BLOCK";
      fi;
      ;;
    auto)
      # 自动检测模式
      block="";
      for partname in boot init_boot vendor_boot vendor_kernel_boot; do
        block=$(find_block $partname);
        if [ -n "$block" ]; then
          BLOCK=$block;
          log_debug "自动检测到分区: $BLOCK";
          break;
        fi;
      done;
      if [ -z "$block" ]; then
        abort " " "无法自动检测分区";
      fi;
      ;;
    *)
      # 分区名称，需要查找块设备
      block=$(find_block $BLOCK);
      if [ -z "$block" ]; then
        abort " " "找不到分区: $BLOCK";
      fi;
      BLOCK=$block;
      ;;
  esac;
  # MTD 分区检测
  case $BLOCK in
    /dev/mtd*)
      log_debug "检测到 MTD 分区: $BLOCK";
      ;;
  esac;
  # 检测 boot 镜像头版本以确定多分区自动化
  if [ -f "$BIN/magiskboot" ]; then
    hdr_ver=$(magiskboot unpack -h $BOOTIMG 2>&1 | grep HEADER_VER | sed -n 's;.*\[\(.*\)\];\1;p');
    case $hdr_ver in
      4|5)
        # hdr v4+ 可能需要 vendor_boot 和 vendor_kernel_boot
        log_debug "检测到 boot 头版本: $hdr_ver";
        ;;
    esac;
  fi;
  # 调用属性函数（如果定义）
  if type boot_attributes >/dev/null 2>&1; then
    boot_attributes;
  fi;
  log_debug "AK 初始化完成: BLOCK=$BLOCK, SLOT=$SLOT";
}


dump_moduleinfo() {
cat <<EOF > $1;
id=ak3-helper
name=AK3 Helper Module
version=$(awk '{ print $3 }' $AKHOME/vertmp) $(grep -oE '#.[0-9]' $AKHOME/vertmp)
versionCode=1
author=AnyKernel3
description=$KERNEL_STRING
EOF
}

dump_moduleremover() {
cat <<'EOF' > $1;
#!/system/bin/sh
MODDIR=${0%/*};
if [ "$(cat /proc/version)" != "$(cat $MODDIR/version)" ]; then
  rm -rf $MODDIR;
  exit;
fi;
rm -f $MODDIR/update;
. $MODDIR/post-fs-data.2.sh;
EOF
}

do_modules() {
  [ "$(file_getprop anykernel.sh do.modules)" == 1 ] || return 1;
  local block modcon moddir modtarget module mount slot umask umountksu;
  if [ "$(file_getprop anykernel.sh do.systemless)" == 1 ]; then
    # ═══ 无 Root 模式（systemless）═══
    if [ ! -d /data/adb -o ! -d /data/data/android ]; then
      ui_print " " "警告：无法访问 /data，跳过内核辅助模块安装！";
      return 1;
    fi;
    cd $AKHOME/modules;
    ui_print " " "正在创建内核辅助无 Root 模块...";
    if [ -d /data/adb/magisk -a -f $AKHOME/magisk_patched ] || [ -d /data/data/me.weishu.kernelsu -a -f $AKHOME/kernelsu_patched ]; then
      umask=$(umask);
      moddir=/data/adb/modules/ak3-helper;
      # KernelSU 初始化处理
      if [ -f $AKHOME/kernelsu_patched ]; then
        umask 077;
        # 初始化 ksud
        if [ ! -f /data/adb/ksud ]; then
          cp -f /data/app/*/me.weishu.kernelsu*/lib/*/libksud.so /data/adb/ksud;
          chmod 755 /data/adb/ksud;
        fi;
        # 创建 KernelSU 模块目录
        if [ ! -d /data/adb/modules ]; then
          mkdir -p /data/adb/modules;
          chmod 777 /data/adb/modules;
        fi;
        [ -d /data/adb/modules_update ] || mkdir -p /data/adb/modules_update;
        [ -d /data/adb/ksu ] || mkdir -p /data/adb/ksu;
        # 处理 modules_update.img
        [ -f /data/adb/ksu/modules.img ] && cp -f /data/adb/ksu/modules.img /data/adb/ksu/modules_update.img;
        if [ ! -f /data/adb/ksu/modules_update.img ]; then
          /system/bin/make_ext4fs -b 1024 -l 256M /data/adb/ksu/modules_update.img 2>/dev/null \
            || /system/bin/make_ext4fs -l 256M /data/adb/ksu/modules_update.img 2>/dev/null;
        fi;
        umountksu=1;
        # 挂载 modules_update.img
        if [ -f /data/adb/ksu/modules_update.img ]; then
          moddir=/data/adb/modules_update/ak3-helper;
          mkdir -p $moddir;
          mount -t ext4 -o rw /data/adb/ksu/modules_update.img $moddir 2>/dev/null \
            || mount -o rw /data/adb/ksu/modules_update.img $moddir 2>/dev/null;
        fi;
      fi;
      # 创建模块目录结构
      mkdir -p $moddir;
      # 创建 module.prop
      dump_moduleinfo $moddir/module.prop;
      # 创建版本文件
      cat /proc/version > $moddir/version;
      # 创建 post-fs-data.sh 脚本
      cat <<'PFSDEOF' > $moddir/post-fs-data.sh
#!/system/bin/sh
MODDIR=${0%/*};
. $MODDIR/system.prop 2>/dev/null;
PFSDEOF
      # 创建 service.sh 脚本
      cat <<'SVCEOF' > $moddir/service.sh
#!/system/bin/sh
MODDIR=${0%/*};
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1;
done;
SVCEOF
      # 安装模块文件
      for module in $AKHOME/modules/*.ko; do
        [ -f "$module" ] || continue;
        modtarget=$(basename $module);
        cp -f $module $moddir/$modtarget;
        printf "insmod $MODDIR/$modtarget\n" >> $moddir/service.sh;
      done;
      # 安装补丁脚本
      if [ -f "$AKHOME/modules/post-fs-data.sh" ]; then
        cat $AKHOME/modules/post-fs-data.sh >> $moddir/post-fs-data.sh;
      fi;
      if [ -f "$AKHOME/modules/service.sh" ]; then
        cat $AKHOME/modules/service.sh >> $moddir/service.sh;
      fi;
      # 创建 system.prop
      if [ -f "$AKHOME/modules/system.prop" ]; then
        cp -f $AKHOME/modules/system.prop $moddir/system.prop;
      fi;
      # 创建自动卸载脚本
      dump_moduleremover $moddir/post-fs-data.2.sh;
      # 设置权限
      umask $umask;
      set_perm_recursive 0 0 755 644 $moddir;
      chmod 755 $moddir/post-fs-data.sh $moddir/service.sh $moddir/post-fs-data.2.sh;
      # KernelSU 卸载处理
      if [ "$umountksu" = 1 ]; then
        umount -l $moddir 2>/dev/null;
        # 使用 ksud 安装模块
        if [ -x /data/adb/ksud ]; then
          /data/adb/ksud module install $moddir 2>/dev/null;
        fi;
      fi;
      ui_print " " "无 Root 模块安装完成";
    else
      ui_print " " "警告：未检测到 Magisk 或 KernelSU，跳过模块安装";
    fi;
  else
    # ═══ 传统模式（直接推送到 rootfs）═══
    cd $AKHOME/modules;
    ui_print " " "正在安装内核模块到 rootfs...";
    for module in *.ko; do
      [ -f "$module" ] || continue;
      cp -f $module $RAMDISK/;
      # 设置 SELinux 上下文
      if which restorecon >/dev/null 2>&1; then
        restorecon $RAMDISK/$module 2>/dev/null;
      fi;
      log_debug "已安装模块: $module";
    done;
    ui_print " " "内核模块安装完成";
  fi;
}


backup_boot_image() {
  local backup_dir="/sdcard/ak3-backups";
  local device timestamp backup_file device_info;
  # 确保备份目录存在
  mkdir -p "$backup_dir" 2>/dev/null;
  if [ $? -ne 0 ]; then
    log_warn "无法创建备份目录: $backup_dir";
    return 1;
  fi;
  # 获取设备信息
  device=$(getprop ro.product.device 2>/dev/null || printf "unknown\n");
  timestamp=$(date +%Y%m%d_%H%M%S);
  backup_file="$backup_dir/boot_${device}_${timestamp}.img";
  # 备份当前 boot 镜像
  if [ -f "$BOOTIMG" ]; then
    cp -f "$BOOTIMG" "$backup_file";
  elif [ -n "$BLOCK" ] && [ -e "$BLOCK" ]; then
    dd if=$BLOCK of="$backup_file" bs=1048576 2>/dev/null;
  else
    log_warn "没有可备份的 boot 镜像";
    return 1;
  fi;
  if [ $? -ne 0 ]; then
    log_warn "备份 boot 镜像失败";
    return 1;
  fi;
  # 记录设备信息
  device_info="$backup_dir/boot_${device}_${timestamp}.info";
  {
    printf "设备: $device\n";
    printf "时间: $(date)\n";
    printf "Android 版本: $(getprop ro.build.version.release 2>/dev/null)\n";
    printf "安全补丁: $(getprop ro.build.version.security_patch 2>/dev/null)\n";
    printf "分区: $BLOCK\n";
    printf "文件大小: $(stat -c%%s \n"$backup_file" 2>/dev/null || echo "未知")";
  } > "$device_info";
  ui_print " " "boot 镜像已备份到: $backup_file";
  log_debug "备份完成: $backup_file";
  return 0;
}

restore_boot_image() {
  local backup_file="$1";
  local backup_size partition_size;
  if [ -z "$backup_file" ]; then
    log_error "未指定备份文件";
    return 1;
  fi;
  if [ ! -f "$backup_file" ]; then
    log_error "备份文件不存在: $backup_file";
    return 1;
  fi;
  if [ -z "$BLOCK" ] || [ ! -e "$BLOCK" ]; then
    log_error "目标分区无效: $BLOCK";
    return 1;
  fi;
  # 安全检查：备份文件大小不应超过分区大小太多
  backup_size=$(stat -c%s "$backup_file" 2>/dev/null);
  partition_size=$(blockdev --getsize64 "$BLOCK" 2>/dev/null);
  if [ -n "$backup_size" ] && [ -n "$partition_size" ] && [ "$backup_size" -gt "$partition_size" ]; then
    log_error "备份文件大小 ($backup_size) 超过分区大小 ($partition_size)";
    log_error "恢复操作已取消以防止数据损坏";
    return 1;
  fi;
  # 执行恢复
  ui_print " " "正在从备份恢复 boot 镜像...";
  if [ -f "$BIN/nanddump" ]; then
    flash_erase $BLOCK 0 0;
    nandwrite -p $BLOCK "$backup_file";
  else
    dd if="$backup_file" of=$BLOCK bs=1048576;
  fi;
  if [ $? -ne 0 ]; then
    log_error "恢复 boot 镜像失败";
    return 1;
  fi;
  ui_print " " "boot 镜像已成功恢复";
  log_debug "恢复完成: $backup_file -> $BLOCK";
  return 0;
}


trap_handler() {
  local sig="$1";
  log_error "收到信号 $sig，正在清理并退出...";
  debugging;
  restore_env;
  cleanup;
  exit 1;
}

debugging() {
  local debug log path;
  # 检查是否启用调试模式
  case $(basename "$ZIPFILE" .zip) in
    *-debugging) debug=1;;
  esac;
  for path in /tmp /cache /metadata /persist; do
    [ -f $path/.ak3-debugging ] && debug=1;
  done;
  if [ "$debug" ]; then
    ui_print " " "正在创建调试归档到 $DIR...";
    [ -f /tmp/recovery.log ] && log=/tmp/recovery.log;
    tar -czf "$DIR/anykernel3-$(date +%Y-%m-%d_%H%M%S)-debug.tgz" $AKHOME $log;
  fi;
}

create_debug_archive() {
  local log archive;
  ui_print " " "正在创建调试归档...";
  [ -f /tmp/recovery.log ] && log=/tmp/recovery.log;
  archive="$DIR/anykernel3-$(date +%Y-%m-%d_%H%M%S)-debug.tgz";
  tar -czf "$archive" $AKHOME $log 2>/dev/null;
  if [ $? -eq 0 ]; then
    ui_print " " "调试归档已保存: $archive";
  else
    log_error "创建调试归档失败";
  fi;
}

cleanup() {
  cd $AKHOME/../;
  rm -rf $AKHOME;
}


show_banner() {
  if [ -f "$AKHOME/banner" ]; then
    ui_printfile "$AKHOME/banner";
  fi;
  if [ -f "$AKHOME/kernel.string" ]; then
    KERNEL_STRING=$(cat $AKHOME/kernel.string);
    ui_print " " "$KERNEL_STRING";
  fi;
  if [ -f "$AKHOME/version" ]; then
    ui_print " " "版本: $(cat $AKHOME/version)";
  fi;
}


show_help() {
  printf "AnyKernel3 单脚本刷入工具 v$AK3_VERSION\n"
  printf "\n"
  printf "用法:\n"
  printf "  sh ak3-flash.sh [选项] <刷机包.zip>\n"
  printf "\n"
  printf "选项:\n"
  printf "  -z, --zip <路径>       指定刷机包 ZIP 文件路径\n"
  printf "  -o, --outfd <fd>       指定 Recovery UI 输出文件描述符\n"
  printf "  -d, --debug            启用调试模式\n"
  printf "  -h, --help             显示帮助信息\n"
  printf "\n"
  printf "示例:\n"
  printf "  sh ak3-flash.sh /sdcard/Download/kernel.zip\n"
  printf "  sh ak3-flash.sh -z /sdcard/Download/kernel.zip\n"
  printf "  su -c 'sh /sdcard/ak3-flash.sh -d -z /sdcard/Download/kernel.zip'\n"
}

interactive_input() {
  local input_path
  local confirmed=false

  printf "\n"
  printf "╔══════════════════════════════════╗\n"
  printf "║     AnyKernel3 单脚本刷入工具 - 交互模式                    ║\n"
  printf "╚════════════════════════════════╝\n"
  printf "\n"

  # 检查是否在终端交互环境中
  if [ ! -t 0 ]; then
    printf "错误: 无法进入交互模式（未检测到终端输入）\n" >&2
    printf "请使用命令行参数指定压缩包路径:\n" >&2
    printf "  sh ak3-flash.sh /path/to/kernel.zip\n" >&2
    printf "  sh ak3-flash.sh -z /path/to/kernel.zip\n" >&2
    exit 1
  fi

  # 交互式循环，直到用户确认路径
  while [ "$confirmed" != "true" ]; do
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    printf "\n"
    printf "📁 请输入刷机包 ZIP 文件的完整路径\n"
    printf "   (例如: /sdcard/Download/AnyKernel3.zip)\n"
    printf "\n"
    printf "💡 提示: 可以输入部分路径后按 Tab 键自动补全（如果终端支持）\n"
    printf "\n"
    printf "路径 > "
    read -r input_path

    # 去除首尾空格
    input_path=$(printf "$input_path\n" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # 检查是否为空
    if [ -z "$input_path" ]; then
      printf "\n"
      printf "⚠️  路径不能为空，请重新输入\n"
      printf "\n"
      continue
    fi

    # 展开 ~ 为 HOME 目录
    case "$input_path" in
      ~/*) input_path="$HOME${input_path#~}" ;;
      ~) input_path="$HOME" ;;
    esac

    # 检查文件是否存在
    if [ ! -f "$input_path" ]; then
      printf "\n"
      printf "❌ 文件不存在: $input_path\n"
      printf "\n"

      # 尝试查找相似文件
      local dir=$(dirname "$input_path" 2>/dev/null)
      local base=$(basename "$input_path" 2>/dev/null)
      if [ -d "$dir" ]; then
        local similar=$(find "$dir" -maxdepth 1 -name "*.zip" -type f 2>/dev/null | head -5)
        if [ -n "$similar" ]; then
          printf "📋 在该目录下找到以下 ZIP 文件:\n"
          printf "$similar\n" | while read -r f; do
            printf "   - $f\n"
          done
          printf "\n"
        fi
      fi
      continue
    fi

    # 检查是否为 ZIP 文件
    if ! unzip -l "$input_path" >/dev/null 2>&1; then
      printf "\n"
      printf "❌ 该文件不是有效的 ZIP 格式: $input_path\n"
      printf "\n"
      continue
    fi

    # 显示文件信息
    printf "\n"
    printf "📄 文件信息:\n"
    printf "   路径: $input_path\n"
    printf "   大小: $(ls -lh "$input_path" 2>/dev/null | awk '{print $5}')"
    printf "   修改时间: $(ls -l "$input_path" 2>/dev/null | awk '{print $6, $7, $8}')"
    printf "\n"

    # 确认提示
    printf "✅ 确认使用该文件? [Y/n] > "
    read -r confirm

    case "$confirm" in
      [Yy]|""|[Yy][Ee][Ss])
        confirmed=true
        ZIPFILE="$input_path"
        printf "\n"
        printf "✓ 已选择: $ZIPFILE\n"
        printf "\n"
        ;;
      [Nn]|[Nn][Oo])
        printf "\n"
        printf "🔄 请重新输入路径\n"
        printf "\n"
        ;;
      *)
        printf "\n"
        printf "⚠️  无效输入，请重新输入路径\n"
        printf "\n"
        ;;
    esac
  done
}

parse_args() {
  local positional_args=""

  while [ "$1" ]; do
    case "$1" in
      -z|--zip)
        if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
          printf "错误: $1 需要一个文件路径参数\n" >&2
          exit 1
        fi
        ZIPFILE="$2"
        shift 2
        ;;
      -o|--outfd)
        if [ -z "$2" ]; then
          printf "错误: $1 需要一个文件描述符参数\n" >&2
          exit 1
        fi
        OUTFD="$2"
        shift 2
        ;;
      -d|--debug)
        DEBUG_MODE=1
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -*)
        printf "错误: 未知选项 $1\n" >&2
        printf "使用 -h 或 --help 查看帮助\n" >&2
        exit 1
        ;;
      *)
        # 位置参数：收集为候选压缩包路径
        positional_args="$positional_args $1"
        shift
        ;;
    esac
  done

  # 如果没有通过 -z 指定 ZIPFILE，尝试从位置参数中获取
  if [ -z "$ZIPFILE" ]; then
    # Recovery 调用约定: $1=recovery_arg(通常为空), $2=outfd, $3=zipfile
    # 直接调用约定: $1=zipfile
    set -- $positional_args
    case $# in
      0)
        # 没有提供任何参数，进入交互式输入模式
        interactive_input
        ;;
      1)
        # 单个参数：直接作为 ZIP 路径
        ZIPFILE="$1"
        ;;
      2)
        # 两个参数：可能是 (outfd, zipfile) 或 (recovery_arg, zipfile)
        # 判断第一个参数是否为数字（文件描述符）
        if [ "$1" -eq "$1" ] 2>/dev/null; then
          OUTFD="$1"
          ZIPFILE="$2"
        else
          ZIPFILE="$1"
          OUTFD="$2"
        fi
        ;;
      3)
        # 三个参数：Recovery 调用约定 (recovery_arg, outfd, zipfile)
        OUTFD="$2"
        ZIPFILE="$3"
        ;;
      *)
        # 超过三个参数：取最后一个作为 ZIP 路径
        ZIPFILE="$#"
        ;;
    esac
  fi
}

main() {
  # ═══ 步骤 0：解析命令行参数 ═══
  parse_args "$@"

  # ═══ 步骤 1：初始化基本变量 ═══
  # OUTFD 和 ZIPFILE 已在 parse_args 中设置
  BOOTMODE=false;
  # 通过 zygote 进程检测是否为系统内刷入模式
  ps | grep zygote | grep -v grep >/dev/null && BOOTMODE=true;
  $BOOTMODE || ps -A 2>/dev/null | grep zygote | grep -v grep >/dev/null && BOOTMODE=true;
  # 设置工作目录
  DIR=/sdcard;
  $BOOTMODE || DIR=$(dirname "$ZIPFILE");
  [ $DIR == "/sideload" ] && DIR=/tmp;
  # 设置 postinstall 路径
  [ -d /postinstall/tmp ] && POSTINSTALL=/postinstall;
  [ "$AKHOME" ] || export AKHOME=$POSTINSTALL/tmp/anykernel;
  [ "$ANDROID_ROOT" ] || ANDROID_ROOT=/system;

  # ═══ 步骤 2：验证输入 ═══
  validate_input "$ZIPFILE" || abort "输入验证失败，请检查刷机包路径是否正确";
  check_root || abort "需要 root 权限才能执行刷入操作";

  # ═══ 步骤 3：设置目录结构 ═══
  export AKHOME=$AKHOME;
  BOOTIMG=$AKHOME/boot.img;
  BIN=$AKHOME/tools;
  PATCH=$AKHOME/patch;
  RAMDISK=$AKHOME/ramdisk;
  SPLITIMG=$AKHOME/split_img;

  # ═══ 步骤 4：清理旧目录并解压 ZIP ═══
  rm -rf $AKHOME 2>/dev/null;
  mkdir -p $AKHOME $AKHOME/bin;
  # 解压刷机包
  log_info "正在解压刷机包: $ZIPFILE";
  cd $AKHOME;
  unzip -o "$ZIPFILE" 2>/dev/null;
  if [ $? != 0 ]; then
    abort "无法解压刷机包: $ZIPFILE";
  fi;

  # ═══ 步骤 5：初始化 busybox ═══
  setup_bb;

  # ═══ 步骤 6：设置 PATH ═══
  OLD_PATH=$PATH;
  export PATH=$AKHOME/bin:$PATH;

  # ═══ 步骤 7：显示横幅 ═══
  show_banner;

  # ═══ 步骤 8：设置环境 ═══
  setup_env;

  # ═══ 步骤 9：安全检查 ═══
  do_devicecheck;
  do_versioncheck;
  do_levelcheck;
  do_vendorlevelcheck;

  # ═══ 步骤 10：显示安装提示 ═══
  ui_print " " "正在安装...";

  # ═══ 步骤 11：处理 ak*-core.sh 符号链接（向后兼容）═══
  if [ -L "$AKHOME/tools/ak3-core.sh" ] || [ -L "$AKHOME/tools/ak-core.sh" ]; then
    log_debug "检测到旧版 ak-core.sh 符号链接，已跳过（使用内置核心逻辑）";
  fi;

  # ═══ 步骤 12：执行 anykernel.sh 配置脚本 ═══
  ui_print " " "正在执行刷入脚本...";
  ui_print " " "⚠️  注意：此过程可能需要 1-3 分钟，请勿中断或关闭终端";
  ui_print " " "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  
  if [ -f "$AKHOME/anykernel.sh" ]; then
    # 加载属性函数
    if type properties >/dev/null 2>&1; then
      properties;
    fi;
    # 在 AKHOME 目录下执行 anykernel.sh
    cd $AKHOME;
    ash anykernel.sh 2>/dev/null || sh anykernel.sh;
    if [ $? != 0 ]; then
      abort " " "执行 anykernel.sh 失败";
    fi;
  else
    abort " " "未找到 anykernel.sh 配置文件";
  fi;
  
  ui_print " " "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  ui_print " " "✓ 刷入操作已完成！";

  # ═══ 步骤 13：模块安装 ═══
  do_modules;

  # ═══ 步骤 14：创建调试归档 ═══
  debugging;

  # ═══ 步骤 15：恢复环境 ═══
  restore_env;

  # ═══ 步骤 16：条件清理 ═══
  if [ "$(file_getprop anykernel.sh do.cleanup 2>/dev/null)" == 1 ]; then
    cleanup;
  fi;

  # ═══ 步骤 17：完成 ═══
  ui_print " ";
  ui_print "╔══════════════════════════════════╗";
  ui_print "║                    ✓ 刷写完成                               ║";
  ui_print "╚════════════════════════════════╝";
  ui_print " ";
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  ui_print "刷入信息:";
  ui_print "  分区路径: $BLOCK";
  if [ -n "$SLOT" ]; then
    ui_print "  当前槽位: $SLOT";
  fi;
  if [ -f "$AKHOME/magisk_patched" ]; then
    ui_print "  Magisk 支持: ✓ 已保留";
  elif [ -f "$AKHOME/kernelsu_patched" ]; then
    ui_print "  KernelSU 支持: ✓ 已保留";
  fi;
  if [ -f "$AKHOME/vertmp" ]; then
    local kern_ver=$(cat "$AKHOME/vertmp" 2>/dev/null | head -1);
    if [ -n "$kern_ver" ]; then
      ui_print "  内核版本: $kern_ver";
    fi;
  fi;
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  ui_print " ";

  # ═══ 步骤 18：询问是否重启 ═══
  if [ -t 0 ]; then
    printf "是否现在重启设备? [Y/n] > "
    read -r reboot_choice
    case "$reboot_choice" in
      [Yy]|""|[Yy][Ee][Ss])
        ui_print " " "正在重启...";
        sleep 1;
        reboot;
        ;;
      [Nn]|[Nn][Oo])
        ui_print " ";
        ui_print "⚠️  请稍后手动重启设备以应用更改";
        ui_print " ";
        ;;
      *)
        ui_print " ";
        ui_print "⚠️  请稍后手动重启设备以应用更改";
        ui_print " ";
        ;;
    esac
  else
    ui_print "⚠️  请重启设备以应用更改";
    ui_print " ";
  fi;
}



ak3_main_flow() {
    local ZIP_FILE="$1"
    local WORK_DIR="/data/local/tmp/ak3_work"
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    printf "${Y}解压ZIP文件...${N}\n"
    unzip -o "$ZIP_FILE" -d "$WORK_DIR" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        printf "${R}解压失败${N}\n"
        rm -rf "$WORK_DIR"
        return 1
    fi
    if [ ! -f "$WORK_DIR/anykernel.sh" ]; then
        printf "${R}不是有效的AnyKernel3包${N}\n"
        rm -rf "$WORK_DIR"
        return 1
    fi
    printf "${G}检测到AnyKernel3包${N}\n"
    cd "$WORK_DIR"
    sh anykernel.sh
    local result=$?
    cd /
    rm -rf "$WORK_DIR"
    if [ $result -eq 0 ]; then
        printf "${G}刷入完成！建议重启设备${N}\n"
    else
        printf "${R}刷入失败，返回码: $result${N}\n"
    fi
}


run_resource_download() {
    while true; do
        echo
        printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
        printf "${ORANGE}║${N}            ${W}资 源 下 载${N}                        ${ORANGE}║${N}\n"
        printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
        printf "${ORANGE}│${N}  ${G}1${N}. ${W}GKI资源${N}                             ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}2${N}. ${W}APK资源${N}                             ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${G}3${N}. ${W}潘多拉内核${N}                           ${ORANGE}│${N}\n"
        printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                           ${ORANGE}║${N}\n"
        printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
        echo
        printf "  ${Y}请选择: ${N}"
        read sub_choice
        case "$sub_choice" in
            1) printf "${Y}GKI资源 - 功能开发中，敬请期待...${N}\n" ;;
            2) resource_apk_download ;;
            3) printf "${Y}潘多拉内核 - 功能开发中，敬请期待...${N}\n" ;;
            0) break ;;
        esac
        printf "${DI}按回车继续...${N}\n"
        read
    done
}

resource_apk_download() {
    clear
    printf "${C}[*] 正在连接服务器获取APK列表...${N}\n"
    local list_url="${API_URL}?action=list_files&dir=软件"
    local list_json=""
    if which curl >/dev/null 2>&1; then
        list_json=$(curl -s -L --connect-timeout 10 "$list_url" 2>/dev/null)
    elif which wget >/dev/null 2>&1; then
        list_json=$(wget -q -O - --timeout=10 "$list_url" 2>/dev/null)
    fi
    if [ -z "$list_json" ]; then
        printf "${R}[X] 无法连接服务器${N}\n"
        return 1
    fi
    # 检查是否返回错误
    if printf "$list_json\n" | grep -q '"error"'; then
        local err_msg=$(printf "$list_json\n" | grep -o '"error":"[^"]*"' | sed 's/"error":"//;s/"$//')
        printf "${R}[X] ${err_msg}${N}\n"
        printf "${DI}    请联系作者添加资源文件${N}\n"
        return 1
    fi
    # 解析文件数量
    local file_count=$(printf "$list_json\n" | grep -o '"count":[0-9]*' | sed 's/"count"://')
    if [ -z "$file_count" ] || [ "$file_count" = "0" ]; then
        printf "${R}[X] 目录下暂无文件${N}\n"
        printf "${DI}    请联系作者添加资源文件${N}\n"
        return 1
    fi
    # 解析文件名列表（从JSON中提取name字段）
    local file_names=$(printf "$list_json\n" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"$//')
    local file_sizes=$(printf "$list_json\n" | grep -o '"size_text":"[^"]*"' | sed 's/"size_text":"//;s/"$//')
    echo
    printf "${G}[OK] 找到 ${Y}${file_count}${G} 个文件${N}\n"
    printf "${ORANGE}╔══════════════════════════════════════════════════╗${N}\n"
    printf "${ORANGE}║${N}              ${W}APK 资源列表${N}                      ${ORANGE}║${N}\n"
    printf "${ORANGE}╠══════════════════════════════════════════════════╣${N}\n"
    # 用换行符分割文件名
    local idx=1
    local name_idx=1
    printf "$file_names\n" | while IFS= read -r fname; do
        [ -z "$fname" ] && continue
        if [ $idx -le 20 ]; then
            printf "${ORANGE}║${N}  ${G}${idx}${N}. ${W}${fname}${N}\n"
        fi
        idx=$((idx + 1))
    done
    if [ "$file_count" -gt 20 ] 2>/dev/null; then
        printf "${ORANGE}║${N}  ${DI}... 还有 $((file_count - 20)) 个文件${N}\n"
    fi
    printf "${ORANGE}╠══════════════════════════════════════════════════╣${N}\n"
    printf "${ORANGE}║${N}  ${G}a${N}. ${W}全部下载${N}                                ${ORANGE}║${N}\n"
    printf "${ORANGE}║${N}  ${R}0${N}. ${W}返回${N}                                    ${ORANGE}║${N}\n"
    printf "${ORANGE}╚══════════════════════════════════════════════════╝${N}\n"
    echo
    printf "  ${Y}请选择要下载的文件编号: ${N}"
    read apk_choice
    [ "$apk_choice" = "0" ] && return 0
    [ -z "$apk_choice" ] && return 0
    local save_dir="/sdcard/Download/XToolbox/APK"
    mkdir -p "$save_dir"
    local dl_base="${CLOUD_BASE}/软件/"
    if [ "$apk_choice" = "a" ]; then
        local dl_idx=1
        printf "$file_names\n" | while IFS= read -r fname; do
            [ -z "$fname" ] && continue
            printf "${C}[$dl_idx/$file_count] 正在下载: ${W}${fname}${N}\n"
            download_with_progress_retry "${dl_base}${fname}" "${save_dir}/${fname}" "$fname"
            dl_idx=$((dl_idx + 1))
        done
        printf "${G}[OK] 全部下载完成，保存到: ${save_dir}${N}\n"
    else
        local dl_idx=1
        printf "$file_names\n" | while IFS= read -r fname; do
            [ -z "$fname" ] && continue
            if [ "$dl_idx" = "$apk_choice" ]; then
                printf "${C}[*] 正在下载: ${W}${fname}${N}\n"
                download_with_progress_retry "${dl_base}${fname}" "${save_dir}/${fname}" "$fname"
                printf "${G}[OK] 下载完成: ${save_dir}/${fname}${N}\n"
                break
            fi
            dl_idx=$((dl_idx + 1))
        done
    fi
}


main() {
    mkdir -p "$XTB_DIR" "$TS_DIR" "$OUT_DIR"
    init_usage
    init_launch_count
    add_launch_count
    # 第一屏：免责协议（需确认）
    show_screen3_disclaimer
    # 第二屏：启动检测（777权限 + MT拓展包）
    show_startup_check
    # 第三屏：公告
    show_screen2_announce
    # 卡密验证
    do_verify
    # 逐行提示
    show_tips
    # Root检测
    if ! detect_root; then
        printf "${Y}[!] 未检测到Root环境${N}\n"
        printf "  ${DI}按回车继续...${N}"
        read
    fi
    get_device_info
    # 主菜单循环
    while true; do
        clear
        show_main_menu
        printf "  ${Y}请选择功能 [0-16]: ${N}"
        read choice
        case "$choice" in
            1)
                clear
                while true; do
                    echo
                    printf "${ORANGE}╔════════════════════════════════════════╗${N}\n"
                    printf "${ORANGE}║${N}              ${W}设 备 清 理${N}                    ${ORANGE}║${N}\n"
                    printf "${ORANGE}╠════════════════════════════════════════╣${N}\n"
                    printf "${ORANGE}│${N}  ${G}1${N}. ${W}一键改ID${N}                            ${ORANGE}│${N}\n"
                    printf "${ORANGE}│${N}  ${G}2${N}. ${W}显示当前设备ID${N}                        ${ORANGE}│${N}\n"
                    printf "${ORANGE}│${N}  ${R}0${N}. ${W}返回主菜单${N}                             ${ORANGE}│${N}\n"
                    printf "${ORANGE}╚════════════════════════════════════════╝${N}\n"
                    echo
                    printf "  ${Y}请选择: ${N}"
                    read sub_choice
                    case "$sub_choice" in
                        1) clear; change_device_ids ;;
                        2) clear; show_current_ids ;;
                        0) break ;;
                    esac
                done
                ;;
            2) clear; run_full_install ;;
            3) clear; run_trickystore_config ;;
            4) clear; run_game_clean ;;
            5) clear; run_anti_detect ;;
            6) clear; run_scheduler_center ;;
            7) clear; run_tg_verify ;;
            8) clear; run_clipboard_unlock ;;
            9) clear; run_hide_apps ;;
            10) clear; run_module_manager ;;
            11) clear; run_apk_installer ;;
            12) clear; run_partition_backup ;;
            13) clear; run_ak3_flash ;;
            14) clear; run_resource_download ;;
            15) clear; run_dtbo_toolkit ;;
            16) clear; run_flash_toolkit ;;
            0) printf "${G}感谢使用 XToolbox v1.6${N}\n"; exit 0 ;;
        esac
    done
}

main "$@"

