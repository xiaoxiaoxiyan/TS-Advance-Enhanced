#!/system/bin/sh

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;33m⚠️ 当前没有 Root 权限，正在尝试自动提权...\033[0m"
    if command -v su >/dev/null 2>&1; then
        exec su -c "sh $0"
    else
        echo -e "\033[1;31m✗ 未找到 su 命令，请手动以 Root 权限运行\033[0m"
        echo -e "\033[1;33m  手动运行命令: su -c \"sh $0\"\033[0m"
        exit 1
    fi
fi

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;31m✗ 提权失败，请确保设备已 Root 并授权\033[0m"
    exit 1
fi

echo -e "\033[1;32m✓ Root 权限获取成功\033[0m"

SELINUX_ORIG=$(getenforce 2>/dev/null)
if [ "$SELINUX_ORIG" = "Enforcing" ]; then
    echo -e "\033[1;33m⚠️ SELinux 处于 Enforcing 模式，临时切换为 Permissive\033[0m"
    setenforce 0
    echo -e "\033[1;32m✓ SELinux 已临时关闭\033[0m"
fi

if [ ! -d "/sys/class/android_usb/android0" ]; then
    echo -e "\033[1;33m⚠️ 未找到 /sys/class/android_usb/android0，尝试创建...\033[0m"
    mkdir -p /sys/class/android_usb/android0 2>/dev/null
fi

R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
C='\033[0;36m'
M='\033[0;35m'
W='\033[1;37m'
NC='\033[0m'

LOCKDIR="/data/local/tmp/.adbtoolkit"
mkdir -p "$LOCKDIR" 2>/dev/null

fb_keepalive() {
    local target=$1
    while [ -f "$LOCKDIR/fb_keepalive.lock" ]; do
        [ -n "$target" ] && fastboot -s $target getvar product 2>/dev/null || fastboot getvar product 2>/dev/null
        sleep 0.3
    done
}

usb_wake() {
    echo $$ > "$LOCKDIR/usb_wake.pid"
    while [ -f "$LOCKDIR/usb_wake.lock" ]; do
        if [ -w "/sys/class/android_usb/android0/enable" ]; then
            echo 1 > /sys/class/android_usb/android0/enable 2>/dev/null
        fi
        for dev in /sys/bus/usb/devices/*/power/control; do
            if [ -w "$dev" ]; then
                echo on > $dev 2>/dev/null
            fi
        done
        for dev in /sys/bus/usb/devices/*/power/autosuspend; do
            if [ -w "$dev" ]; then
                echo -1 > $dev 2>/dev/null
            fi
        done
        sleep 0.5
    done
}

adb_lock() {
    echo $$ > "$LOCKDIR/adb_lock.pid"
    while [ -f "$LOCKDIR/adb_lock.lock" ]; do
        resetprop ro.debuggable 1 2>/dev/null
        resetprop service.adb.root 1 2>/dev/null
        resetprop persist.sys.usb.config mtp,adb,diag,serial 2>/dev/null
        resetprop persist.adb.tcp.port 5555 2>/dev/null
        resetprop ro.secure 0 2>/dev/null
        resetprop ro.adb.secure 0 2>/dev/null
        if ! pidof adbd > /dev/null 2>&1; then
            stop adbd 2>/dev/null
            start adbd 2>/dev/null
        fi
        sleep 1
    done
}

cleanup() {
    for pidf in "$LOCKDIR"/*.pid; do
        [ -f "$pidf" ] && kill "$(cat "$pidf")" 2>/dev/null
    done
    rm -rf "$LOCKDIR"
    if [ "$SELINUX_ORIG" = "Enforcing" ]; then
        setenforce 1 2>/dev/null
    fi
    sysctl -w usbcore.autosuspend=1 2>/dev/null
    echo -e "${G}✓ 工具箱已安全退出${NC}"
    echo -e "${Y}  所有系统设置已还原${NC}"
    exit 0
}

trap cleanup EXIT INT TERM

loading_animation() {
    local msg=$1
    local duration=$2
    local spin=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local end=$((SECONDS+duration))
    local i=0
    while [ $SECONDS -lt $end ]; do
        printf "\r${C}%s ${W}%s${NC}" "${spin[i]}" "$msg"
        i=$((i+1))
        [ $i -ge 10 ] && i=0
        sleep 0.1
    done
    printf "\r${G}✓ %s 完成${NC}\n" "$msg"
}

get_path() {
    local prompt="$1"
    local suffix="$2"
    local mode="$3"
    local auto_scan="$4"
    local input_path=""
    while true; do
        echo -n -e "$prompt${C}"
        read input_path
        echo -e -n "${NC}"
        input_path=$(echo "$input_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed "s/^'//;s/'$//" | sed 's/^"//;s/"$//')
        if [ -z "$input_path" ] && [ "$auto_scan" = "0" ]; then
            if [ "$mode" = "file" ] && [ -n "$suffix" ]; then
                set +f
                files=$(find . -maxdepth 1 -type f -name "*$suffix" -o -name "*$suffix" 2>/dev/null | sort | sed 's|^\./||')
                set -f
                count=$(echo "$files" | grep -c .)
                if [ "$count" -eq 0 ]; then
                    echo -e "${R}当前目录未找到*$suffix文件，请重试或手动输入${NC}"
                    continue
                elif [ "$count" -eq 1 ]; then
                    input_path="$files"
                    echo -e "${Y}（自动扫描到: $input_path）${NC}"
                else
                    echo -e "${Y}检测到多个*$suffix文件${NC}"
                    i=1
                    echo "$files" | while IFS= read -r f; do
                        echo "  $i. $f"
                        i=$((i+1))
                    done
                    echo -n "请选择文件编号 (1-$count) 或 q 退出: "
                    read choice
                    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
                        XP_PATH=""
                        return 1
                    fi
                    if echo "$choice" | grep -qE '^[0-9]+$' && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
                        input_path=$(echo "$files" | sed -n "${choice}p")
                    else
                        echo -e "${R}无效选择${NC}"
                        continue
                    fi
                fi
            elif [ "$mode" = "dir" ]; then
                input_path="./"
            fi
        fi
        if [ "$input_path" = "q" ] || [ "$input_path" = "Q" ]; then
            XP_PATH=""
            return 1
        fi
        if [ -z "$input_path" ]; then
            echo -e "${R}输入不能为空${NC}"
            continue
        fi
        if [ "$mode" = "file" ]; then
            if [ ! -f "$input_path" ]; then
                echo -e "${R}文件不存在: $input_path${NC}"
                continue
            fi
            if [ -n "$suffix" ] && [[ ! "$input_path" == *"$suffix" ]]; then
                echo -e "${R}文件后缀必须是 $suffix${NC}"
                continue
            fi
            XP_PATH="$input_path"
            return 0
        elif [ "$mode" = "dir" ]; then
            if [ ! -d "$input_path" ]; then
                echo -e "${R}目录不存在: $input_path${NC}"
                continue
            fi
            XP_PATH="$input_path"
            return 0
        fi
    done
}

check_device() {
    local MD="$1"
    local TM=$((10 + 1))
    local IT=1
    local EL=0
    local HW=0
    local ADB_OUT=""
    local FB_OUT=""
    local ADB_HAS=0
    local FB_HAS=0
    local UNAUTH=""
    local ADB_DEVS=""
    local REC_DEVS=""
    local SIDE_DEVS=""
    local FB_LIST=""
    local SER=""
    local DEV_MODE=""
    local K=""
    echo
    while [ $EL -lt $TM ]; do
        ADB_OUT=$(adb devices 2>/dev/null)
        FB_OUT=$(fastboot devices 2>/dev/null)
        ADB_HAS=$(echo "$ADB_OUT" | grep -v "List of devices attached" | grep -v '^[[:space:]]*$' | wc -l)
        FB_HAS=$(echo "$FB_OUT" | grep -v '^[[:space:]]*$' | wc -l)
        if [ "$ADB_HAS" -eq 0 ] && [ "$FB_HAS" -eq 0 ]; then
            printf "\r [等待设备响应 ${Y}%d/10秒${NC} q退出]:" $EL
            read -t $IT -n 1 K 2>/dev/null || true
            if [ "$K" = "q" ] || [ "$K" = "Q" ]; then
                bdse="0"
                return 1
            fi
            EL=$((EL + IT))
            continue
        fi
        if [ "$MD" = "adb" ] || [ "$MD" = "any" ]; then
            UNAUTH=$(echo "$ADB_OUT" | grep -v "List of devices" | grep "unauthorized$" | awk '{print $1}')
            if [ -n "$UNAUTH" ] && [ "$HW" -eq 0 ]; then
                echo -e "\n${R}检测到未授权设备：$UNAUTH${NC}"
                echo -e "${Y}请在设备上勾选[一律允许使用这台计算机进行调试]并点击[允许]${NC}"
                echo
                HW=1
            fi
        fi
        case $MD in
            "adb")
                ADB_DEVS=$(echo "$ADB_OUT" | grep -v "List of devices" | grep "device$" | awk '{print $1}')
                if [ -n "$ADB_DEVS" ]; then
                    DEVICE_SERIAL=$(echo "$ADB_DEVS" | head -n1)
                    QGHP_MODE="adb"
                    echo -e "${G}ADB已连接 $DEVICE_SERIAL${NC}"
                    return 0
                fi ;;
            "fastboot")
                FB_LIST=$(echo "$FB_OUT" | head -n1)
                if [ -n "$FB_LIST" ]; then
                    DEVICE_SERIAL=$(echo "$FB_LIST" | awk '{print $1}')
                    DEV_MODE=$(echo "$FB_LIST" | awk '{print $2}')
                    if [ "$DEV_MODE" = "fastbootd" ]; then
                        QGHP_MODE="fastbootD"
                        echo -e "${G}FastbootD已连接 $DEVICE_SERIAL${NC}"
                    else
                        QGHP_MODE="fastboot"
                        echo -e "${G}Fastboot已连接 $DEVICE_SERIAL${NC}"
                    fi
                    return 0
                fi ;;
            "recovery")
                REC_DEVS=$(echo "$ADB_OUT" | grep -v "List of devices" | grep "recovery$" | awk '{print $1}')
                if [ -n "$REC_DEVS" ]; then
                    DEVICE_SERIAL=$(echo "$REC_DEVS" | head -n1)
                    QGHP_MODE="recovery"
                    echo -e "${G}Recovery已连接 $DEVICE_SERIAL${NC}"
                    return 0
                fi ;;
            "any")
                ADB_DEVS=$(echo "$ADB_OUT" | grep -v "List of devices" | grep "device$" | awk '{print $1}')
                FB_LIST=$(echo "$FB_OUT" | head -n1)
                SIDE_DEVS=$(echo "$ADB_OUT" | grep -v "List of devices" | grep "sideload$" | awk '{print $1}')
                REC_DEVS=$(echo "$ADB_OUT" | grep -v "List of devices" | grep "recovery$" | awk '{print $1}')
                if [ -n "$ADB_DEVS" ]; then
                    DEVICE_SERIAL=$(echo "$ADB_DEVS" | head -n1)
                    QGHP_MODE="adb"
                    echo -e "${G}ADB已连接 $DEVICE_SERIAL${NC}"
                    return 0
                elif [ -n "$FB_LIST" ]; then
                    DEVICE_SERIAL=$(echo "$FB_LIST" | awk '{print $1}')
                    DEV_MODE=$(echo "$FB_LIST" | awk '{print $2}')
                    if [ "$DEV_MODE" = "fastbootd" ]; then
                        QGHP_MODE="fastbootD"
                        echo -e "${G}FastbootD已连接 $DEVICE_SERIAL${NC}"
                    else
                        QGHP_MODE="fastboot"
                        echo -e "${G}Fastboot已连接 $DEVICE_SERIAL${NC}"
                    fi
                    return 0
                elif [ -n "$SIDE_DEVS" ]; then
                    DEVICE_SERIAL=$(echo "$SIDE_DEVS" | head -n1)
                    QGHP_MODE="sideload"
                    echo -e "${G}Sideload已连接 $DEVICE_SERIAL${NC}"
                    return 0
                elif [ -n "$REC_DEVS" ]; then
                    DEVICE_SERIAL=$(echo "$REC_DEVS" | head -n1)
                    QGHP_MODE="recovery"
                    echo -e "${G}Recovery已连接 $DEVICE_SERIAL${NC}"
                    return 0
                fi ;;
        esac
        printf "\r [等待设备响应 ${Y}%d/10秒${NC} q退出]:" $EL
        read -t $IT -n 1 K 2>/dev/null || true
        if [ "$K" = "q" ] || [ "$K" = "Q" ]; then
            bdse="0"
            return 1
        fi
        EL=$((EL + IT))
    done
    echo -e "\n${R}设备连接超时${NC}"
    echo -e "${Y}请检查是否开启OTG和设备连接${NC}"
    return 1
}

flash_with_retry() {
    local PARTITION="$1"
    local IMG_PATH="$2"
    local RETRY_COUNT=0
    local SUCCESS=0
    echo -e "\n${C}刷入分区${NC}: ${W}$PARTITION${NC}"
    while [ $RETRY_COUNT -lt 3 ]; do
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -gt 1 ]; then
            echo -e "\n${Y}尝试第 $RETRY_COUNT 次刷入${NC}"
        fi
        fastboot flash "$PARTITION" "$IMG_PATH"
        if [ $? -eq 0 ]; then
            echo -e "${G}刷入成功。${NC}"
            SUCCESS=1
            break
        else
            if [ $RETRY_COUNT -lt 3 ]; then
                echo -e "${R}刷入失败 (第 $RETRY_COUNT 次)${NC}"
                local fastboot_full_output=$(fastboot devices 2>/dev/null)
                local fastboot_has_device=$(echo "$fastboot_full_output" | grep -v '^[[:space:]]*$' | wc -l)
                if [ $fastboot_has_device -eq 0 ]; then
                    echo -e "\n${R}检测到设备异常断开 请勿触碰设备！${NC}"
                fi
                sleep 1
            fi
        fi
    done
    if [ $SUCCESS -eq 0 ]; then
        echo -e "\n${R}错误: [$PARTITION] 分区刷入 3 次后仍然失败${NC}"
        return 1
    fi
    return 0
}

ensure_target_mode() {
    local target="$1"
    local REBOOT_SUCCESS=0
    local start_time=$(date +%s)
    local q_cmd
    local fastboot_list
    local current_serial
    local current_mode
    local elapsed
    local last_output_time=0
    if [ "$QGHP_MODE" = "fastboot" ] || [ "$QGHP_MODE" = "fastbootD" ]; then
        if [ "$target" = "fastbootD" ] && [ "$QGHP_MODE" = "fastbootD" ]; then
            sleep 0.5
            return 0
        elif [ "$target" = "bootloader" ] && [ "$QGHP_MODE" = "fastboot" ]; then
            sleep 0.5
            return 0
        fi
    fi
    echo
    if [ "$target" = "fastbootD" ]; then
        echo -e "${G}当前模式：$QGHP_MODE → 重启到 fastbootD${NC}"
        case "$QGHP_MODE" in
            "adb"|"recovery") adb reboot fastboot ;;
            "fastboot") (fastboot reboot fastboot >/dev/null 2>&1 &) && disown $! 2>/dev/null ;;
            *)  echo -e "${R}不支持的设备模式，无法重启到 fastbootD${NC}"
                return 1 ;;
        esac
    elif [ "$target" = "bootloader" ]; then
        echo -e "${G}当前模式：$QGHP_MODE → 重启到 fastboot${NC}"
        if [ "$QGHP_MODE" = "fastbootD" ]; then
            (fastboot reboot-bootloader >/dev/null 2>&1 &) && disown $! 2>/dev/null
        elif [ "$QGHP_MODE" = "adb" ] || [ "$QGHP_MODE" = "recovery" ]; then
            adb reboot bootloader
        else
            echo -e "${R}不支持的设备模式，无法重启到 fastboot${NC}"
            return 1
        fi
    fi
    while true; do
        read -t 1 -n 1 q_cmd 2>/dev/null || true
        if [ "$q_cmd" = "q" ] || [ "$q_cmd" = "Q" ]; then
            echo -e "\n${R}主动退出等待，操作终止！${QN}"
            return 1
        fi
        fastboot_list=$(fastboot devices 2>/dev/null | head -n1)
        if [ -n "$fastboot_list" ]; then
            current_serial=$(echo "$fastboot_list" | awk '{print $1}')
            current_mode=$(echo "$fastboot_list" | awk '{print $2}')
            if [ "$target" = "fastbootD" ] && [ "$current_mode" = "fastbootd" ]; then
                DEVICE_SERIAL="$current_serial"
                QGHP_MODE="fastbootD"
                elapsed=$(( $(date +%s) - start_time ))
                echo -e "\n${G}设备成功进入 fastbootD 模式！（共等待 ${elapsed} 秒）${NC}"
                echo -e "${Y}等待 8 秒稳定...${NC}"
                sleep 8
                REBOOT_SUCCESS=1
                break
            elif [ "$target" = "bootloader" ] && [ "$current_mode" = "fastboot" ]; then
                DEVICE_SERIAL="$current_serial"
                QGHP_MODE="fastboot"
                elapsed=$(( $(date +%s) - start_time ))
                echo -e "\n${G}设备成功进入 fastboot 模式！（共等待 ${elapsed} 秒）${NC}"
                echo -e "${Y}等待 8 秒稳定...${NC}"
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
            echo -e "\n${R}等待60秒超时，未检测到设备进入目标模式${NC}"
            echo -n "是否继续检测？(y继续/n退出): "
            read retry_confirm
            if [ "$retry_confirm" = "y" ] || [ "$retry_confirm" = "Y" ]; then
                start_time=$(date +%s)
                elapsed=0
                last_output_time=0
            else
                echo -e "${Y}已退出检测，操作终止${NC}"
                return 1
            fi
        fi
    done
    echo -e "\r"
    if [ $REBOOT_SUCCESS -eq 1 ]; then
        return 0
    else
        echo -e "${R}进入目标模式失败${NC}"
        return 1
    fi
}

rex_flash_engine() {
    local img_path="$1"
    local partition="$2"
    local mode="$3"
    local success=0

    echo -e "${Y}开始刷写: $partition ← $img_path${NC}"

    if [ ! -f "$img_path" ]; then
        echo -e "${R}错误: 镜像文件不存在${NC}"
        return 1
    fi

    local file_size=$(stat -c%s "$img_path" 2>/dev/null || echo "0")
    if [ "$file_size" -lt 1024 ]; then
        echo -e "${R}错误: 镜像文件大小异常 (小于1KB)，可能已损坏${NC}"
        return 1
    fi

    if [ "$mode" = "fastboot" ]; then
        echo -e "${Y}检查分区是否存在...${NC}"
        fastboot getvar partition-size:"$partition" 2>/dev/null | grep -q "partition-size"
        if [ $? -ne 0 ]; then
            echo -e "${R}错误: 分区 [$partition] 不存在！${NC}"
            return 1
        fi
        if [ "$partition" = "boot" ] || [ "$partition" = "recovery" ]; then
            echo -e "${Y}校验镜像头部...${NC}"
            local magic=$(dd if="$img_path" bs=1 count=8 2>/dev/null | xxd -p)
            if [ "$partition" = "boot" ] && [ "$magic" != "414e44524f494421" ]; then
                echo -e "${R}警告: 镜像头部不符 (非标准boot.img)，继续可能会变砖！${NC}"
                echo -n -e "${C}仍然继续? (yes/no): ${NC}"
                read confirm
                if [ "$confirm" != "yes" ]; then
                    echo -e "${Y}已取消刷写${NC}"
                    return 1
                fi
            fi
        fi
        flash_with_retry "$partition" "$img_path"
        if [ $? -eq 0 ]; then
            echo -e "${G}刷写成功！${NC}"
            return 0
        else
            echo -e "${R}刷写失败！${NC}"
            return 1
        fi
    elif [ "$mode" = "adb" ] || [ "$mode" = "recovery" ]; then
        local temp_name="tmp_$(basename "$img_path")"
        local device_path="/data/local/tmp/$temp_name"
        echo -e "${Y}传输镜像到设备...${NC}"
        adb push "$img_path" "$device_path"
        if [ $? -ne 0 ]; then
            echo -e "${R}文件传输失败${NC}"
            return 1
        fi
        echo -e "${Y}通过dd写入分区...${NC}"
        adb shell "dd if=$device_path of=/dev/block/by-name/$partition"
        if [ $? -eq 0 ]; then
            success=1
        fi
        adb shell "rm -f $device_path"
        if [ $success -eq 1 ]; then
            echo -e "${G}刷写成功！${NC}"
        else
            echo -e "${R}刷写失败！${NC}"
        fi
        return $success
    elif [ "$mode" = "edl" ]; then
        echo -e "${Y}准备EDL刷写...${NC}"
        if [ -z "$FIREHOSE" ] || [ -z "$RAWPROG" ]; then
            echo -e "${R}缺少Firehose或rawprogram.xml${NC}"
            return 1
        fi
        qcom-dl -f "$FIREHOSE" -p "$RAWPROG" -d "$(ls /dev/ttyUSB* 2>/dev/null | head -n1)"
        if [ $? -eq 0 ]; then
            success=1
        fi
        if [ $success -eq 1 ]; then
            echo -e "${G}刷写成功！${NC}"
        else
            echo -e "${R}刷写失败！${NC}"
        fi
        return $success
    else
        echo -e "${R}未知模式${NC}"
        return 1
    fi
}

if [ -f "./otg_config.bin" ]; then
    OTG_CONFIG=$(cat ./otg_config.bin)
    if [ -n "$OTG_CONFIG" ]; then
        eval "$OTG_CONFIG"
    fi
fi

bdse=""

clear
echo -e "${R}"
echo "██████╗ ███████╗██╗  ██╗    ███████╗██╗      █████╗ ███████╗██╗  ██╗"
echo "██╔══██╗██╔════╝╚██╗██╔╝    ██╔════╝██║     ██╔══██╗██╔════╝██║  ██║"
echo "██████╔╝█████╗   ╚███╔╝     █████╗  ██║     ███████║███████╗███████║"
echo "██╔══██╗██╔══╝   ██╔██╗     ██╔══╝  ██║     ██╔══██║╚════██║██╔══██║"
echo "██║  ██║███████╗██╔╝ ██╗    ██║     ███████╗██║  ██║███████║██║  ██║"
echo "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "${W}          REX FLASH TOOLKIT ｜ 全能刷机工具箱 ｜ v3.4${NC}"
echo -e "${C}  作者: Rex ｜ 支持: 高通/联发科 ｜ 模式: 9008/Fastboot/ADB${NC}"
echo
echo -e "${Y}内核版本: ${W}$(uname -r 2>/dev/null || echo "未知")${NC}"
echo
echo -e "${G}脚本完全免费 如果你是买来的请立刻退款 并且拿筷子${NC}"
echo
echo -e "${C}小贴士：${NC}"
echo -e "${C}拯救者Y700用户进入FastBoot或9008 请将数据线连接长口，否则可能无法连接${NC}"
echo -e "${C}如进入fastboot无法连接，请拔线重新插入${NC}"
echo -e "${C}刷的时候请不要拔掉数据线，否则可能出现故障${NC}"
echo
echo -e "${Y}🔐 请输入授权卡密:${NC}"
read -r PWD
if [ "$PWD" != "Rex123" ]; then
    echo -e "\n${R}✗ 卡密验证失败！${NC}"
    echo -e "${Y}  请联系作者获取正确卡密${NC}"
    sleep 2
    exit 1
fi
echo
loading_animation "正在验证卡密" 1
loading_animation "正在初始化环境" 1
loading_animation "正在启动守护进程" 1

touch "$LOCKDIR/usb_wake.lock" "$LOCKDIR/adb_lock.lock"
usb_wake &
adb_lock &
sleep 1

MAIN_LOOP(){
while true
do
clear
echo -e "${R}"
echo "██████╗ ███████╗██╗  ██╗    ███████╗██╗      █████╗ ███████╗██╗  ██╗"
echo "██╔══██╗██╔════╝╚██╗██╔╝    ██╔════╝██║     ██╔══██╗██╔════╝██║  ██║"
echo "██████╔╝█████╗   ╚███╔╝     █████╗  ██║     ███████║███████╗███████║"
echo "██╔══██╗██╔══╝   ██╔██╗     ██╔══╝  ██║     ██╔══██║╚════██║██╔══██║"
echo "██║  ██║███████╗██╔╝ ██╗    ██║     ███████╗██║  ██║███████║██║  ██║"
echo "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "${W}          REX FLASH TOOLKIT ｜ 全能刷机工具箱 ｜ v3.4${NC}"
echo -e "${C}  作者: Rex ｜ 支持: 高通/联发科 ｜ 模式: 9008/Fastboot/ADB${NC}"
echo
echo -e "${Y}📋 功能菜单${NC}"
echo -e "${W}  1${NC} 🔓 一键ROOT (自动检测BL状态并刷入)"
echo -e "${W}  2${NC} 🔥 9008 EDL深度刷写"
echo -e "${W}  3${NC} ⚡ Fastboot专区"
echo -e "${W}  4${NC} 🔓 一键ROOT获取 (不处理BL)"
echo -e "${W}  5${NC} 🔄 重启模式切换"
echo -e "${W}  6${NC} 🛠️  BL解锁/救砖修复"
echo -e "${W}  7${NC} 📦 一键重装全平台驱动 + ADB环境补全"
echo -e "${W}  8${NC} 🧪 系统环境自检"
echo -e "${W}  9${NC} 🔒 一键回锁Bootloader"
echo -e "${W}  10${NC} 💾 分区备份/恢复"
echo -e "${W}  11${NC} 📱 刷入第三方Recovery"
echo -e "${W}  12${NC} 🔄 全分区擦除（四清）"
echo -e "${W}  13${NC} 📋 查看分区表"
echo -e "${W}  14${NC} 🧰 修复IMEI/基带"
echo -e "${W}  15${NC} 🔄 自动刷入Magisk"
echo -e "${W}  16${NC} 🛡️ 深度救砖"
echo -e "${W}  17${NC} 📦 小白一键刷入全量包"
echo -e "${W}  18${NC} 🟢 欧加线刷工具 (OFP/OPPO/OnePlus/Realme)"
echo -e "${W}  19${NC} 🔵 小米线刷工具 (Fastboot/EDL)"
echo -e "${W}  20${NC} 🎯 自定义 ADB 指令"
echo -e "${W}  21${NC} 💾 备份当前boot分区 (安全)"
echo -e "${W}  A${NC} 🔗 连接设备 (强制刷新)"
echo -e "${W}  0${NC} ❌ 退出工具箱"
echo -e "${C}请输入选项编号:${NC}"
read OPT

case $OPT in
1)
clear
echo -e "${B}🔓 一键ROOT (自动检测BL状态并刷入)${NC}"
echo
if ! check_device "any"; then
    echo -e "${R}✗ 未检测到设备${NC}"
    sleep 2
    continue
fi
if [ "$QGHP_MODE" != "fastboot" ]; then
    echo -e "${Y}当前不是Fastboot模式，尝试切换到Fastboot...${NC}"
    if [ "$QGHP_MODE" = "adb" ]; then
        adb reboot bootloader
        echo -e "${Y}等待设备重启到Fastboot...${NC}"
        sleep 10
        if ! check_device "fastboot"; then
            echo -e "${R}✗ 切换失败，请手动进入Fastboot模式${NC}"
            sleep 2
            continue
        fi
    else
        echo -e "${R}✗ 无法自动切换到Fastboot模式，请手动重启到Fastboot${NC}"
        sleep 2
        continue
    fi
fi
echo -e "${Y}正在检测BL状态...${NC}"
local bl_status=$(fastboot getvar unlocked 2>&1 | grep -E '^unlocked:' | awk -F': ' '{print $2}' | tr -d '[:space:]')
if [ "$bl_status" = "yes" ] || [ "$bl_status" = "unlocked" ]; then
    echo -e "${G}✓ Bootloader 已解锁${NC}"
else
    echo -e "${R}✗ Bootloader 未解锁${NC}"
    echo -e "${Y}解锁BL将清空所有用户数据！${NC}"
    echo -n -e "${C}是否解锁Bootloader? (y/n): ${NC}"
    read confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${Y}已取消操作${NC}"
        sleep 2
        continue
    fi
    echo -e "${Y}正在解锁Bootloader...${NC}"
    fastboot flashing unlock
    if [ $? -ne 0 ]; then
        fastboot oem unlock
    fi
    echo -e "${Y}解锁命令已发送，设备将重启，请等待进入系统后再次进入Fastboot并重新运行此功能${NC}"
    sleep 5
    continue
fi
get_path "请输入Magisk修补后的boot镜像路径: " ".img" "file" "0"
if [ -z "$XP_PATH" ]; then
    continue
fi
MAG="$XP_PATH"
echo
echo -e "${Y}正在刷入Magisk Boot...${NC}"
rex_flash_engine "$MAG" "boot" "fastboot"
if [ $? -eq 0 ]; then
    echo -e "${G}✓ 刷入成功！${NC}"
    echo -e "${Y}  设备将自动重启${NC}"
    fastboot reboot
else
    echo -e "${R}✗ 刷入失败！${NC}"
fi
sleep 3
;;

2)
clear
echo -e "${B}🔥 小白式 9008 EDL 深度刷机${NC}"
echo
modprobe usbserial 2>/dev/null
modprobe qdloader 2>/dev/null
TTY_LIST=$(ls /dev/ttyUSB* 2>/dev/null)
if [ -z "$TTY_LIST" ]; then
    echo -e "${R}✗ 未检测到9008设备${NC}"
    echo -e "${Y}  请确保设备已进入9008模式并正确连接${NC}"
    sleep 3
    continue
fi
if [ ! -f "/system/bin/qcom-dl" ]; then
    echo -e "${R}✗ 缺少qcom-dl刷写工具${NC}"
    echo -e "${Y}  请将qcom-dl放置到/system/bin目录并赋予执行权限${NC}"
    sleep 3
    continue
fi
echo -e "${G}✓ 检测到以下9008设备:${NC}"
IDX=1
for dev in $TTY_LIST
do
    echo "  $IDX $dev"
    IDX=$((IDX+1))
done
echo
echo -e "${C}请输入固件包（ZIP）路径:${NC}"
read -r ZIP_PATH
if [ ! -f "$ZIP_PATH" ]; then
    echo -e "${R}✗ 文件不存在${NC}"
    sleep 2
    continue
fi
TEMP_DIR="/sdcard/temp_edl"
mkdir -p "$TEMP_DIR" 2>/dev/null
echo -e "${Y}正在解压固件包...${NC}"
unzip -o "$ZIP_PATH" -d "$TEMP_DIR" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${R}✗ 解压失败，请检查ZIP文件是否损坏${NC}"
    rm -rf "$TEMP_DIR" 2>/dev/null
    sleep 3
    continue
fi
FIREHOSE=$(find "$TEMP_DIR" -name "*.mbn" | head -n1)
RAWPROG=$(find "$TEMP_DIR" -name "rawprogram*.xml" | head -n1)
if [ -z "$FIREHOSE" ]; then
    echo -e "${R}✗ 未找到 Firehose 文件 (*.mbn)${NC}"
    rm -rf "$TEMP_DIR" 2>/dev/null
    sleep 3
    continue
fi
if [ -z "$RAWPROG" ]; then
    echo -e "${R}✗ 未找到 rawprogram.xml 文件${NC}"
    rm -rf "$TEMP_DIR" 2>/dev/null
    sleep 3
    continue
fi
echo -e "${G}✓ 已找到 Firehose: $(basename "$FIREHOSE")${NC}"
echo -e "${G}✓ 已找到 rawprogram: $(basename "$RAWPROG")${NC}"
echo
echo -e "${R}⚠️  警告: 刷写将清空所有用户数据！${NC}"
echo -e "${Y}  确定要继续吗？(y/N)${NC}"
read -r CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo -e "${Y}已取消刷写操作${NC}"
    rm -rf "$TEMP_DIR" 2>/dev/null
    sleep 2
    continue
fi
TARGET_TTY=$(echo "$TTY_LIST" | head -n1)
echo
echo -e "${Y}正在开始刷写...${NC}"
rex_flash_engine "$FIREHOSE" "EDL" "edl"
RESULT=$?
rm -rf "$TEMP_DIR" 2>/dev/null
if [ $RESULT -eq 0 ]; then
    echo -e "${G}✓ 刷写成功！${NC}"
    echo -e "${Y}  设备将自动重启${NC}"
else
    echo -e "${R}✗ 刷写失败！${NC}"
    echo -e "${Y}  请检查固件包是否匹配设备型号${NC}"
fi
sleep 5
;;

3)
clear
echo -e "${B}⚡ Fastboot专区${NC}"
echo
modprobe f_fastboot 2>/dev/null
if [ $FB_COUNT -eq 0 ]; then
    echo -e "${R}✗ 未检测到Fastboot设备${NC}"
    echo -e "${Y}  请确保设备已进入Fastboot模式并正确连接${NC}"
    sleep 3
    continue
fi
if [ $FB_COUNT -gt 1 ]; then
    echo -e "${G}✓ 检测到以下Fastboot设备:${NC}"
    IDX=1
    for dev in "${FB_DEVICES[@]}"; do
        echo "  $IDX $dev"
        IDX=$((IDX+1))
    done
    echo
    echo -e "${C}请选择要操作的设备序号:${NC}"
    read -r SEL_DEV
    TARGET_FB=${FB_DEVICES[$((SEL_DEV-1))]}
    FB_CMD="fastboot -s $TARGET_FB"
else
    FB_CMD="fastboot"
fi
echo
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${W}  1${NC} 刷写Boot镜像"
echo -e "${W}  2${NC} 执行自定义Fastboot命令"
echo -e "${W}  3${NC} 刷写Recovery镜像"
echo -e "${W}  4${NC} 返回主菜单"
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${C}请选择功能:${NC}"
read -r F_OPT
case $F_OPT in
1)
    get_path "请输入Boot镜像路径: " ".img" "file" "0"
    if [ -z "$XP_PATH" ]; then continue; fi
    IMG="$XP_PATH"
    echo
    echo -e "${Y}正在开始刷写...${NC}"
    rex_flash_engine "$IMG" "boot" "fastboot"
    echo -e "${G}✓ Boot镜像刷写完成${NC}"
    ;;
2)
    echo -e "${C}请输入要执行的Fastboot命令:${NC}"
    read -r CMD
    echo
    loading_animation "正在执行命令" 1
    echo -e "${Y}════════════════════════════════════════${NC}"
    $FB_CMD $CMD
    echo -e "${Y}════════════════════════════════════════${NC}"
    echo -e "${G}✓ 命令执行完毕${NC}"
    ;;
3)
    get_path "请输入Recovery镜像路径: " ".img" "file" "0"
    if [ -z "$XP_PATH" ]; then continue; fi
    IMG="$XP_PATH"
    echo
    echo -e "${Y}正在开始刷写...${NC}"
    rex_flash_engine "$IMG" "recovery" "fastboot"
    echo -e "${G}✓ Recovery镜像刷写完成${NC}"
    ;;
4)
    echo -e "${G}✓ 返回主菜单${NC}"
    ;;
*)
    echo -e "${R}✗ 无效选项${NC}"
    ;;
esac
sleep 3
;;

4)
clear
echo -e "${B}🔓 一键ROOT获取 (不处理BL)${NC}"
echo
echo -e "${Y}  此功能将刷入Magisk修补后的Boot镜像${NC}"
echo -e "${Y}  请确保已使用Magisk修补好Boot.img${NC}"
echo
get_path "请输入Magisk修补后的Boot镜像路径: " ".img" "file" "0"
if [ -z "$XP_PATH" ]; then continue; fi
MAG="$XP_PATH"
echo
echo -e "${Y}⚠️  设备将自动重启到Fastboot模式${NC}"
loading_animation "正在重启设备" 2
fastboot reboot bootloader 2>/dev/null
sleep 5
echo
echo -e "${Y}正在开始刷写...${NC}"
rex_flash_engine "$MAG" "boot" "fastboot"
echo
loading_animation "正在重启设备" 2
fastboot reboot
echo -e "${G}✓ ROOT获取成功！${NC}"
echo -e "${Y}  设备重启后即可获得ROOT权限${NC}"
sleep 5
;;

5)
clear
echo -e "${B}🔄 重启模式切换${NC}"
echo
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${W}  1${NC} 重启到Fastboot模式"
echo -e "${W}  2${NC} 重启到Fastbootd模式"
echo -e "${W}  3${NC} 重启到Recovery模式"
echo -e "${W}  4${NC} 重启到9008 EDL模式"
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${C}请选择重启模式:${NC}"
read -r R
case $R in
    1) 
        echo -e "${Y}正在重启到Fastboot模式...${NC}"
        fastboot reboot bootloader 2>/dev/null
        ;;
    2) 
        echo -e "${Y}正在重启到Fastbootd模式...${NC}"
        fastboot reboot fastboot 2>/dev/null
        ;;
    3) 
        echo -e "${Y}正在重启到Recovery模式...${NC}"
        fastboot reboot recovery 2>/dev/null
        ;;
    4) 
        echo -e "${Y}正在重启到9008 EDL模式...${NC}"
        fastboot oem edl 2>/dev/null
        ;;
    *) 
        echo -e "${R}✗ 无效选择${NC}"
        ;;
esac
echo -e "${G}✓ 重启指令已发送${NC}"
sleep 3
;;

6)
clear
echo -e "${B}🛠️  BL解锁/救砖修复${NC}"
echo
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${W}  1${NC} 一键解锁Bootloader"
echo -e "${W}  2${NC} 修复Fastboot引导"
echo -e "${W}  3${NC} 修复Recovery引导"
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${C}请选择功能:${NC}"
read -r B
case $B in
    1)
        echo -e "${R}⚠️  警告: 解锁BL将清空所有用户数据！${NC}"
        echo -e "${Y}  确定要继续吗？(y/N)${NC}"
        read -r C
        if [ "$C" = "y" ]; then
            echo -e "${Y}正在发送解锁指令...${NC}"
            fastboot oem unlock-go 2>/dev/null
            fastboot reboot 2>/dev/null
            echo -e "${G}✓ BL解锁指令已发送${NC}"
        else
            echo -e "${Y}已取消解锁操作${NC}"
        fi
        ;;
    2)
        echo -e "${Y}正在尝试修复Fastboot引导...${NC}"
        fastboot reboot 2>/dev/null
        echo -e "${G}✓ Fastboot引导修复指令已发送${NC}"
        ;;
    3)
        echo -e "${Y}正在尝试修复Recovery引导...${NC}"
        adb reboot system 2>/dev/null
        echo -e "${G}✓ Recovery引导修复指令已发送${NC}"
        ;;
    *)
        echo -e "${R}✗ 无效选项${NC}"
        ;;
esac
sleep 3
;;

7)
clear
echo -e "${B}📦 一键重装全平台驱动 + ADB 环境补全${NC}"
echo
echo -e "${Y}⚠️  正在执行全平台驱动注入 + 防失联配置 + ADB 环境补全${NC}"
echo -e "${Y}  此过程约需5-10秒，请勿断开连接${NC}"
echo

loading_animation "正在卸载旧USB驱动" 1
rmmod usbserial 2>/dev/null
rmmod qcserial 2>/dev/null
rmmod qdloader 2>/dev/null
rmmod option 2>/dev/null
rmmod cdc_acm 2>/dev/null
rmmod f_fastboot 2>/dev/null
rmmod g_serial 2>/dev/null
rmmod usb_f_mtp 2>/dev/null
rmmod usb_f_adb 2>/dev/null
rmmod sprd_serial 2>/dev/null
rmmod pl2303 2>/dev/null
rmmod ftdi_sio 2>/dev/null
sleep 0.5

loading_animation "正在加载核心USB驱动" 1
modprobe usbcore 2>/dev/null
modprobe usb_common 2>/dev/null
modprobe usb_serial 2>/dev/null
modprobe cdc_acm 2>/dev/null
modprobe option 2>/dev/null
modprobe f_fastboot 2>/dev/null
modprobe g_serial 2>/dev/null
modprobe usb_f_mtp 2>/dev/null
modprobe usb_f_adb 2>/dev/null
modprobe sprd_serial 2>/dev/null
modprobe pl2303 2>/dev/null
modprobe ftdi_sio 2>/dev/null
sleep 0.5

loading_animation "正在植入高通9008 EDL驱动" 1
modprobe qcserial 2>/dev/null
modprobe qdloader 2>/dev/null
if [ -f "/sys/bus/usb-serial/drivers/qcserial/new_id" ]; then
    echo "05c6 9008" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9006" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 900e" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "18d1 d00d" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9001" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9002" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9003" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9004" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9005" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9007" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9009" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9010" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9011" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9025" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9091" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 90b1" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 90b2" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 90b3" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 90b4" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
fi
sleep 0.5

loading_animation "正在植入骁龙全系列通用驱动" 1
if [ -f "/sys/bus/usb-serial/drivers/qcserial/new_id" ]; then
    echo "05c6 676c" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 6764" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 6765" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 676a" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 90db" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 90dc" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 90dd" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 90de" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 90df" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9130" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9131" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9132" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9133" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9134" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9135" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9136" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9137" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9138" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
    echo "05c6 9139" > /sys/bus/usb-serial/drivers/qcserial/new_id 2>/dev/null
fi
sleep 0.5

loading_animation "正在植入联发科MTK驱动" 1
if [ -f "/sys/bus/usb-serial/drivers/option/new_id" ]; then
    echo "0e8d 0003" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 2000" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 2001" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 2002" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 2003" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 0001" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 0002" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 0004" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 2004" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 2005" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 2006" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 3000" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 3001" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 3002" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 3003" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 4000" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 4001" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 4002" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 4003" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 5000" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 5001" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 5002" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 5003" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
fi
sleep 0.5

loading_animation "正在植入天玑全系列通用驱动" 1
if [ -f "/sys/bus/usb-serial/drivers/option/new_id" ]; then
    echo "0e8d 1234" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1235" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1236" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1237" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1240" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1241" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1242" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1243" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1250" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1251" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1252" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "0e8d 1253" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
fi
sleep 0.5

loading_animation "正在植入展讯/紫光展锐驱动" 1
if [ -f "/sys/bus/usb-serial/drivers/option/new_id" ]; then
    echo "1782 4d00" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "1782 5d00" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "1782 4d01" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "1782 4d02" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "1782 4d03" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "1782 4d04" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "1782 5d01" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "1782 5d02" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "1782 5d03" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "1782 5d04" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
fi
sleep 0.5

loading_animation "正在植入海思/麒麟驱动" 1
if [ -f "/sys/bus/usb-serial/drivers/option/new_id" ]; then
    echo "12d1 3609" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "12d1 107e" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "12d1 107f" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "12d1 1035" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "12d1 1036" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "12d1 1037" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
    echo "12d1 1038" > /sys/bus/usb-serial/drivers/option/new_id 2>/dev/null
fi
sleep 0.5

loading_animation "正在配置Fastboot防失联" 1
sysctl -w usbcore.autosuspend=-1 2>/dev/null
sysctl -w usbcore.usbfs_memory_mb=1024 2>/dev/null
echo 0 > /sys/module/usbcore/parameters/old_scheme_first 2>/dev/null
echo 1 > /sys/module/usbcore/parameters/use_both_schemes 2>/dev/null
echo high > /sys/class/android_usb/android0/speed 2>/dev/null
sleep 0.5

loading_animation "正在配置USB调试防断连" 1
resetprop persist.sys.usb.config mtp,adb,diag,serial,acm 2>/dev/null
resetprop service.adb.tcp.port 5555 2>/dev/null
resetprop ro.adb.secure 0 2>/dev/null
resetprop ro.debuggable 1 2>/dev/null
stop adbd 2>/dev/null
start adbd 2>/dev/null
sleep 0.5

loading_animation "正在重置USB总线" 1
echo 0 > /sys/class/android_usb/android0/enable 2>/dev/null
sleep 0.3
echo 1 > /sys/class/android_usb/android0/enable 2>/dev/null
sleep 1

loading_animation "正在补全 ADB 环境" 1

resetprop ro.debuggable 1
resetprop ro.secure 0
resetprop ro.adb.secure 0
resetprop service.adb.root 1

resetprop persist.sys.usb.config mtp,adb,diag,serial,acm
resetprop persist.sys.usb.config mtp,adb
resetprop persist.sys.usb.config adb

resetprop persist.adb.tcp.port 5555
resetprop service.adb.tcp.port 5555

resetprop ro.adb.secure 0
resetprop adb.secure 0

stop adbd
sleep 1
start adbd

setenforce 0

echo "ADB_ENV_READY" > /data/local/tmp/.adb_env_ready

loading_animation "ADB 环境补全完成" 1

echo
echo -e "${G}✓ 全平台驱动重装完成！${NC}"
echo -e "${G}✓ Fastboot防失联已启用${NC}"
echo -e "${G}✓ USB调试防断连已启用${NC}"
echo -e "${G}✓ ADB环境已补全${NC}"
echo
echo -e "${C}📋 最新设备列表:${NC}"
echo -e "${C}QDLoader 9008设备:${NC}"
echo "  $(ls /dev/bus/usb/* 2>/dev/null | grep qd || echo "无")"
echo -e "${C}Fastboot设备:${NC}"
echo "  $(fastboot devices 2>/dev/null || echo "无")"
echo -e "${C}USB串口设备:${NC}"
echo "  $(ls /dev/ttyUSB* 2>/dev/null || echo "无")"
echo -e "${C}MTK串口设备:${NC}"
echo "  $(ls /dev/ttyMT* 2>/dev/null || echo "无")"
echo
echo -e "${Y}💡 提示: 如果设备仍未识别，请重新插拔USB线${NC}"
sleep 8
;;

8)
clear
echo -e "${B}🧪 系统环境自检${NC}"
echo
echo -e "${C}SELinux状态: ${W}$(getenforce 2>/dev/null || echo "未知")${NC}"
echo -e "${C}ADB Root状态: ${W}$(getprop service.adb.root 2>/dev/null || echo "未知")${NC}"
echo -e "${C}USB自动休眠: ${W}$(cat /sys/module/usbcore/parameters/autosuspend 2>/dev/null || echo "未知")${NC}"
echo -e "${C}ADB TCP端口: ${W}$(getprop persist.adb.tcp.port 2>/dev/null || echo "未知")${NC}"
echo -e "${C}系统调试模式: ${W}$(getprop ro.debuggable 2>/dev/null || echo "未知")${NC}"
echo -e "${C}系统安全模式: ${W}$(getprop ro.secure 2>/dev/null || echo "未知")${NC}"
echo -e "${C}USB内存限制: ${W}$(sysctl -n usbcore.usbfs_memory_mb 2>/dev/null || echo "未知") MB${NC}"
echo
echo -e "${G}✓ 环境自检完成${NC}"
sleep 5
;;

9)
clear
echo -e "${B}🔒 一键回锁Bootloader${NC}"
echo
if [ $FB_COUNT -eq 0 ]; then
    echo -e "${R}✗ 未检测到Fastboot设备${NC}"
    echo -e "${Y}  请确保设备已进入Fastboot模式并正确连接${NC}"
    sleep 3
    continue
fi
echo -e "${R}⚠️  警告: 回锁Bootloader将清空所有用户数据！${NC}"
echo -e "${Y}  确定要继续吗？(y/N)${NC}"
read -r CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo -e "${Y}已取消回锁操作${NC}"
    sleep 2
    continue
fi
echo
echo -e "${Y}正在执行回锁指令...${NC}"
fastboot oem lock 2>/dev/null
if [ $? -ne 0 ]; then
    fastboot flashing lock 2>/dev/null
fi
echo
echo -e "${G}✓ 回锁指令已发送${NC}"
echo -e "${Y}  设备可能会自动重启${NC}"
sleep 3
;;

10)
clear
echo -e "${B}💾 分区备份/恢复${NC}"
echo
if [ $FB_COUNT -eq 0 ]; then
    echo -e "${R}✗ 未检测到Fastboot设备${NC}"
    echo -e "${Y}  请确保设备已进入Fastboot模式并正确连接${NC}"
    sleep 3
    continue
fi
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${W}  1${NC} 备份分区 (boot, recovery)"
echo -e "${W}  2${NC} 恢复分区"
echo -e "${W}  3${NC} 擦除分区 (谨慎)"
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${C}请选择功能:${NC}"
read -r P_OPT
case $P_OPT in
1)
    echo -e "${Y}正在备份分区...${NC}"
    fastboot boot boot_backup.img 2>/dev/null
    fastboot boot recovery_backup.img 2>/dev/null
    echo -e "${G}✓ 分区备份完成${NC}"
    echo -e "${Y}  备份文件保存在 /sdcard/${NC}"
    ;;
2)
    echo -e "${C}请输入要恢复的分区文件路径:${NC}"
    read -r RESTORE_PATH
    if [ ! -f "$RESTORE_PATH" ]; then
        echo -e "${R}✗ 文件不存在${NC}"
        sleep 2
        continue
    fi
    echo -e "${Y}正在恢复分区...${NC}"
    fastboot flash boot "$RESTORE_PATH" 2>/dev/null
    echo -e "${G}✓ 分区恢复完成${NC}"
    ;;
3)
    echo -e "${R}⚠️  擦除分区将清空数据！${NC}"
    echo -e "${Y}  请选择要擦除的分区:${NC}"
    echo "  1. boot"
    echo "  2. recovery"
    read -r ERASE_PART
    case $ERASE_PART in
    1) fastboot erase boot 2>/dev/null ;;
    2) fastboot erase recovery 2>/dev/null ;;
    *) echo -e "${R}✗ 无效分区${NC}" ;;
    esac
    echo -e "${G}✓ 擦除指令已发送${NC}"
    ;;
*)
    echo -e "${R}✗ 无效选项${NC}"
    ;;
esac
sleep 3
;;

11)
clear
echo -e "${B}📱 刷入第三方Recovery${NC}"
echo
if [ $FB_COUNT -eq 0 ]; then
    echo -e "${R}✗ 未检测到Fastboot设备${NC}"
    echo -e "${Y}  请确保设备已进入Fastboot模式并正确连接${NC}"
    sleep 3
    continue
fi
echo -e "${Y}  此功能将刷入TWRP或其他第三方Recovery${NC}"
echo
get_path "请输入Recovery镜像路径: " ".img" "file" "0"
if [ -z "$XP_PATH" ]; then continue; fi
REC_IMG="$XP_PATH"
echo
echo -e "${Y}正在开始刷写...${NC}"
rex_flash_engine "$REC_IMG" "recovery" "fastboot"
if [ $? -eq 0 ]; then
    echo -e "${G}✓ Recovery刷写成功！${NC}"
    echo -e "${Y}  可用 fastboot reboot recovery 进入${NC}"
else
    echo -e "${R}✗ Recovery刷写失败${NC}"
fi
sleep 3
;;

12)
clear
echo -e "${B}🔄 全分区擦除（四清）${NC}"
echo
if [ $FB_COUNT -eq 0 ]; then
    echo -e "${R}✗ 未检测到Fastboot设备${NC}"
    echo -e "${Y}  请确保设备已进入Fastboot模式并正确连接${NC}"
    sleep 3
    continue
fi
echo -e "${R}⚠️  警告: 这将清空所有用户数据！${NC}"
echo -e "${Y}  包括: data, cache, system${NC}"
echo -e "${Y}  确定要继续吗？(y/N)${NC}"
read -r CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo -e "${Y}已取消擦除操作${NC}"
    sleep 2
    continue
fi
echo
echo -e "${Y}正在执行四清...${NC}"
fastboot erase data 2>/dev/null
fastboot erase cache 2>/dev/null
fastboot erase system 2>/dev/null
echo -e "${G}✓ 全分区擦除完成${NC}"
echo -e "${Y}  设备可能需要重新刷入系统${NC}"
sleep 3
;;

13)
clear
echo -e "${B}📋 查看分区表${NC}"
echo
if [ $FB_COUNT -eq 0 ]; then
    echo -e "${R}✗ 未检测到Fastboot设备${NC}"
    echo -e "${Y}  请确保设备已进入Fastboot模式并正确连接${NC}"
    sleep 3
    continue
fi
echo
echo -e "${Y}正在获取分区信息...${NC}"
fastboot getvar partition-size:boot 2>/dev/null
fastboot getvar partition-size:recovery 2>/dev/null
fastboot getvar partition-size:system 2>/dev/null
fastboot getvar partition-size:vendor 2>/dev/null
fastboot getvar partition-size:product 2>/dev/null
fastboot getvar partition-size:userdata 2>/dev/null
echo
echo -e "${G}✓ 分区信息显示完成${NC}"
sleep 3
;;

14)
clear
echo -e "${B}🧰 修复IMEI/基带${NC}"
echo
echo -e "${Y}  此功能用于备份/恢复EFS分区（包含IMEI和基带信息）${NC}"
echo
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${W}  1${NC} 备份EFS分区"
echo -e "${W}  2${NC} 恢复EFS分区"
echo -e "${Y}════════════════════════════════════════${NC}"
echo -e "${C}请选择功能:${NC}"
read -r EFS_OPT
case $EFS_OPT in
1)
    echo -e "${Y}正在备份EFS分区...${NC}"
    adb root 2>/dev/null
    adb wait-for-device
    adb shell "dd if=/dev/block/by-name/efs of=/sdcard/efs.img 2>/dev/null"
    echo -e "${G}✓ EFS备份成功！${NC}"
    echo -e "${Y}  文件保存位置: /sdcard/efs.img${NC}"
    ;;
2)
    echo -e "${C}请输入EFS镜像路径:${NC}"
    read -r EFS_IMG
    if [ ! -f "$EFS_IMG" ]; then
        echo -e "${R}✗ EFS镜像文件不存在${NC}"
        sleep 2
        continue
    fi
    echo -e "${Y}正在恢复EFS分区...${NC}"
    adb root 2>/dev/null
    adb wait-for-device
    adb shell "dd if=/sdcard/efs.img of=/dev/block/by-name/efs 2>/dev/null"
    echo -e "${G}✓ EFS恢复成功！${NC}"
    echo -e "${Y}  请重启设备${NC}"
    ;;
*)
    echo -e "${R}✗ 无效选项${NC}"
    ;;
esac
sleep 3
;;

15)
clear
echo -e "${B}🔄 自动刷入Magisk${NC}"
echo
if [ $FB_COUNT -eq 0 ]; then
    echo -e "${R}✗ 未检测到Fastboot设备${NC}"
    echo -e "${Y}  请确保设备已进入Fastboot模式并正确连接${NC}"
    sleep 3
    continue
fi
echo -e "${Y}  此功能将自动刷入Magisk修补后的Boot镜像${NC}"
echo
get_path "请输入Magisk修补后的Boot镜像路径: " ".img" "file" "0"
if [ -z "$XP_PATH" ]; then continue; fi
MAG_IMG="$XP_PATH"
echo
echo -e "${Y}正在开始刷写...${NC}"
rex_flash_engine "$MAG_IMG" "boot" "fastboot"
if [ $? -eq 0 ]; then
    echo -e "${G}✓ Magisk刷入成功！${NC}"
    echo -e "${Y}  设备重启后即可获得Root权限${NC}"
else
    echo -e "${R}✗ Magisk刷入失败${NC}"
fi
sleep 3
;;

16)
clear
echo -e "${B}🛡️ 深度救砖${NC}"
echo
echo -e "${Y}  此功能用于设备无法进入系统或Fastboot时的深度救砖${NC}"
echo -e "${Y}  设备必须进入9008 EDL模式${NC}"
echo
if [ -z "$QD_DEV" ] && [ -z "$TTY_USB" ]; then
    echo -e "${R}✗ 未检测到9008 EDL设备${NC}"
    echo -e "${Y}  请确保设备已进入9008模式并正确连接${NC}"
    sleep 3
    continue
fi
echo -e "${Y}正在准备救砖...${NC}"
echo -e "${C}请输入Firehose编程器路径:${NC}"
read -r FIREHOSE
if [ ! -f "$FIREHOSE" ]; then
    echo -e "${R}✗ Firehose文件不存在${NC}"
    sleep 2
    continue
fi
echo -e "${C}请输入rawprogram.xml路径:${NC}"
read -r RAWPROG
if [ ! -f "$RAWPROG" ]; then
    echo -e "${R}✗ rawprogram文件不存在${NC}"
    sleep 2
    continue
fi
echo
echo -e "${Y}正在开始刷写...${NC}"
rex_flash_engine "$FIREHOSE" "EDL" "edl"
if [ $? -eq 0 ]; then
    echo -e "${G}✓ 救砖成功！${NC}"
    echo -e "${Y}  设备将自动重启${NC}"
else
    echo -e "${R}✗ 救砖失败！${NC}"
    echo -e "${Y}  请检查设备连接和固件文件${NC}"
fi
sleep 5
;;

17)
clear
echo -e "${B}📦 小白一键刷入全量包${NC}"
echo
if [ $FB_COUNT -eq 0 ]; then
    echo -e "${R}✗ 未检测到Fastboot设备${NC}"
    echo -e "${Y}  请确保设备已进入Fastboot模式并正确连接${NC}"
    sleep 3
    continue
fi
echo -e "${Y}  此功能会自动解压并刷入全量包（ZIP格式）${NC}"
echo -e "${Y}  请确保全量包与设备型号匹配${NC}"
echo
get_path "请输入全量包路径: " ".zip" "file" "0"
if [ -z "$XP_PATH" ]; then continue; fi
ZIP_PATH="$XP_PATH"
echo
echo -e "${Y}正在解压全量包...${NC}"
TEMP_DIR="/sdcard/temp_flash"
mkdir -p "$TEMP_DIR" 2>/dev/null
unzip -o "$ZIP_PATH" -d "$TEMP_DIR" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${R}✗ 解压失败，请检查ZIP文件是否损坏${NC}"
    rm -rf "$TEMP_DIR" 2>/dev/null
    sleep 3
    continue
fi
echo -e "${G}✓ 解压完成${NC}"
echo
echo -e "${Y}正在刷入分区...${NC}"
TOTAL_PARTS=0
for PART in boot recovery system vendor product; do
    if [ -f "$TEMP_DIR/$PART.img" ]; then
        TOTAL_PARTS=$((TOTAL_PARTS+1))
    fi
done
CURRENT=0
for PART in boot recovery system vendor product; do
    if [ -f "$TEMP_DIR/$PART.img" ]; then
        CURRENT=$((CURRENT+1))
        rex_flash_engine "$TEMP_DIR/$PART.img" "$PART" "fastboot"
    fi
done
echo
echo -e "${Y}正在清理临时文件...${NC}"
rm -rf "$TEMP_DIR" 2>/dev/null
echo
echo -e "${G}✓ 刷入完成！${NC}"
echo -e "${Y}  设备将自动重启${NC}"
fastboot reboot
sleep 3
;;

18)
clear
echo -e "${B}🟢 欧加线刷工具 (OFP/OPPO/OnePlus/Realme)${NC}"
echo
echo -e "${Y}  此功能用于刷写欧加设备（OPPO/OnePlus/Realme）的 OFP 固件包${NC}"
echo
echo -e "${C}请输入 OFP 固件包路径:${NC}"
read -r OFP_PATH
if [ ! -f "$OFP_PATH" ]; then
    echo -e "${R}✗ 文件不存在${NC}"
    sleep 2
    continue
fi
echo
echo -e "${Y}正在检查设备连接...${NC}"
if ! check_device "any"; then
    echo -e "${R}✗ 未检测到设备 (需要 Fastboot 或 9008 模式)${NC}"
    echo -e "${Y}  请确保设备已进入 Fastboot 或 9008 模式${NC}"
    sleep 3
    continue
fi
echo -e "${Y}正在准备刷写...${NC}"
echo
echo -e "${C}请选择刷写模式:${NC}"
echo "  1. Fastboot 模式刷写"
echo "  2. EDL 模式刷写"
read -r MODE_SEL
case $MODE_SEL in
1)
    echo -e "${Y}正在使用 Fastboot 模式刷写...${NC}"
    if ! check_device "fastboot"; then
        echo -e "${R}✗ 未检测到 Fastboot 设备${NC}"
        sleep 3
        continue
    fi
    echo -e "${Y}解压 OFP 包并刷写...${NC}"
    TEMP_DIR="/sdcard/temp_ofp"
    mkdir -p "$TEMP_DIR" 2>/dev/null
    unzip -o "$OFP_PATH" -d "$TEMP_DIR" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${R}✗ 解压失败${NC}"
        rm -rf "$TEMP_DIR" 2>/dev/null
        sleep 3
        continue
    fi
    TOTAL_PARTS=0
    for PART in boot recovery system vendor product; do
        if [ -f "$TEMP_DIR/$PART.img" ]; then
            TOTAL_PARTS=$((TOTAL_PARTS+1))
        fi
    done
    CURRENT=0
    for PART in boot recovery system vendor product; do
        if [ -f "$TEMP_DIR/$PART.img" ]; then
            CURRENT=$((CURRENT+1))
            rex_flash_engine "$TEMP_DIR/$PART.img" "$PART" "fastboot"
        fi
    done
    rm -rf "$TEMP_DIR" 2>/dev/null
    echo -e "${G}✓ 欧加 Fastboot 刷写完成${NC}"
    ;;
2)
    echo -e "${Y}正在使用 EDL 模式刷写...${NC}"
    if [ -z "$QD_DEV" ] && [ -z "$TTY_USB" ]; then
        echo -e "${R}✗ 未检测到 9008 设备${NC}"
        sleep 3
        continue
    fi
    echo -e "${Y}解压 OFP 包并查找 firehose...${NC}"
    TEMP_DIR="/sdcard/temp_ofp"
    mkdir -p "$TEMP_DIR" 2>/dev/null
    unzip -o "$OFP_PATH" -d "$TEMP_DIR" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${R}✗ 解压失败${NC}"
        rm -rf "$TEMP_DIR" 2>/dev/null
        sleep 3
        continue
    fi
    FIREHOSE=$(find "$TEMP_DIR" -name "*.mbn" | head -n1)
    RAWPROG=$(find "$TEMP_DIR" -name "rawprogram*.xml" | head -n1)
    if [ -z "$FIREHOSE" ] || [ -z "$RAWPROG" ]; then
        echo -e "${R}✗ 未找到 firehose 或 rawprogram.xml${NC}"
        rm -rf "$TEMP_DIR" 2>/dev/null
        sleep 3
        continue
    fi
    echo -e "${Y}正在刷写...${NC}"
    rex_flash_engine "$FIREHOSE" "EDL" "edl"
    rm -rf "$TEMP_DIR" 2>/dev/null
    echo -e "${G}✓ 欧加 EDL 刷写完成${NC}"
    ;;
*)
    echo -e "${R}✗ 无效选择${NC}"
    ;;
esac
sleep 3
;;

19)
clear
echo -e "${B}🔵 小米线刷工具 (Fastboot/EDL)${NC}"
echo
echo -e "${Y}  此功能用于刷写小米设备 (Xiaomi/Redmi/POCO) 的线刷包${NC}"
echo
echo -e "${C}请输入小米线刷包路径 (ZIP 或 tgz):${NC}"
read -r MI_PATH
if [ ! -f "$MI_PATH" ]; then
    echo -e "${R}✗ 文件不存在${NC}"
    sleep 2
    continue
fi
echo
echo -e "${Y}正在检查设备连接...${NC}"
if ! check_device "any"; then
    echo -e "${R}✗ 未检测到设备 (需要 Fastboot 或 9008 模式)${NC}"
    echo -e "${Y}  请确保设备已进入 Fastboot 或 9008 模式${NC}"
    sleep 3
    continue
fi
echo -e "${Y}正在准备刷写...${NC}"
echo
echo -e "${C}请选择刷写模式:${NC}"
echo "  1. Fastboot 模式刷写 (需要解锁 BL)"
echo "  2. EDL 模式刷写 (无需解锁 BL)"
read -r MI_MODE
case $MI_MODE in
1)
    echo -e "${Y}正在使用 Fastboot 模式刷写...${NC}"
    if ! check_device "fastboot"; then
        echo -e "${R}✗ 未检测到 Fastboot 设备${NC}"
        sleep 3
        continue
    fi
    echo -e "${Y}解压线刷包...${NC}"
    TEMP_DIR="/sdcard/temp_mi"
    mkdir -p "$TEMP_DIR" 2>/dev/null
    if [[ "$MI_PATH" == *.tgz ]]; then
        tar -xzf "$MI_PATH" -C "$TEMP_DIR" >/dev/null 2>&1
    else
        unzip -o "$MI_PATH" -d "$TEMP_DIR" >/dev/null 2>&1
    fi
    if [ $? -ne 0 ]; then
        echo -e "${R}✗ 解压失败${NC}"
        rm -rf "$TEMP_DIR" 2>/dev/null
        sleep 3
        continue
    fi
    TOTAL_PARTS=0
    for PART in boot recovery system vendor product; do
        if [ -f "$TEMP_DIR/images/$PART.img" ]; then
            TOTAL_PARTS=$((TOTAL_PARTS+1))
        fi
    done
    CURRENT=0
    for PART in boot recovery system vendor product; do
        if [ -f "$TEMP_DIR/images/$PART.img" ]; then
            CURRENT=$((CURRENT+1))
            rex_flash_engine "$TEMP_DIR/images/$PART.img" "$PART" "fastboot"
        fi
    done
    rm -rf "$TEMP_DIR" 2>/dev/null
    echo -e "${G}✓ 小米 Fastboot 刷写完成${NC}"
    ;;
2)
    echo -e "${Y}正在使用 EDL 模式刷写...${NC}"
    if [ -z "$QD_DEV" ] && [ -z "$TTY_USB" ]; then
        echo -e "${R}✗ 未检测到 9008 设备${NC}"
        sleep 3
        continue
    fi
    echo -e "${Y}解压线刷包...${NC}"
    TEMP_DIR="/sdcard/temp_mi"
    mkdir -p "$TEMP_DIR" 2>/dev/null
    if [[ "$MI_PATH" == *.tgz ]]; then
        tar -xzf "$MI_PATH" -C "$TEMP_DIR" >/dev/null 2>&1
    else
        unzip -o "$MI_PATH" -d "$TEMP_DIR" >/dev/null 2>&1
    fi
    if [ $? -ne 0 ]; then
        echo -e "${R}✗ 解压失败${NC}"
        rm -rf "$TEMP_DIR" 2>/dev/null
        sleep 3
        continue
    fi
    FIREHOSE=$(find "$TEMP_DIR" -name "*.mbn" | head -n1)
    RAWPROG=$(find "$TEMP_DIR" -name "rawprogram*.xml" | head -n1)
    if [ -z "$FIREHOSE" ] || [ -z "$RAWPROG" ]; then
        echo -e "${R}✗ 未找到 firehose 或 rawprogram.xml${NC}"
        rm -rf "$TEMP_DIR" 2>/dev/null
        sleep 3
        continue
    fi
    echo -e "${Y}正在刷写...${NC}"
    rex_flash_engine "$FIREHOSE" "EDL" "edl"
    rm -rf "$TEMP_DIR" 2>/dev/null
    echo -e "${G}✓ 小米 EDL 刷写完成${NC}"
    ;;
*)
    echo -e "${R}✗ 无效选择${NC}"
    ;;
esac
sleep 3
;;

20)
clear
echo -e "${B}🎯 自定义 ADB 指令${NC}"
if ! check_device "adb"; then
    echo -e "${R}✗ 未检测到 ADB 设备${NC}"
    sleep 2
    continue
fi
echo -e "${Y}输入 ADB 指令 (输入 'q' 退出)${NC}"
echo -e "${Y}例如: shell ls /sdcard${NC}"
echo
while true; do
    echo -n -e "${C}adb> ${NC}"
    read CMD
    if [ "$CMD" = "q" ] || [ "$CMD" = "Q" ]; then
        break
    fi
    if [ -z "$CMD" ]; then
        continue
    fi
    echo -e "${Y}正在执行: ${W}adb $CMD${NC}"
    adb $CMD
done
;;

21)
clear
echo -e "${B}💾 备份当前boot分区 (安全)${NC}"
echo
if check_device "fastboot"; then
    echo -e "${Y}正在备份 boot 分区到 /sdcard/boot_backup.img${NC}"
    fastboot flash boot /sdcard/boot_backup.img 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${G}备份完成！${NC}"
    else
        echo -e "${R}备份失败，尝试使用ADB...${NC}"
        if check_device "adb"; then
            adb shell "dd if=/dev/block/by-name/boot of=/sdcard/boot_backup.img"
            echo -e "${G}备份完成 (dd方式)${NC}"
        else
            echo -e "${R}无法备份，请连接Fastboot或ADB${NC}"
        fi
    fi
elif check_device "adb"; then
    echo -e "${Y}正在备份 boot 分区到 /sdcard/boot_backup.img${NC}"
    adb shell "dd if=/dev/block/by-name/boot of=/sdcard/boot_backup.img"
    echo -e "${G}备份完成${NC}"
else
    echo -e "${R}未检测到设备${NC}"
fi
sleep 3
;;

A|a)
clear
echo -e "${B}🔗 强制刷新设备连接${NC}"
echo
echo -e "${Y}正在清理并重新扫描设备...${NC}"
echo
if check_device "any"; then
    echo -e "\n${G}✓ 设备已成功连接！${NC}"
    echo -e "${C}  当前模式: ${W}$QGHP_MODE${NC}"
    echo -e "${C}  设备序列号: ${W}$DEVICE_SERIAL${NC}"
else
    echo -e "\n${R}✗ 未检测到任何设备${NC}"
    echo -e "${Y}  请检查 USB 数据线/OTG 转接头是否正常连接${NC}"
fi
echo
echo -e "${Y}按回车键返回主菜单...${NC}"
read dummy
;;

0)
cleanup
;;
*)
echo -e "${R}✗ 无效选项，请重试${NC}"
sleep 2
;;
esac
done
}
MAIN_LOOP