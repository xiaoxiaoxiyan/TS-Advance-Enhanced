#!/system/bin/sh
# =========================================================
# 自适应 Root 模块安装器
# 支持: Magisk Alpha / KernelSU / Sukisu Ultra / APatch
# 不包含包名检测，自动识别并执行对应方案
# =========================================================

# ---------- 基础环境 ----------
MODID="your_module_id"        # 你的模块 ID（按实际修改）
LOCAL_VER="0516"              # 本地版本，用于更新检测（可选）

# ---------- 工具函数 ----------
check_path() { [ -e "$1" ] && return 0; return 1; }
check_prop() {
    local v
    v="$(getprop "$1" 2>/dev/null)"
    [ -n "$v" ] && return 0
    return 1
}

# ---------- 各 Root 管理器检测（无包名）----------
detect_magisk_alpha() {
    check_path "/data/adb/magisk_alpha"           && return 0
    check_path "/data/adb/magisk_alpha.db"        && return 0
    command -v magisk >/dev/null 2>&1 && magisk -v 2>&1 | grep -iq "alpha" && return 0
    getprop ro.magisk.version 2>/dev/null | grep -iq "alpha" && return 0
    return 1
}

detect_kernelsu() {
    check_path "/data/adb/ksud"           && return 0
    check_path "/system/bin/ksud"         && return 0
    check_path "/data/adb/ksu"            && return 0
    check_path "/data/adb/ksu/bin/su"     && return 0
    command -v ksud >/dev/null 2>&1 && ksud -v 2>&1 | grep -iq "kernelsu" && return 0
    uname -r 2>/dev/null | grep -iq "kernelsu" && return 0
    check_prop "ro.kernel.version" && getprop ro.kernel.version 2>/dev/null | grep -iq "kernelsu" && return 0
    return 1
}

detect_sukisu_ultra() {
    check_path "/data/adb/sukisu"         && return 0
    check_path "/data/adb/sukisud"        && return 0
    check_path "/system/bin/sukisud"      && return 0
    check_path "/data/adb/sukisu/bin/su"  && return 0
    command -v sukisud >/dev/null 2>&1 && sukisud -v 2>&1 | grep -iq "sukisu" && return 0
    check_prop "ro.sukisu.version"        && return 0
    return 1
}

detect_apatch() {
    check_path "/data/adb/apd"            && return 0
    check_path "/system/bin/apd"          && return 0
    check_path "/data/adb/ap"             && return 0
    check_path "/data/adb/ap/bin/su"      && return 0
    command -v apd >/dev/null 2>&1 && apd -v 2>&1 | grep -iq "apatch" && return 0
    check_prop "ro.apatch.version"        && return 0
    uname -r 2>/dev/null | grep -iq "apatch" && return 0
    return 1
}

# ---------- 智能识别（优先环境变量，若无则调用检测函数）----------
if [ "$KSU" = "true" ]; then
    RootImplement="KernelSU"
elif [ "$APATCH" = "true" ]; then
    RootImplement="APatch"
elif [ -n "$SUKISU" ] && [ "$SUKISU" = "true" ]; then
    # 假如未来 Sukisu Ultra 也设置环境变量可以这样兼容
    RootImplement="SukisuUltra"
else
    # 环境变量未命中，使用文件/属性特征检测
    if detect_magisk_alpha; then
        RootImplement="MagiskAlpha"
    elif detect_kernelsu; then
        RootImplement="KernelSU"
    elif detect_sukisu_ultra; then
        RootImplement="SukisuUltra"
    elif detect_apatch; then
        RootImplement="APatch"
    else
        echo "! 未检测到任何受支持的 Root 管理器，安装终止"
        exit 1
    fi
fi

# ---------- 映射执行方案 ----------
case "$RootImplement" in
    "MagiskAlpha")
        ExecuteScheme="MagiskAlpha"
        ;;
    "KernelSU")
        ExecuteScheme="KernelSU"
        ;;
    "SukisuUltra")
        ExecuteScheme="SukisuUltra"
        ;;
    "APatch")
        ExecuteScheme="APatch"
        ;;
esac

echo "- 检测到: $RootImplement"
echo "- 执行方案: $ExecuteScheme"

