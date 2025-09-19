#!/system/bin/sh
# Gboard Lite Module Service Script
# This script runs at boot to verify module status

# Module configuration
MODDIR=${0%/*}
MODID="gboardlite_apmods"
GBOARD_PACKAGE="com.google.android.inputmethod.latin"
PROPFILE="$MODDIR/module.prop"
LANG_ES=false
# Base descriptions in both languages
DESC_BASE_ES="Instalador online de Gboard Lite optimizado para dispositivos ARMv7 y ARM64 (Android 8.1+). Ideal para ROMs personalizadas."
DESC_BASE_EN="Online installer of Gboard Lite optimized for ARMv7 and ARM64 devices (Android 8.1+). Ideal for custom ROMs."
# Function to detect system language
detect_language() {
	local system_lang=$(getprop persist.sys.locale)
	if [ -z "$system_lang" ]; then
		system_lang=$(getprop ro.product.locale.language)
	fi

	case "$system_lang" in
	*es* | *ES* | es_* | ES_* | ES-* | es-*)
		LANG_ES=true
		;;
	*)
		LANG_ES=false
		;;
	esac
}

# Function to get localized status messages
get_status_message() {
	local key="$1"
	case "$key" in
	"working")
		if [ "$LANG_ES" = true ]; then
			echo "[ ✅ El módulo está funcionando ]"
		else
			echo "[ ✅ Module is working ]"
		fi
		;;
	"manual_install")
		if [ "$LANG_ES" = true ]; then
			echo "[ 🙁 Módulo instalado pero necesitas instalar Gboard Lite manualmente ]"
		else
			echo "[ 🙁 Module installed but you need to install Gboard Lite manually ]"
		fi
		;;
	"error")
		if [ "$LANG_ES" = true ]; then
			echo "[ ❌ Error del módulo - revisar logs ]"
		else
			echo "[ ❌ Module error - check logs ]"
		fi
		;;
	esac
}

# Function to log messages
log_msg() {
	local msg="$1"
	if [ "$LANG_ES" = true ]; then
		echo "[$MODID] $msg" >>/cache/magisk.log 2>/dev/null
	else
		echo "[$MODID] $msg" >>/cache/magisk.log 2>/dev/null
	fi
}

# Function to log localized messages
log_msg_lang() {
	local key="$1"
	case "$key" in
	"service_started")
		if [ "$LANG_ES" = true ]; then
			log_msg "Script de servicio iniciado"
		else
			log_msg "Service script started"
		fi
		;;
	"system_ready")
		if [ "$LANG_ES" = true ]; then
			log_msg "Sistema listo después de $1 reintentos"
		else
			log_msg "System ready after $1 retries"
		fi
		;;
	"waiting_system")
		if [ "$LANG_ES" = true ]; then
			log_msg "Esperando sistema... reintento $1/$2"
		else
			log_msg "Waiting for system... retry $1/$2"
		fi
		;;
	"system_timeout")
		if [ "$LANG_ES" = true ]; then
			log_msg "Tiempo de espera del sistema agotado - actualizando con estado de error"
		else
			log_msg "System readiness timeout - updating with error status"
		fi
		;;
	"verification_success")
		if [ "$LANG_ES" = true ]; then
			log_msg "Verificación del módulo exitosa"
		else
			log_msg "Module verification successful"
		fi
		;;
	"gboard_not_found")
		if [ "$LANG_ES" = true ]; then
			log_msg "Gboard no encontrado - instalación manual requerida"
		else
			log_msg "Gboard not found - manual installation required"
		fi
		;;
	"service_completed")
		if [ "$LANG_ES" = true ]; then
			log_msg "Script de servicio completado"
		else
			log_msg "Service script completed"
		fi
		;;
	"system_not_ready")
		if [ "$LANG_ES" = true ]; then
			log_msg "Sistema no listo - directorio shared_relro faltante"
		else
			log_msg "System not ready - shared_relro directory missing"
		fi
		;;
	"pm_not_responsive")
		if [ "$LANG_ES" = true ]; then
			log_msg "Gestor de paquetes no responde"
		else
			log_msg "Package manager not responsive"
		fi
		;;
	"gboard_found")
		if [ "$LANG_ES" = true ]; then
			log_msg "Paquete Gboard encontrado: $1"
		else
			log_msg "Gboard package found: $1"
		fi
		;;
	"gboard_not_found_check")
		if [ "$LANG_ES" = true ]; then
			log_msg "Paquete Gboard no encontrado"
		else
			log_msg "Gboard package not found"
		fi
		;;
	"description_updated")
		if [ "$LANG_ES" = true ]; then
			log_msg "Descripción actualizada: $1"
		else
			log_msg "Updated description: $1"
		fi
		;;
	"prop_not_found")
		if [ "$LANG_ES" = true ]; then
			log_msg "Error: module.prop no encontrado en $PROPFILE"
		else
			log_msg "Error: module.prop not found at $PROPFILE"
		fi
		;;
	esac
}

# Function to update module description
update_description() {
	local new_desc="$1"
	if [ -f "$PROPFILE" ]; then
		sed -Ei "s/^description=(\[.*\][[:space:]]*)?/description=$new_desc /g" "$PROPFILE"
		log_msg_lang "description_updated" "$new_desc"
	else
		log_msg_lang "prop_not_found"
	fi
}

# Function to check if Android system is ready
is_system_ready() {
	# Check if package manager is available and system is initialized
	if [ ! -d "/data/misc/shared_relro" ]; then
		log_msg_lang "system_not_ready"
		return 1
	fi

	# Check if package manager is responsive
	if ! timeout 10 pm list packages >/dev/null 2>&1; then
		log_msg_lang "pm_not_responsive"
		return 1
	fi

	return 0
}

# Function to check if Gboard package is installed
is_gboard_installed() {
	local package_check=$(pm list packages "$GBOARD_PACKAGE" 2>/dev/null)
	if [ -n "$package_check" ]; then
		log_msg_lang "gboard_found" "$package_check"
		return 0
	else
		log_msg_lang "gboard_not_found_check"
		return 1
	fi
}

# Main execution
main() {
	# Detect system language first
	detect_language

	log_msg_lang "service_started"

	# >>> NUEVO: Establecer descripción base según idioma
	if [ "$LANG_ES" = true ]; then
		BASE_DESC="$DESC_BASE_ES"
	else
		BASE_DESC="$DESC_BASE_EN"
	fi

	# Wait for system to be ready (with timeout)
	local retry_count=0
	local max_retries=30

	while [ $retry_count -lt $max_retries ]; do
		if is_system_ready; then
			log_msg_lang "system_ready" "$retry_count"
			break
		fi

		retry_count=$((retry_count + 1))
		log_msg_lang "waiting_system" "$retry_count" "$max_retries"
		sleep 2
	done

	# Check if we timed out
	if [ $retry_count -eq $max_retries ]; then
		log_msg_lang "system_timeout"
		update_description "$BASE_DESC $(get_status_message "error")"
		exit 1
	fi

	# Check Gboard installation status
	if is_gboard_installed; then
		log_msg_lang "verification_success"
		update_description "$BASE_DESC $(get_status_message "working")"
	else
		log_msg_lang "gboard_not_found"
		update_description "$BASE_DESC $(get_status_message "manual_install")"
	fi

	log_msg_lang "service_completed"
}

# Execute main function
main "$@"
