#!/system/bin/sh
# Gboard Lite Module Installer
# Author: APMods Team
# Description: Installs Gboard Lite as a system app replacement

# Module configuration
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true
MINAPI=27

# Global variables
VERSION=""
BASEPATH=""

# Keyboard paths to replace/remove (shared by KSU and Magisk)
KEYBOARD_PATHS="/system/product/priv-app/LatinIME
/system/product/app/LatinIME
/system/product/app/LatinIMEGooglePrebuilt
/system/product/app/LatinImeGoogle
/system/system_ext/app/LatinIMEGooglePrebuilt
/system/app/LatinIMEGooglePrebuilt
/system/product/app/GBoard
/system/app/SogouInput
/system/app/HoneyBoard
/system/product/app/EnhancedGboard
/system/product/app/SogouInput_S_Product
/system/product/app/MIUISecurityInputMethod
/system/product/app/OPlusSegurityKeyboard
/system/product/priv-app/OPlusSegurityKeyboard"

# Source localization (provides detect_language, _msg, ui_print_lang)
. $TMPDIR/lang.sh

# Function to get Gboard version
get_version() {
	VERSION=$(dumpsys package com.google.android.inputmethod.latin 2>/dev/null | grep -m1 versionName)
	if [ -n "$VERSION" ]; then
		VERSION="${VERSION#*=}"
		VERSION=$(echo "$VERSION" | cut -d. -f1-3)
	else
		VERSION="unknown"
	fi
}

