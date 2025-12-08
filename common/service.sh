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
			echo "[ OK El modulo esta funcionando ]"
		else
			echo "[ OK Module is working ]"
		fi
		;;
	"manual_install")
		if [ "$LANG_ES" = true ]; then
			echo "[ ! Modulo instalado pero necesitas instalar Gboard Lite manualmente ]"
		else
			echo "[ ! Module installed but you need to install Gboard Lite manually ]"
		fi
		;;
	"error")
		if [ "$LANG_ES" = true ]; then
			echo "[ X Error del modulo - revisar logs ]"
		else
			echo "[ X Module error - check logs ]"
		fi
		;;
	esac
}

# Function to log messages
log_msg() {
	local msg="$1"
	echo "[$MODID] $msg" >>/cache/magisk.log 2>/dev/null
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
			log_msg "Sistema listo despues de $1 reintentos"
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
			log_msg "Verificacion del modulo exitosa"
		else
			log_msg "Module verification successful"
		fi
		;;
	"gboard_not_found")
		if [ "$LANG_ES" = true ]; then
			log_msg "Gboard no encontrado - instalacion manual requerida"
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
			log_msg "Descripcion actualizada: $1"
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
		# Replace entire description= line
		sed -i "s/^description=.*/description=$new_desc/" "$PROPFILE"
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

# Start web server with busybox httpd
start_webui_server() {
	WEBROOT="$MODDIR/webroot"
	PORT=8080

	# Create cgi-bin directory if it doesn't exist
	mkdir -p "$WEBROOT/cgi-bin"

	# Give execute permissions to CGI scripts
	chmod +x "$WEBROOT"/cgi-bin/*.sh 2>/dev/null

	# Kill previous server instances
	pkill -f "busybox httpd -p $PORT" 2>/dev/null

	# Start httpd server in background
	/system/bin/busybox httpd -f -p $PORT -h "$WEBROOT" &

	log_msg "[HTTPD] Web server started at http://127.0.0.1:$PORT"
}

# Scan themes in $MODDIR/system/etc/gboard_theme and generate JSON list with names
scan_themes() {
	THEME_SRC="$MODDIR/system/etc/gboard_theme"
	WEBROOT="$MODDIR/webroot"
	JSON_OUT="$WEBROOT/themes.json"
	TMP_JSON="$WEBROOT/.themes.tmp"

	if command -v ui_print >/dev/null 2>&1; then
		ui_print "- Scanning .zip themes in $THEME_SRC..."
	else
		echo "[scan_themes] Scanning .zip themes in $THEME_SRC..."
	fi

	# Check if folder exists
	if [ ! -d "$THEME_SRC" ]; then
		mkdir -p "$WEBROOT"
		echo "[]" >"$JSON_OUT"
		return 0
	fi

	mkdir -p "$WEBROOT"
	echo "[" >"$TMP_JSON"
	first=true

	for f in "$THEME_SRC"/*.zip; do
		[ -f "$f" ] || continue
		filename=$(basename "$f" | sed 's/"/\\"/g')

		if [ "$first" = true ]; then
			first=false
		else
			echo "," >>"$TMP_JSON"
		fi

		printf '  { "filename": "%s" }' "$filename" >>"$TMP_JSON"
	done

	echo "" >>"$TMP_JSON"
	echo "]" >>"$TMP_JSON"

	mv "$TMP_JSON" "$JSON_OUT"

	if command -v ui_print >/dev/null 2>&1; then
		ui_print "- Theme list saved to $JSON_OUT"
	else
		echo "[scan_themes] Theme list saved to $JSON_OUT"
	fi
}

# Call server after completing verification
main() {
	detect_language
	log_msg_lang "service_started"

	if [ "$LANG_ES" = true ]; then
		BASE_DESC="$DESC_BASE_ES"
	else
		BASE_DESC="$DESC_BASE_EN"
	fi

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

	if [ $retry_count -eq $max_retries ]; then
		log_msg_lang "system_timeout"
		update_description "$BASE_DESC $(get_status_message "error")"
		exit 1
	fi

	if is_gboard_installed; then
		log_msg_lang "verification_success"
		update_description "$BASE_DESC $(get_status_message "working")"
	else
		log_msg_lang "gboard_not_found"
		update_description "$BASE_DESC $(get_status_message "manual_install")"
	fi
	scan_themes
	log_msg_lang "service_completed"

}

# Execute main function
main "$@"
