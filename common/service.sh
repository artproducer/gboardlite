#!/system/bin/sh
# Gboard Lite Module Service Script
# Runs at boot to verify module status and start services

MODDIR=${0%/*}
MODID="gboardlite_apmods"
GBOARD_PACKAGE="com.google.android.inputmethod.latin"
PROPFILE="$MODDIR/module.prop"

# Source shared language detection
. "$MODDIR/lang.sh"

# Base descriptions
DESC_BASE_ES="Instalador online de Gboard Lite optimizado para dispositivos ARMv7 y ARM64 (Android 8.1+). Ideal para ROMs personalizadas."
DESC_BASE_EN="Online installer of Gboard Lite optimized for ARMv7 and ARM64 devices (Android 8.1+). Ideal for custom ROMs."

# Log to magisk log
log_msg() {
	echo "[$MODID] $1" >>/cache/magisk.log 2>/dev/null
}

# Get localized status message (shown in module manager UI)
get_status_message() {
	case "$1" in
	"working")
		_msg "[ OK El modulo esta funcionando ]" "[ OK Module is working ]"
		;;
	"manual_install")
		_msg "[ ! Modulo instalado pero necesitas instalar Gboard Lite manualmente ]" \
			"[ ! Module installed but you need to install Gboard Lite manually ]"
		;;
	"error")
		_msg "[ X Error del modulo - revisar logs ]" "[ X Module error - check logs ]"
		;;
	esac
}

# Update module description
update_description() {
	if [ -f "$PROPFILE" ]; then
		sed -i "s/^description=.*/description=$1/" "$PROPFILE"
		log_msg "Updated description: $1"
	else
		log_msg "Error: module.prop not found at $PROPFILE"
	fi
}

# Check if Android system is ready
is_system_ready() {
	if [ ! -d "/data/misc/shared_relro" ]; then
		log_msg "System not ready - shared_relro directory missing"
		return 1
	fi

	# Use timeout if available, fallback to direct check
	if command -v timeout >/dev/null 2>&1; then
		timeout 10 pm list packages >/dev/null 2>&1 || {
			log_msg "Package manager not responsive"
			return 1
		}
	else
		pm list packages >/dev/null 2>&1 || {
			log_msg "Package manager not responsive"
			return 1
		}
	fi

	return 0
}

# Check if Gboard package is installed
is_gboard_installed() {
	local package_check=$(pm list packages "$GBOARD_PACKAGE" 2>/dev/null)
	if [ -n "$package_check" ]; then
		log_msg "Gboard package found: $package_check"
		return 0
	else
		log_msg "Gboard package not found"
		return 1
	fi
}

# Scan themes and generate JSON list
scan_themes() {
	local THEME_SRC="$MODDIR/system/etc/gboard_theme"
	local WEBROOT="$MODDIR/webroot"
	local JSON_OUT="$WEBROOT/themes.json"
	local TMP_JSON="$WEBROOT/.themes.tmp"

	log_msg "Scanning .zip themes in $THEME_SRC..."

	if [ ! -d "$THEME_SRC" ]; then
		mkdir -p "$WEBROOT"
		echo "[]" >"$JSON_OUT"
		return 0
	fi

	mkdir -p "$WEBROOT"
	echo "[" >"$TMP_JSON"
	local first=true

	for f in "$THEME_SRC"/*.zip; do
		[ -f "$f" ] || continue
		local filename=$(basename "$f" | sed 's/"/\\"/g')

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
	log_msg "Theme list saved to $JSON_OUT"
}

# Start web server for KernelSU WebUI
start_webui_server() {
	local WEBROOT="$MODDIR/webroot"
	local PORT=8080

	# Only start if busybox httpd is available
	if ! command -v busybox >/dev/null 2>&1; then
		log_msg "busybox not available, skipping web server"
		return 1
	fi

	mkdir -p "$WEBROOT/cgi-bin"
	chmod +x "$WEBROOT"/cgi-bin/*.sh 2>/dev/null

	# Kill previous instances
	pkill -f "busybox httpd -p $PORT" 2>/dev/null

	# Start httpd server in background
	/system/bin/busybox httpd -f -p $PORT -h "$WEBROOT" &
	log_msg "Web server started at http://127.0.0.1:$PORT"
}

# Main function
main() {
	detect_language
	log_msg "Service script started"

	local BASE_DESC
	[ "$LANG_ES" = true ] && BASE_DESC="$DESC_BASE_ES" || BASE_DESC="$DESC_BASE_EN"

	# Wait for system readiness
	local retry_count=0
	local max_retries=30

	while [ $retry_count -lt $max_retries ]; do
		if is_system_ready; then
			log_msg "System ready after $retry_count retries"
			break
		fi
		retry_count=$((retry_count + 1))
		log_msg "Waiting for system... retry $retry_count/$max_retries"
		sleep 2
	done

	if [ $retry_count -eq $max_retries ]; then
		log_msg "System readiness timeout"
		update_description "$BASE_DESC $(get_status_message "error")"
		exit 1
	fi

	# Verify Gboard installation
	if is_gboard_installed; then
		log_msg "Module verification successful"
		update_description "$BASE_DESC $(get_status_message "working")"
	else
		log_msg "Gboard not found - manual installation required"
		update_description "$BASE_DESC $(get_status_message "manual_install")"
	fi

	# Scan available themes
	scan_themes

	# Start WebUI server
	start_webui_server

	log_msg "Service script completed"
}

main "$@"