# Function to get Gboard base path
get_basepath() {
	local path_info=$(pm path com.google.android.inputmethod.latin 2>/dev/null | grep base)
	if [ -n "$path_info" ]; then
		BASEPATH=${path_info#*:}
		BASEPATH=${BASEPATH%/*}
	else
		BASEPATH=""
	fi
}

# Function to print module information
print_modname() {
	detect_language

	local MODNAME=$(grep_prop name $TMPDIR/module.prop)
	local MODVER=$(grep_prop version $TMPDIR/module.prop)
	local DV=$(grep_prop author $TMPDIR/module.prop)
	local AndroidVersion=$(getprop ro.build.version.release)
	local Device=$(getprop ro.product.device)
	local Model=$(getprop ro.product.model)
	local Brand=$(getprop ro.product.brand)

	# Export as globals for ui_print_lang
	export MODNAME MODVER DV AndroidVersion Device Model Brand

	ui_print ""
	ui_print_lang "header"
	ui_print ""
	ui_print "-------------------------------------"
	ui_print_lang "module_info"

	if [ "$BOOTMODE" ] && [ "$KSU" ]; then
		ui_print_lang "provider_ksu"

		# Check for conflicting Magisk installation
		if [ "$(which magisk 2>/dev/null)" ]; then
			ui_print_lang "multiple_root_error"
			abort "*********************************************************"
		fi

		local USE_KSU=true

	elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
		ui_print_lang "provider_magisk"

		local USE_KSU=false
	else
		ui_print_lang "unsupported_recovery"
		abort "*********************************************************"
	fi

	# Check each keyboard path and only replace if it exists
	ui_print_lang "replacing_keyboards"

	local FOUND_PATHS=""
	local FOUND_COUNT=0
	for kpath in $KEYBOARD_PATHS; do
		if [ -d "$kpath" ]; then
			FOUND_PATHS="${FOUND_PATHS}
${kpath}"
			FOUND_COUNT=$((FOUND_COUNT + 1))
			ui_print "  ✓ $(_msg "Eliminado" "Removed"): ${kpath##*/}"
		fi
	done

	# Assign only existing paths to the correct variable
	if [ "$USE_KSU" = true ]; then
		REMOVE="$FOUND_PATHS"
	else
		REPLACE="$FOUND_PATHS"
	fi
	sleep 1.0
}

# Function to download Gboard Lite APK (with retry mechanism)
download_gboard_lite() {
	local VW_APK_URL="https://github.com/artproducer/gboardlite/raw/main/release/${ARCH}/base.apk"
	local APK_PATH="$MODPATH/system/product/app/gboardlite_apmods/base.apk"
	local MAX_RETRIES=3
	local RETRY_COUNT=0

	ui_print_lang "downloading_gboard"

	while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
		RETRY_COUNT=$((RETRY_COUNT + 1))

		if $MODPATH/bin/curl -skL --connect-timeout 30 --max-time 300 "$VW_APK_URL" -o "$APK_PATH" 2>/dev/null; then
			# Verify file exists and is larger than 1MB (valid APK)
			local file_size=$(wc -c <"$APK_PATH" 2>/dev/null || echo 0)
			if [ -f "$APK_PATH" ] && [ "$file_size" -gt 1048576 ]; then
				ui_print_lang "download_success"
				return 0
			fi
			ui_print_lang "download_invalid"
		else
			ui_print_lang "download_failed"
		fi

		# Retry with delay (except on last attempt)
		if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
			export RETRY_COUNT MAX_RETRIES
			ui_print_lang "download_retry"
			sleep 3
		fi
	done

	return 1
}

# Function to handle existing Gboard installation
handle_existing_gboard() {
	local package_info=$(pm list packages com.google.android.inputmethod.latin 2>/dev/null | grep -v nga)

	if [ -z "$package_info" ]; then
		ui_print_lang "gboard_not_installed"
		return 0
	fi

	ui_print_lang "found_existing_gboard"

	# Force stop Gboard
	am force-stop com.google.android.inputmethod.latin 2>/dev/null

	# Unmount any existing mounts
	if grep -q com.google.android.inputmethod.latin /proc/self/mountinfo 2>/dev/null; then
		ui_print_lang "unmounting_gboard"
		grep com.google.android.inputmethod.latin /proc/self/mountinfo | while IFS= read -r line; do
			local mountpoint=$(echo "$line" | awk '{print $5}')
			if [ -n "$mountpoint" ]; then
				umount -l "${mountpoint%%\\*}" 2>/dev/null || true
			fi
		done
	fi

	return 0
}

# Function to install Gboard Lite APK
install_gboard_lite() {
	local APK_PATH="$MODPATH/system/product/app/gboardlite_apmods/base.apk"

	get_basepath

	# Check if current version matches
	if [ -n "$BASEPATH" ] && $MODPATH/bin/cmpr "$BASEPATH" "$APK_PATH" 2>/dev/null; then
		ui_print_lang "gboard_up_to_date"
		return 0
	fi

	ui_print_lang "installing_gboard_apk"

	# Set proper permissions
	set_perm "$APK_PATH" 1000 1000 644 u:object_r:apk_data_file:s0

	# Install APK
	if ! pm install --user 0 -i com.google.android.inputmethod.latin -r -d "$APK_PATH" >/dev/null 2>&1; then
		ui_print_lang "apk_install_failed"
		return 1
	fi

	# Update version info
	get_version
	ui_print_lang "gboard_installed_success"

	# Update module.prop with new version
	if [ -n "$VERSION" ] && [ "$VERSION" != "unknown" ]; then
		sed -i "s/^version=.*/version=$VERSION/g" "$MODPATH/module.prop"
	fi

	return 0
}

# Function to optimize Gboard Lite
optimize_gboard() {
	ui_print_lang "optimizing_gboard"

	# Force stop before optimization
	am force-stop com.google.android.inputmethod.latin 2>/dev/null

	# Compile/optimize the app
	nohup cmd package compile --reset com.google.android.inputmethod.latin >/dev/null 2>&1 &

	return 0
}

# Main installation function
on_install() {
	detect_language

	# Set description based on language
	if [ "$LANG_ES" = true ]; then
		sed -i 's|^description=.*|description=Instalador online de Gboard Lite optimizado para dispositivos ARMv7 y ARM64 (Android 8.1+). Ideal para ROMs personalizadas.|' "$MODPATH/module.prop"
	else
		sed -i 's|^description=.*|description=Online installer for Gboard Lite, optimized for ARMv7 and ARM64 devices (Android 8.1+). Perfect for custom ROMs.|' "$MODPATH/module.prop"
	fi

	# Check API level
	if [ -n "$MINAPI" ] && [ "$API" -lt "$MINAPI" ]; then
		ui_print_lang "api_error"
	fi

	# Create necessary directories
	ui_print_lang "extracting_binaries"
	if ! mkdir -p "$MODPATH/bin" "$MODPATH/system/product/app/gboardlite_apmods"; then
		ui_print_lang "failed_create_dirs"
		ui_print_lang "installation_failed"
	fi

	# Extract curl and cmpr binaries
	if ! unzip -oj "$ZIPFILE" "bin/$ARCH/curl" -d "$MODPATH/bin" >/dev/null 2>&1; then
		ui_print_lang "failed_extract_curl"
		ui_print_lang "installation_failed"
	fi

	if ! unzip -oj "$ZIPFILE" "bin/$ARCH/cmpr" -d "$MODPATH/bin" >/dev/null 2>&1; then
		ui_print_lang "failed_extract_cmpr"
		ui_print_lang "installation_failed"
	fi

	# Verify curl extraction
	if [ ! -f "$MODPATH/bin/curl" ]; then
		ui_print_lang "curl_not_found"
		ui_print_lang "installation_failed"
	fi

	# Set permissions for binaries
	set_perm "$MODPATH/bin/curl" root root 755
	set_perm "$MODPATH/bin/cmpr" root root 755
	export PATH="$MODPATH/bin:$PATH"

	# Extract system files
	ui_print_lang "extracting_system_files"
	unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >/dev/null 2>&1

	# Extract webroot files (for KernelSU WebUI)
	ui_print_lang "extracting_webroot"
	unzip -o "$ZIPFILE" 'webroot/*' -d "$MODPATH" >/dev/null 2>&1

	# Generate themes.json and copy preview images
	local THEME_DIR="$MODPATH/system/etc/gboard_theme"
	local WEBROOT_DIR="$MODPATH/webroot"
	if [ -d "$THEME_DIR" ]; then
		local THEMES_JSON="$WEBROOT_DIR/themes.json"
		local PREVIEW_DIR="$WEBROOT_DIR/previews"
		mkdir -p "$PREVIEW_DIR"

		# Copy preview images (files without .zip extension)
		for img in "$THEME_DIR"/*; do
			[ -f "$img" ] || continue
			case "$img" in *.zip) continue ;; esac
			cp "$img" "$PREVIEW_DIR/" 2>/dev/null
		done

		echo "[" >"$THEMES_JSON"
		local FIRST=true
		for f in "$THEME_DIR"/*.zip; do
			[ -f "$f" ] || continue
			local fname=$(basename "$f")
			local preview_name="${fname%.zip}"
			local has_preview=""
			if [ -f "$PREVIEW_DIR/$preview_name" ]; then
				has_preview="previews/$preview_name"
			fi
			if [ "$FIRST" = true ]; then
				FIRST=false
			else
				echo "," >>"$THEMES_JSON"
			fi
			printf '{"filename":"%s","preview":"%s"}' "$fname" "$has_preview" >>"$THEMES_JSON"
		done
		echo "" >>"$THEMES_JSON"
		echo "]" >>"$THEMES_JSON"
	fi

	# Generate config.json from system.prop defaults
	local CONFIG_JSON="$WEBROOT_DIR/config.json"
	local LIGHT_THEME=""
	local DARK_THEME=""
	# Search system.prop in multiple locations (PROPFILE=true copies it after on_install)
	local SYSPROP=""
	for sp in "$MODPATH/system.prop" "$MODPATH/common/system.prop" "$TMPDIR/system.prop"; do
		if [ -f "$sp" ]; then
			SYSPROP="$sp"
			break
		fi
	done
	if [ -n "$SYSPROP" ]; then
		LIGHT_THEME=$(grep '^ro.com.google.ime.theme_file=' "$SYSPROP" | cut -d= -f2)
		DARK_THEME=$(grep '^ro.com.google.ime.d_theme_file=' "$SYSPROP" | cut -d= -f2)
	fi
	printf '{"lightTheme":"%s","darkTheme":"%s"}' "$LIGHT_THEME" "$DARK_THEME" >"$CONFIG_JSON"

	# Get current Gboard version
	get_version
	ui_print_lang "current_gboard_version"

	# Download Gboard Lite (with retry)
	ui_print_lang "checking_latest_version"
	if ! download_gboard_lite; then
		ui_print_lang "failed_download_gboard"
	fi

	# Handle existing Gboard installation
	handle_existing_gboard

	# Install Gboard Lite
	if ! install_gboard_lite; then
		ui_print_lang "failed_install_gboard"
	fi

	# Check if Gboard is system app
	local system_package=$(pm list packages -s com.google.android.inputmethod.latin 2>/dev/null | grep -v nga)
	if [ -z "$system_package" ]; then
		ui_print_lang "setting_system_app"
	else
		ui_print_lang "gboard_is_system_app"
	fi

	# Optimize the installation
	optimize_gboard

	ui_print_lang "installation_complete"
}

# Function to set final permissions
set_permissions() {
	set_perm_recursive "$MODPATH" 0 0 0755 0644
	set_perm "$MODPATH/bin"/* 0 0 0755

	ui_print_lang "visit_telegram"
	sleep 2

	# Open Telegram and YouTube links (non-blocking)
	nohup am start -a android.intent.action.VIEW -d "https://t.me/apmodsx" >/dev/null 2>&1 &
	sleep 3.0
	nohup am start -a android.intent.action.VIEW -d "https://donate.dsorak.com/" >/dev/null 2>&1 &
}
