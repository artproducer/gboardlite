SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true
MINAPI=27

# Function to print title with centered alignment
ui_print_title() {
  local msg="$1"
  local term_width=$(getprop ro.product.max_width)
  local padding=$(((term_width - ${#msg}) / 2))
  printf "%${padding}s%s\n" " " "$msg"
}

# Function to print module information
print_modname() {
  MODNAME=$(grep_prop name $TMPDIR/module.prop)
  MODVER=$(grep_prop version $TMPDIR/module.prop)
  DV=$(grep_prop author $TMPDIR/module.prop)
  AndroidVersion=$(getprop ro.build.version.release)
  Device=$(getprop ro.product.device)
  Model=$(getprop ro.product.model)
  Brand=$(getprop ro.product.brand)

  ui_print ""
  ui_print "<<<< MULCH WEBVIEW ONLINE INSTALLER >>>>"
  ui_print ""
  sleep 0.01
  echo "-------------------------------------"
  echo -e "- Module：\c"
  echo "$MODNAME"
  sleep 0.01
  echo -e "- Version：\c"
  echo "$MODVER"
  sleep 0.01
  echo -e "- Author：\c"
  echo "$DV"
  sleep 0.01
  echo -e "- Android：\c"
  echo "$AndroidVersion"
  sleep 0.01

  if [ "$BOOTMODE" ] && [ "$KSU" ]; then
    ui_print "- Proveedor: KernelSU App"
    ui_print "- KernelSU：$KSU_KERNEL_VER_CODE [kernel] + $KSU_VER_CODE [ksud]"
    REMOVE="
/system/product/app/webview
/system/product/app/WebView
/system/product/app/WebViewGoogle
/system/product/app/WebViewGoogle64
/system/product/app/WebView64
/system/product/app/WebViewGoogle-Stub
"
    if [ "$(which magisk)" ]; then
      ui_print "*********************************************************"
      ui_print "! ¡La implementación de múltiples root NO es compatible!"
      ui_print "! Por favor, desinstala Magisk antes de instalar Zygisksu"
      abort "*********************************************************"
    fi
  elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
    ui_print "- Proveedor: Magisk App"
    REPLACE="
/system/product/app/webview
/system/product/app/WebView
/system/product/app/WebViewGoogle
/system/product/app/WebViewGoogle64
/system/product/app/WebView64
/system/product/app/WebViewGoogle-Stub
"
  else
    ui_print "*********************************************************"
    ui_print "Recovery no soportado"
    abort "*********************************************************"
  fi
  sleep 0.01
  echo "-------------------------------------"
}

# Function to handle module installation
on_install() {
  mkdir -p $MODPATH/system/bin >/dev/null 2>&1
  unzip -oj "$ZIPFILE" "system/bin/$ARCH/curl" -d $MODPATH/system/bin >/dev/null 2>&1
  if [ ! -f "$MODPATH/system/bin/curl" ]; then
    echo "Error: no se pudo extraer curl a $MODPATH/system/bin"
    exit 1
  fi
  set_perm $MODPATH/system/bin/curl root root 777
  export PATH=$MODPATH/system/bin:$PATH

  [ -z $MINAPI ] || { [ $API -lt $MINAPI ] && abort "- ¡El API de tu sistema, $API, es inferior al API mínimo de $MINAPI! ¡Abortando!"; }

  getVersion() {
    VERSION=$(dumpsys package us.spotco.mulch_wv | grep -m1 versionName)
    VERSION="${VERSION#*=}"
  }

  mkdir -p $MODPATH/system/product/app/MulchWebview
  mkdir -p $MODPATH/system/product/overlay
  VW_APK_URL="https://gitlab.com/divested-mobile/mulch/-/raw/master/prebuilt/${ARCH}/webview.apk"

  download_with_module_curl() {
    $MODPATH/system/bin/curl -skL "$VW_APK_URL" -o "$MODPATH/system/product/app/MulchWebview/webview.apk"
  }

  ui_print "- Verificando Last version de Mulch WebView..."
  sleep 1.0
  ui_print "- Descargando Mulch WebView for [${ARCH}] espere..."
  download_with_module_curl
  if [ ! -f "$MODPATH/system/product/app/MulchWebview/webview.apk" ]; then
    echo "- Error al descargar, verifica conexion!"
    exit 1
  fi

  for i in $(find $MODPATH -type f -name "*.sh" -o -name "*.prop" -o -name "*.rule"); do
    [ -f $i ] && {
      sed -i -e "/^#/d" -e "/^ *$/d" $i
      [ "$(tail -1 $i)" ] && echo "" >>$i
    }
  done

  getVersion
  if [ -z "$(pm list packages us.spotco.mulch_wv)" ]; then
    ui_print "- Mulch Webview no está instalado!"
  else
    grep us.spotco.mulch_wv /proc/self/mountinfo | while read -r line; do
      ui_print "- Desmontando"
      mountpoint=$(echo "$line" | cut -d' ' -f5)
      umount -l "${mountpoint%%\\*}"
    done
  fi

  am force-stop us.spotco.mulch_wv

  ui_print "- Instalando Mulch Webview..."
  set_perm $MODPATH/system/product/app/MulchWebview/webview.apk 1000 1000 644 u:object_r:apk_data_file:s0 >/dev/null 2>&1
  if ! pm install --user 0 -i us.spotco.mulch_wv -r -d $MODPATH/system/product/app/MulchWebview/webview.apk >/dev/null 2>&1; then
    ui_print "- Error: la instalación de APK falló!"
    abort
  else
    getVersion
    ui_print "- Mulch Webview $VERSION instalado!"
  fi
  ui_print "- Extrayendo WebViewOverlay for [${ARCH}]..."
  unzip -oj "$ZIPFILE" "common/overlay/$ARCH/WebviewOverlay.apk" -d $MODPATH/system/product/overlay >/dev/null 2>&1
  am force-stop us.spotco.mulch_wv
  ui_print "- Optimizando Mulch WebView $VERSION..."
  nohup cmd package compile --reset us.spotco.mulch_wv >/dev/null 2>&1
}

# Function to set permissions
set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm $MODPATH/system/bin/daemon 0 0 0755
  ui_print "- Telegram: @apmods"
  sleep 4
  nohup am start -a android.intent.action.VIEW -d https://t.me/apmods?boost >/dev/null 2>&1
}
