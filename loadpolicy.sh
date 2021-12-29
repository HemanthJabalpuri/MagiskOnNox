#!/system/bin/sh

for module in $(ls /data/adb/modules); do
  if ! [ -f "/data/adb/modules/$module/disable" ] && [ -f "/data/adb/modules/$module/sepolicy.rule" ]; then
    /sbin/magiskpolicy --live --apply "/data/adb/modules/$module/sepolicy.rule"
  fi
done
