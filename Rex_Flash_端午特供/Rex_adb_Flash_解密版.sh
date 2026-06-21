#!/system/bin/sh

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;31m✗ 需要 Root 权限\033[0m"
    exit 1
fi

R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
C='\033[0;36m'
M='\033[0;35m'
W='\033[1;37m'
NC='\033[0m'

clear
echo -e "${R}"
echo "██████╗ ███████╗██╗  ██╗    █████╗ ██████╗ ██████╗     ███████╗██╗      █████╗ ███████╗██╗  ██╗"
echo "██╔══██╗██╔════╝╚██╗██╔╝    ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝██║     ██╔══██╗██╔════╝██║  ██║"
echo "██████╔╝█████╗   ╚███╔╝     ███████║██║  ██║██████╔╝    █████╗  ██║     ███████║███████╗███████║"
echo "██╔══██╗██╔══╝   ██╔██╗     ██╔══██║██║  ██║██╔══██╗    ██╔══╝  ██║     ██╔══██║╚════██║██╔══██║"
echo "██║  ██║███████╗██╔╝ ██╗    ██║  ██║██████╔╝██║  ██║    ██║     ███████╗██║  ██║███████║██║  ██║"
echo "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝    ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "${W}      REX_ADB_FLASH ｜ 强大的adb工具箱 ｜ v3.1${NC}"
echo -e "${C}  作者: Rex ｜ 支持: 高通/联发科 ｜ 快速执行adb指令 ｜ 酷安：Rexyy${NC}"
echo

check_device() {
    if fastboot devices 2>/dev/null | grep -q "fastboot"; then
        echo -e "${G}✓ Fastboot 设备已连接${NC}"
        return 1
    elif adb devices 2>/dev/null | grep -v "List" | grep -q "device$"; then
        echo -e "${G}✓ ADB 设备已连接${NC}"
        return 2
    else
        echo -e "${R}✗ 未检测到设备${NC}"
        return 0
    fi
}

loading_animation() {
    local msg=$1
    local spin=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    while [ $i -lt 20 ]; do
        printf "\r${C}%s ${W}%s${NC}" "${spin[$((i % 10))]}" "$msg"
        sleep 0.1
        i=$((i + 1))
    done
    printf "\r${G}✓ %s 完成${NC}\n" "$msg"
}

while true; do
    echo -e "${W}  1${NC} 🔓 解除 Bootloader 锁"
    echo -e "${W}  2${NC} 🔒 回锁 Bootloader"
    echo -e "${W}  3${NC} ⚡ 进入 Fastboot 模式"
    echo -e "${W}  4${NC} 📡 进入 9008 EDL 模式"
    echo -e "${W}  5${NC} 📲 进入 MTK 下载模式"
    echo -e "${W}  6${NC} 🧹 擦除指定分区"
    echo -e "${W}  7${NC} 💾 自定义刷入分区"
    echo -e "${W}  8${NC} 🔄 重启到 FastbootD"
    echo -e "${W}  9${NC} 🛠️ ADB 自定义命令"
    echo -e "${W}  0${NC} ❌ 退出"
    echo -n -e "${C}请选择: ${NC}"
    read OPT

    case $OPT in
        1)
            check_device
            if [ $? -eq 1 ]; then
                echo -e "${Y}正在解除 Bootloader 锁...${NC}"
                fastboot oem unlock 2>/dev/null || fastboot flashing unlock 2>/dev/null
                loading_animation "解锁命令发送"
            else
                echo -e "${R}设备未处于 Fastboot 模式${NC}"
            fi
            ;;
        2)
            check_device
            if [ $? -eq 1 ]; then
                echo -e "${Y}正在回锁 Bootloader...${NC}"
                fastboot oem lock 2>/dev/null || fastboot flashing lock 2>/dev/null
                loading_animation "回锁命令发送"
            else
                echo -e "${R}设备未处于 Fastboot 模式${NC}"
            fi
            ;;
        3)
            check_device
            if [ $? -eq 2 ]; then
                echo -e "${Y}正在重启到 Fastboot...${NC}"
                adb reboot bootloader
                loading_animation "设备重启中"
            else
                echo -e "${R}设备未处于 ADB 模式${NC}"
            fi
            ;;
        4)
            check_device
            if [ $? -eq 1 ]; then
                echo -e "${Y}正在进入 9008 EDL 模式...${NC}"
                fastboot oem edl 2>/dev/null || fastboot reboot edl 2>/dev/null
                loading_animation "设备重启中"
            else
                echo -e "${R}设备未处于 Fastboot 模式${NC}"
            fi
            ;;
        5)
            check_device
            if [ $? -eq 2 ]; then
                echo -e "${Y}正在进入 MTK 下载模式...${NC}"
                adb reboot bootloader
                loading_animation "重启中"
                echo -e "${Y}请手动按住音量上键进入 MTK 下载模式${NC}"
            else
                echo -e "${R}设备未处于 ADB 模式${NC}"
            fi
            ;;
        6)
            check_device
            if [ $? -eq 1 ]; then
                echo -n -e "${C}请输入要擦除的分区名称 (如 boot, recovery, system): ${NC}"
                read PART
                if [ -z "$PART" ]; then
                    echo -e "${R}分区名称不能为空${NC}"
                else
                    echo -e "${Y}正在擦除 ${PART} 分区...${NC}"
                    fastboot erase "$PART"
                    loading_animation "擦除完成"
                fi
            else
                echo -e "${R}设备未处于 Fastboot 模式${NC}"
            fi
            ;;
        7)
            check_device
            if [ $? -eq 1 ]; then
                echo -n -e "${C}请输入分区名称: ${NC}"
                read PART
                echo -n -e "${C}请输入镜像文件路径: ${NC}"
                read IMG
                if [ -z "$PART" ] || [ -z "$IMG" ]; then
                    echo -e "${R}分区和镜像路径不能为空${NC}"
                elif [ ! -f "$IMG" ]; then
                    echo -e "${R}镜像文件不存在${NC}"
                else
                    echo -e "${Y}正在刷入 ${PART} 分区...${NC}"
                    fastboot flash "$PART" "$IMG"
                    loading_animation "刷入完成"
                fi
            else
                echo -e "${R}设备未处于 Fastboot 模式${NC}"
            fi
            ;;
        8)
            check_device
            if [ $? -eq 2 ]; then
                echo -e "${Y}正在从 ADB 重启到 FastbootD...${NC}"
                adb reboot fastboot
                loading_animation "设备重启中"
            elif [ $? -eq 1 ]; then
                echo -e "${Y}正在从 Fastboot 重启到 FastbootD...${NC}"
                fastboot reboot fastboot
                loading_animation "设备重启中"
            else
                echo -e "${R}设备未处于 ADB 或 Fastboot 模式${NC}"
            fi
            ;;
        9)
            check_device
            if [ $? -eq 2 ]; then
                echo -e "${Y}进入 ADB 自定义命令模式 (输入 'q' 退出)${NC}"
                echo -e "${C}示例: shell ls, shell pm list packages, push file /sdcard/${NC}"
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
                    echo
                done
            else
                echo -e "${R}设备未处于 ADB 模式${NC}"
            fi
            ;;
        0)
            echo -e "\n${G}感谢使用 Rex_adb_Flash！${NC}"
            exit 0
            ;;
        *)
            echo -e "${R}无效选项，请重试${NC}"
            ;;
    esac
    sleep 2
done