# ===================== 权限设置 =====================
set_perm_recursive "$MODPATH" 0 0 0755 0755

# ===================== 版本检测（保留参考）=====================

# ===================== 各方案执行函数 =====================
# 方案1：Magisk Alpha
execute_MagiskAlpha() {
    echo "- 执行【Magisk Alpha 方案】"
    # 安装预置 APK
    for apk in "$MODPATH/apk"/*.apk; do
        [ ! -f "$apk" ] && continue
        echo "  安装 APK: $(basename "$apk")"
        pm install -r "$apk"
    done
    # 安装专属子模块 zip
    for zip in "$MODPATH/Alpha"/*.zip; do
        [ ! -f "$zip" ] && continue
        echo "  刷入子模块: $(basename "$zip")"
        install_module "$zip"
    done
    magisk --remove-modules XEC
    echo "- Magisk Alpha 方案执行完毕"
}

# 方案2：KernelSU
execute_KernelSU() {
    echo "- 执行【KernelSU 方案】"
    local hma="$MODPATH/apk/HMA.apk"
    if [ -f "$hma" ]; then
        echo "  安装 HMA"
        pm install -r "$hma"
    fi
    for zip in "$MODPATH/ty"/*.zip; do
        [ ! -f "$zip" ] && continue
        echo "  准备刷入: $(basename "$zip")"
        if command -v ksud >/dev/null 2>&1; then
            ksud module install "$zip"
            echo "  ksud 执行返回: $?"
        else
            echo "  ksud 命令不存在，尝试 install_module"
            install_module "$zip" 2>&1
        fi
    done
    # 所有子模块安装完成后，静默卸载母模块自身
rm -rf /data/adb/modules/XEC
    echo "- KernelSU 方案执行完毕"
}

# 方案3：Sukisu Ultra
execute_SukisuUltra() {
    echo "- 执行【Sukisu Ultra 方案】"
    # 如果需要安装 APK，可自行添加
    # 假设只安装 HMA
    local hma="$MODPATH/apk/HMA.apk"
    [ -f "$hma" ] && pm install -r "$hma"
    # 刷入专属子模块
    for zip in "$MODPATH/ty"/*.zip; do
        [ ! -f "$zip" ] && continue
        echo "  刷入子模块: $(basename "$zip")"
        install_module "$zip"
    done
    echo "- Sukisu Ultra 方案执行完毕"
}

# 方案4：APatch
execute_APatch() {
    echo "- 执行【APatch 方案】"
    # 只安装 HMA
    local hma="$MODPATH/apk/HMA.apk"
    [ -f "$hma" ] && pm install -r "$hma"
    # 刷入专属子模块
    for zip in "$MODPATH/ty"/*.zip; do
        [ ! -f "$zip" ] && continue
        echo "  刷入子模块: $(basename "$zip")"
        install_module "$zip"
    done
    apd module uninstall XEC
    echo "- APatch 方案执行完毕"
}

# ===================== 调度执行 =====================
case "$ExecuteScheme" in
    "MagiskAlpha")    execute_MagiskAlpha ;;
    "KernelSU")       execute_KernelSU ;;
    "SukisuUltra")    execute_SukisuUltra ;;
    "APatch")         execute_APatch ;;
    *)                echo "! 未知方案" ; exit 1 ;;
esac

# ===================== 收尾清理 =====================
# 删除母模块自身临时文件（可选）
rm -rf "$MODPATH/apk" "$MODPATH/magisk_alpha" "$MODPATH/kernelsu" \
       "$MODPATH/sukisu_ultra" "$MODPATH/apatch" 2>/dev/null
rm -rf /data/adb/modules/XEC
rm -rf /data/adb/XEC



echo "即将转跳QQ群"

sleep 3
GROUP_CODE="1084259061"
am start -a android.intent.action.VIEW \
    -d "mqqapi://card/show_pslcard?src_type=internal&version=1&uin=$GROUP_CODE&card_type=group&source=external" \
    >/dev/null 2>&1

echo ""
echo "*********************************************"
echo "- 安装完成，请重启设备使模块生效"
echo "- 当前 Root 方案: $RootImplement"
echo "*********************************************"