#!/system/bin/sh
MODDIR=${0%/*}
INFO=/data/adb/modules/.gboardlite_apmods-files
MODID=gboardlite_apmods
LIBDIR=/system
MODPATH=/data/adb/modules/gboardlite_apmods
if [ -f $INFO ]; then
  while read LINE; do
    if [ "$(echo -n $LINE | tail -c 1)" == "~" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f $LINE~ $LINE
    else
      rm -f $LINE
      while true; do
        LINE=$(dirname $LINE)
        [ "$(ls -A $LINE 2>/dev/null)" ] && break 1 || rm -rf $LINE
      done
    fi
  done < $INFO
  rm -f $INFO
fi


