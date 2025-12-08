#!/system/bin/sh
# Function to print localized messages
ui_print_lang() {
	local key="$1"
	case "$key" in
	"header")
		if [ "$LANG_ES" = true ]; then
			ui_print "<<<< $MODNAME $MODVER >>>>"
		else
			ui_print "<<<< $MODNAME $MODVER >>>>"
		fi
		;;
	"module_info")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Modulo: $MODNAME"
			ui_print "- Version: $MODVER"
			ui_print "- Autor: $DV"
			ui_print "- Android: $AndroidVersion"
			ui_print "- Dispositivo: $Brand $Model ($Device)"
		else
			ui_print "- Module: $MODNAME"
			ui_print "- Version: $MODVER"
			ui_print "- Author: $DV"
			ui_print "- Android: $AndroidVersion"
			ui_print "- Device: $Brand $Model ($Device)"
		fi
		;;
	"provider_ksu")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Proveedor: KernelSU App"
		else
			ui_print "- Provider: KernelSU App"
		fi
		ui_print "- KernelSU: $KSU_KERNEL_VER_CODE [kernel] + $KSU_VER_CODE [ksud]"
		;;
	"provider_magisk")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Proveedor: Magisk App"
		else
			ui_print "- Provider: Magisk App"
		fi
		ui_print "- Magisk: $MAGISK_VER ($MAGISK_VER_CODE)"
		;;
	"multiple_root_error")
		ui_print "*********************************************************"
		if [ "$LANG_ES" = true ]; then
			ui_print "! Las implementaciones de multiples root NO son compatibles!"
			ui_print "! Por favor desinstala Magisk antes de instalar este modulo"
		else
			ui_print "! Multiple root implementations are NOT supported!"
			ui_print "! Please uninstall Magisk before installing this module"
		fi
		;;
	"unsupported_recovery")
		ui_print "*********************************************************"
		if [ "$LANG_ES" = true ]; then
			ui_print "! Entorno de recovery no compatible"
			ui_print "! Por favor usa Magisk o KernelSU"
		else
			ui_print "! Unsupported recovery environment"
			ui_print "! Please use Magisk or KernelSU"
		fi
		;;
	"api_error")
		if [ "$LANG_ES" = true ]; then
			abort "- Tu API del sistema ($API) es menor que el API minimo requerido ($MINAPI)! Abortando!"
		else
			abort "- Your system API ($API) is lower than minimum required API ($MINAPI)! Aborting!"
		fi
		;;
	"extracting_binaries")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Extrayendo binarios requeridos"
		else
			ui_print "- Extracting required binaries"
		fi
		;;
	"failed_extract_curl")
		if [ "$LANG_ES" = true ]; then
			ui_print "! Error al extraer el binario curl"
		else
			ui_print "! Failed to extract curl binary"
		fi
		;;
	"failed_extract_cmpr")
		if [ "$LANG_ES" = true ]; then
			ui_print "! Error al extraer el binario cmpr"
		else
			ui_print "! Failed to extract cmpr binary"
		fi
		;;
	"curl_not_found")
		if [ "$LANG_ES" = true ]; then
			ui_print "! Binario curl no encontrado despues de la extraccion"
		else
			ui_print "! curl binary not found after extraction"
		fi
		;;
	"extracting_system_files")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Extrayendo archivos del sistema"
		else
			ui_print "- Extracting system files"
		fi
		;;
	"extracting_webroot")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Extrayendo archivos webroot"
		else
			ui_print "- Extracting webroot files"
		fi
		;;
	"current_gboard_version")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Version actual de Gboard: $VERSION"
		else
			ui_print "- Current Gboard version: $VERSION"
		fi
		;;
	"checking_latest_version")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Verificando la ultima version de Gboard Lite..."
		else
			ui_print "- Checking for latest Gboard Lite version..."
		fi
		;;
	"downloading_gboard")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Descargando Gboard Lite para [$ARCH], por favor espera..."
		else
			ui_print "- Downloading Gboard Lite for [$ARCH], please wait..."
		fi
		;;
	"download_failed")
		if [ "$LANG_ES" = true ]; then
			ui_print "! Descarga fallo - verifica tu conexion a internet"
		else
			ui_print "! Download failed - check your internet connection"
		fi
		;;
	"download_invalid")
		if [ "$LANG_ES" = true ]; then
			ui_print "! El archivo descargado es invalido o esta vacio"
		else
			ui_print "! Downloaded file is invalid or empty"
		fi
		;;
	"download_success")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Descarga completada exitosamente"
		else
			ui_print "- Download completed successfully"
		fi
		;;
	"gboard_not_installed")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Gboard no esta instalado"
		else
			ui_print "- Gboard is not installed"
		fi
		;;
	"found_existing_gboard")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Encontrada instalacion existente de Gboard"
		else
			ui_print "- Found existing Gboard installation"
		fi
		;;
	"unmounting_gboard")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Desmontando montajes existentes de Gboard"
		else
			ui_print "- Unmounting existing Gboard mounts"
		fi
		;;
	"gboard_up_to_date")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Gboard $VERSION ya esta actualizado!"
		else
			ui_print "- Gboard $VERSION is already up to date!"
		fi
		;;
	"installing_gboard_apk")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Instalando APK de Gboard Lite"
		else
			ui_print "- Installing Gboard Lite APK"
		fi
		;;
	"apk_install_failed")
		if [ "$LANG_ES" = true ]; then
			ui_print "! Fallo la instalacion del APK"
		else
			ui_print "! APK installation failed"
		fi
		;;
	"gboard_installed_success")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Gboard Lite $VERSION instalado exitosamente!"
		else
			ui_print "- Gboard Lite $VERSION installed successfully!"
		fi
		;;
	"setting_system_app")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Configurando Gboard Lite como aplicacion del sistema..."
		else
			ui_print "- Setting Gboard Lite as system app..."
		fi
		;;
	"gboard_is_system_app")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Gboard Lite es ahora una aplicacion del sistema"
		else
			ui_print "- Gboard Lite is now a system app"
		fi
		;;
	"optimizing_gboard")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Optimizando Gboard Lite $VERSION"
		else
			ui_print "- Optimizing Gboard Lite $VERSION"
		fi
		;;
	"installation_complete")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Instalacion completada exitosamente!"
		else
			ui_print "- Installation completed successfully!"
		fi
		;;
	"visit_telegram")
		if [ "$LANG_ES" = true ]; then
			ui_print "- Visita nuestro Telegram: @apmods"
			ui_print "- Visita nuestro YouTube: Diman Ap"
		else
			ui_print "- Visit our Telegram: @apmods"
			ui_print "- Visit our YouTube: Diman Ap"
		fi
		;;
	"failed_create_dirs")
		if [ "$LANG_ES" = true ]; then
			ui_print "! Error al crear directorios"
		else
			ui_print "! Failed to create directories"
		fi
		;;
	"installation_failed")
		if [ "$LANG_ES" = true ]; then
			abort "Instalacion fallo"
		else
			abort "Installation failed"
		fi
		;;
	"failed_download_gboard")
		if [ "$LANG_ES" = true ]; then
			abort "Error al descargar Gboard Lite"
		else
			abort "Failed to download Gboard Lite"
		fi
		;;
	"failed_install_gboard")
		if [ "$LANG_ES" = true ]; then
			abort "Error al instalar Gboard Lite"
		else
			abort "Failed to install Gboard Lite"
		fi
		;;
	esac
}
