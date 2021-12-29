#!/system/bin/sh
# This script is written by HuskyDG

[ "$(whoami)" = "root" ] || abort "! Run script as root only"

abort() {
  echo "$1"; exit 1
}

ABI=$(getprop ro.product.cpu.abi)
ABI32=x86
case "$ABI" in
  x86|x86_64) true;;
  *) abort "Not x86";;
esac

tmpd="$PWD"; [ "$PWD" = "/" ] && tmpd=""
case "$0" in
  /*) cdir="$0";;
  *) cdir="$tmpd/${0#./}";;
esac
cdir="${cdir%/*}"

APKFILE="$cdir/magisk.apk"
bb=/data/local/tmp/busybox
MTMPDIR=/dev/tmp_magisk
MAGISKCORE=/system/etc/magisk

echo "******************************"
echo "      Magisk installer"
echo "******************************"

cd "$cdir"

cp busybox $bb
chmod 777 $bb
mkdir $MTMPDIR


echo "- Mount system partition (Read-write)"
mount -o rw,remount /system || abort "! Failed to mount system partition"


echo "- Initialize Magisk Core"
rm -rf $MAGISKCORE
mkdir $MAGISKCORE
chown root:root $MAGISKCORE
chmod 750 $MAGISKCORE

$bb unzip -oj "$APKFILE" 'assets/util_functions.sh' -d $MTMPDIR
[ -f $MTMPDIR/util_functions.sh ] || abort "! This apk is not Magisk app"
. $MTMPDIR/util_functions.sh
echo "-- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
api_level_arch_detect # from util_functions.sh


echo "- Extract Magisk APK"
mkdir $MTMPDIR/magisk
$bb unzip -oj "$APKFILE" "lib/$ABI/*" -x lib/$ABI/busybox.so -d $MTMPDIR/magisk
chmod -R 777 $MTMPDIR/magisk

if [ $IS64BIT == true ]; then
  mkdir $MTMPDIR/magisk32
  $bb unzip -oj "$APKFILE" "lib/$ABI32/*" -x lib/$ABI/busybox.so -d $MTMPDIR/magisk32
  chmod -R 777 $MTMPDIR/magisk32
fi

(
  cd $MTMPDIR/magisk
  for file in lib*.so; do
    chmod 755 $file
    mv $file "$MAGISKCORE/${file:3:${#file}-6}"
    echo "  add magisk binary: ${file:3:${#file}-6}"
  done

  if [ $IS64BIT == true ]; then
    cd $MTMPDIR/magisk32
    for file in lib*.so; do
      chmod 755 $file
      if [ ! -f "$MAGISKCORE/${file:3:${#file}-6}" ]; then
        mv $file "$MAGISKCORE/${file:3:${#file}-6}"
        echo "  add magisk binary: ${file:3:${#file}-6}"
      fi
    done
  fi
)

mkdir -p /data/adb/magisk
$bb unzip -oj "$APKFILE" 'assets/*' -x 'assets/chromeos/*' -d /data/adb/magisk


echo "- Install Magisk loader..."
cp overlay.sh $MAGISKCORE/
cp loadpolicy.sh $MAGISKCORE/
cp magisk.rc /system/etc/init/


echo "- Mount system partition (Read-only)"
mount -o ro,remount /system


echo "- Install Magisk app..."
pm install -r "$APKFILE" || echo "* Install Magisk yourself"


rm -rf $MTMPDIR
echo "- Done!"
