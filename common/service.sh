#!/system/bin/sh
MODDIR=${0%/*}
INFO=/data/adb/modules/.gboardlite_apmods-files
MODID=gboardlite_apmods
LIBDIR=/system
MODPATH=/data/adb/modules/gboardlite_apmods
MODDIR="${0%/*}"
CONFIG_FILE="$MODDIR/.gboardlite_apmods"
VW_PACKAGE=$(grep "VW_PACKAGE=" ${CONFIG_FILE} | cut -d"=" -f2)
PROPFILE="$MODDIR/module.prop"
if [[ -n "$(ls -a /data/misc/shared_relro)" ]]; then
    if [[ "pm list packages -a | grep -q ${VW_PACKAGE}" ]]; then
        sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ✅ Module is working ] /g' "$PROPFILE"
    fi
else
    sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ 🙁 Module installed but you need to install Gboard Lite manually ] /g' "$PROPFILE"
fi

