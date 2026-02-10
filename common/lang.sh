#!/system/bin/sh
# Gboard Lite - Localization System
# Provides detect_language(), _msg(), and ui_print_lang() for all module scripts

LANG_ES=false

# Detect system language (Spanish or English fallback)
detect_language() {
	local system_lang=$(getprop persist.sys.locale)
	[ -z "$system_lang" ] && system_lang=$(getprop ro.product.locale.language)
	case "$system_lang" in
	*es* | *ES* | es_* | ES_* | ES-* | es-*) LANG_ES=true ;;
	*) LANG_ES=false ;;
	esac
}

# Helper: returns Spanish or English text based on LANG_ES
_msg() { [ "$LANG_ES" = true ] && echo "$1" || echo "$2"; }

# Print localized UI messages (install-time)
ui_print_lang() {
	local key="$1"
	case "$key" in
	"header")
		ui_print "<<<< $MODNAME $MODVER >>>>"
		;;
	"module_info")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Modulo: $MODNAME"
			ui_print "- Autor: $DV"
		else
			ui_print "- Module: $MODNAME"
			ui_print "- Author: $DV"
		fi
		ui_print "- Version: $MODVER"
		ui_print "- Android: $AndroidVersion"
		ui_print "- $(_msg "Dispositivo" "Device"): $Brand $Model ($Device)"
		;;
	"provider_ksu")
		ui_print "- $(_msg "Proveedor" "Provider"): KernelSU App"
		ui_print "- KernelSU: $KSU_KERNEL_VER_CODE [kernel] + $KSU_VER_CODE [ksud]"
		;;
	"provider_magisk")
		ui_print "- $(_msg "Proveedor" "Provider"): Magisk App"
		ui_print "- Magisk: $MAGISK_VER ($MAGISK_VER_CODE)"
		;;
	"multiple_root_error")
		ui_print "*********************************************************"
		ui_print "! $(_msg "Las implementaciones de multiples root NO son compatibles!" "Multiple root implementations are NOT supported!")"
		ui_print "! $(_msg "Por favor desinstala Magisk antes de instalar este modulo" "Please uninstall Magisk before installing this module")"
		;;
	"unsupported_recovery")
		ui_print "*********************************************************"
		ui_print "! $(_msg "Entorno de recovery no compatible" "Unsupported recovery environment")"
		ui_print "! $(_msg "Por favor usa Magisk o KernelSU" "Please use Magisk or KernelSU")"
		;;
	"api_error")
		abort "- $(_msg "Tu API del sistema ($API) es menor que el API minimo requerido ($MINAPI)! Abortando!" \
			"Your system API ($API) is lower than minimum required API ($MINAPI)! Aborting!")"
		;;
	"extracting_binaries")
		ui_print "- $(_msg "Extrayendo binarios requeridos" "Extracting required binaries")"
		;;
	"failed_extract_curl")
		ui_print "! $(_msg "Error al extraer el binario curl" "Failed to extract curl binary")"
		;;
	"failed_extract_cmpr")
		ui_print "! $(_msg "Error al extraer el binario cmpr" "Failed to extract cmpr binary")"
		;;
	"curl_not_found")
		ui_print "! $(_msg "Binario curl no encontrado despues de la extraccion" "curl binary not found after extraction")"
		;;
	"extracting_system_files")
		ui_print "- $(_msg "Extrayendo archivos del sistema" "Extracting system files")"
		;;
	"extracting_webroot")
		ui_print "- $(_msg "Extrayendo archivos webroot" "Extracting webroot files")"
		;;
	"current_gboard_version")
		ui_print "- $(_msg "Version actual de Gboard" "Current Gboard version"): $VERSION"
		;;
	"checking_latest_version")
		ui_print "- $(_msg "Verificando la ultima version de Gboard Lite..." "Checking for latest Gboard Lite version...")"
		;;
	"downloading_gboard")
		ui_print "- $(_msg "Descargando Gboard Lite para [$ARCH], por favor espera..." "Downloading Gboard Lite for [$ARCH], please wait...")"
		;;
	"download_failed")
		ui_print "! $(_msg "Descarga fallo - verifica tu conexion a internet" "Download failed - check your internet connection")"
		;;
	"download_invalid")
		ui_print "! $(_msg "El archivo descargado es invalido o esta vacio" "Downloaded file is invalid or empty")"
		;;
	"download_success")
		ui_print "- $(_msg "Descarga completada exitosamente" "Download completed successfully")"
		;;
	"download_retry")
		ui_print "- $(_msg "Reintentando descarga ($RETRY_COUNT/$MAX_RETRIES)..." "Retrying download ($RETRY_COUNT/$MAX_RETRIES)...")"
		;;
	"replacing_keyboards")
		ui_print "- $(_msg "Reemplazando teclados del sistema..." "Replacing system keyboards...")"
		;;
	"gboard_not_installed")
		ui_print "- $(_msg "Gboard no esta instalado" "Gboard is not installed")"
		;;
	"found_existing_gboard")
		ui_print "- $(_msg "Encontrada instalacion existente de Gboard" "Found existing Gboard installation")"
		;;
	"unmounting_gboard")
		ui_print "- $(_msg "Desmontando montajes existentes de Gboard" "Unmounting existing Gboard mounts")"
		;;
	"gboard_up_to_date")
		ui_print "- $(_msg "Gboard $VERSION ya esta actualizado!" "Gboard $VERSION is already up to date!")"
		;;
	"installing_gboard_apk")
		ui_print "- $(_msg "Instalando APK de Gboard Lite" "Installing Gboard Lite APK")"
		;;
	"apk_install_failed")
		ui_print "! $(_msg "Fallo la instalacion del APK" "APK installation failed")"
		;;
	"gboard_installed_success")
		ui_print "- $(_msg "Gboard Lite $VERSION instalado exitosamente!" "Gboard Lite $VERSION installed successfully!")"
		;;
	"setting_system_app")
		ui_print "- $(_msg "Configurando Gboard Lite como aplicacion del sistema..." "Setting Gboard Lite as system app...")"
		;;
	"gboard_is_system_app")
		ui_print "- $(_msg "Gboard Lite es ahora una aplicacion del sistema" "Gboard Lite is now a system app")"
		;;
	"optimizing_gboard")
		ui_print "- $(_msg "Optimizando Gboard Lite $VERSION" "Optimizing Gboard Lite $VERSION")"
		;;
	"installation_complete")
		ui_print "- $(_msg "Instalacion completada exitosamente!" "Installation completed successfully!")"
		;;
	"visit_telegram")
		ui_print "- $(_msg "Visita nuestro Telegram: @apmodsx" "Visit our Telegram: @apmodsx")"
		ui_print "- $(_msg "Visita nuestro YouTube: Diman Ap" "Visit our YouTube: Diman Ap")"
		;;
	"failed_create_dirs")
		ui_print "! $(_msg "Error al crear directorios" "Failed to create directories")"
		;;
	"installation_failed")
		abort "$(_msg "Instalacion fallo" "Installation failed")"
		;;
	"failed_download_gboard")
		abort "$(_msg "Error al descargar Gboard Lite" "Failed to download Gboard Lite")"
		;;
	"failed_install_gboard")
		abort "$(_msg "Error al instalar Gboard Lite" "Failed to install Gboard Lite")"
		;;
	esac
}
