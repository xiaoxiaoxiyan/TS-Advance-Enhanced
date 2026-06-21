#!/bin/sh
[ $(id -u) -ne 0 ] && echo -e "\n\033[31m请以root身份运行\033[0m" && exit 1

adb_version=$(adb version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
fastboot_version=$(fastboot --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
edl_version=$(edl --version )

check_tool() {
    if command -v $1 >/dev/null 2>&1; then
        echo -e "\033[32m[✓] $1 工具检测成功\033[0m"
        return 0
    else
        echo -e "\033[31m[✗] $1 工具检测失败\033[0m"
        return 1
    fi
}

check_usb_module() {
    MOD_DIR="/data/adb/modules/usbPro+"
    if [ -d "$MOD_DIR" ] && [ -f "${MOD_DIR}/module.prop" ]; then
        echo -e "\033[32m[✓] USB Pro+ 模块已安装并正常存在\033[0m"
        if grep -q "^disabled=0" "${MOD_DIR}/module.prop"; then
            echo -e "\033[32m[✓] USB Pro+ 模块已启用\033[0m"
        else
            echo -e "\033[33m[!] USB Pro+ 模块当前已禁用\033[0m"
        fi
    else
        echo -e "\033[31m[✗] 未检测到 USB Pro+ 模块\033[0m"
    fi
}

sh_path=$(command -v sh)
bash_path=$(command -v bash)
clear
echo -e "\n\n"
if [ "$bash_path" != "" ] && echo "$bash_path" | grep -q "bin.mt.Pro+" && [ "$sh_path" != "" ] && echo "$sh_path" | grep -q "bin.mt.Pro+"; then
  echo -e "运行环境：📱MT扩展环境"
elif [ "$bash_path" != "" ] && echo "$bash_path" | grep -q "com.termux" && [ "$sh_path" != "" ] && echo "$sh_path" | grep -q "com.termux"; then
  echo -e "运行环境：📱Termux环境"
elif [ "$sh_path" = "/system/bin/sh" ]; then
  echo -e "运行环境：📱Android环境"
elif [ "$bash_path" = "/usr/bin/bash" ] && [ "$sh_path" = "/usr/bin/sh" ]; then
  echo -e "运行环境：💻Linux环境" 
else
  echo -e "运行环境：❗️未知环境" 
fi

echo -e "\nUSB Pro+ 模块检测"
check_usb_module

echo -e "\n基本工具 (必要)"
check_tool adb
check_tool fastboot
echo -e "\n镜像生成(可忽略)"
check_tool lpmake
echo -e "\n解压工具 (可忽略)"
check_tool payload-dumper-go
check_tool gzip
check_tool tar
echo -e "\n9008 (可忽略)"
check_tool edl
check_tool lsusb
echo -e "\n一键 root (KernelSU)"
check_tool libksud
echo -e "\nADB 版本：${adb_version:-未知}"
echo -e "Fastboot 版本：${fastboot_version:-未知}"
echo -e "edl 版本: ${edl_version:-未知}"
