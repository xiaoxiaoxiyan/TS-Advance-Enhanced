chmod -R 777 /data/adb/modules/tyedl
MODDIR=${0%/*}
mount --bind $MODDIR/system/bin/edl /system/bin/edl
mount --bind $MODDIR/system/bin/edl_vip_auth /system/bin/edl_vip_auth