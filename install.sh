#!/system/bin/sh
# Gboard Lite Module Installer
# Author: APMods Team
# Description: Installs Gboard Lite as a system app replacement

# Module configuration
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true
MINAPI=27

# Global variables
VERSION=""
BASEPATH=""

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
	local MODNAME=$(grep_prop name $TMPDIR/module.prop)
	local MODVER=$(grep_prop version $TMPDIR/module.prop)
	local DV=$(grep_prop author $TMPDIR/module.prop)
	local AndroidVersion=$(getprop ro.build.version.release)
	local Device=$(getprop ro.product.device)
	local Model=$(getprop ro.product.model)
	local Brand=$(getprop ro.product.brand)

	ui_print ""
	ui_print "<<<< $MODNAME $MODVER >>>>"
	ui_print ""
	ui_print "-------------------------------------"
	ui_print "- Module: $MODNAME"
	ui_print "- Version: $MODVER"
	ui_print "- Author: $DV"
	ui_print "- Android: $AndroidVersion"
	ui_print "- Device: $Brand $Model ($Device)"

	if [ "$BOOTMODE" ] && [ "$KSU" ]; then
		ui_print "- Provider: KernelSU App"
		ui_print "- KernelSU: $KSU_KERNEL_VER_CODE [kernel] + $KSU_VER_CODE [ksud]"

		# Check for conflicting Magisk installation
		if [ "$(which magisk 2>/dev/null)" ]; then
			ui_print "*********************************************************"
			ui_print "! Multiple root implementations are NOT supported!"
			ui_print "! Please uninstall Magisk before installing this module"
			abort "*********************************************************"
		fi

		# Define paths to remove for KernelSU
		REMOVE="
      /system/product/priv-app/LatinIME
      /system/product/app/LatinIME
      /system/product/app/LatinIMEGooglePrebuilt
      /system/product/app/LatinImeGoogle
      /system/system_ext/app/LatinIMEGooglePrebuilt
      /system/app/LatinIMEGooglePrebuilt
      /system/product/app/GBoard
      /system/app/SogouInput
      /system/app/gboardlite_apmods
      /system/app/HoneyBoard
      /system/product/app/EnhancedGboard
      /system/product/app/SogouInput_S_Product
      /system/product/app/MIUISecurityInputMethod
      /system/product/app/OPlusSegurityKeyboard
      /system/product/priv-app/OPlusSegurityKeyboard
    "

	elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
		ui_print "- Provider: Magisk App"
		ui_print "- Magisk: $MAGISK_VER ($MAGISK_VER_CODE)"

		# Define paths to replace for Magisk
		REPLACE="
      /system/product/priv-app/LatinIME
      /system/product/app/LatinIME
      /system/product/app/LatinIMEGooglePrebuilt
      /system/product/app/LatinImeGoogle
      /system/system_ext/app/LatinIMEGooglePrebuilt
      /system/app/LatinIMEGooglePrebuilt
      /system/product/app/GBoard
      /system/app/SogouInput
      /system/app/gboardlite_apmods
      /system/app/HoneyBoard
      /system/product/app/EnhancedGboard
      /system/product/app/SogouInput_S_Product
      /system/product/app/MIUISecurityInputMethod
      /system/product/app/OPlusSegurityKeyboard
      /system/product/priv-app/OPlusSegurityKeyboard
    "
	else
		ui_print "*********************************************************"
		ui_print "! Unsupported recovery environment"
		ui_print "! Please use Magisk or KernelSU"
		abort "*********************************************************"
	fi

	ui_print "-------------------------------------"
}

# Function to download Gboard Lite APK
download_gboard_lite() {
	local VW_APK_URL="https://github.com/artproducer/gboardlite/raw/main/release/${ARCH}/base.apk"
	local APK_PATH="$MODPATH/system/product/app/gboardlite_apmods/base.apk"

	ui_print "- Downloading Gboard Lite for [$ARCH], please wait..."

	if ! $MODPATH/bin/curl -skL --connect-timeout 30 --max-time 300 "$VW_APK_URL" -o "$APK_PATH"; then
		ui_print "! Download failed - check your internet connection"
		return 1
	fi

	if [ ! -f "$APK_PATH" ] || [ ! -s "$APK_PATH" ]; then
		ui_print "! Downloaded file is invalid or empty"
		return 1
	fi

	ui_print "- Download completed successfully"
	return 0
}

# Function to handle existing Gboard installation
handle_existing_gboard() {
	local package_info=$(pm list packages com.google.android.inputmethod.latin 2>/dev/null | grep -v nga)

	if [ -z "$package_info" ]; then
		ui_print "- Gboard is not installed"
		return 0
	fi

	ui_print "- Found existing Gboard installation"

	# Force stop Gboard
	am force-stop com.google.android.inputmethod.latin 2>/dev/null

	# Unmount any existing mounts
	if grep -q com.google.android.inputmethod.latin /proc/self/mountinfo 2>/dev/null; then
		ui_print "- Unmounting existing Gboard mounts"
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
		ui_print "- Gboard $VERSION is already up to date!"
		return 0
	fi

	ui_print "- Installing Gboard Lite APK"

	# Set proper permissions
	set_perm "$APK_PATH" 1000 1000 644 u:object_r:apk_data_file:s0

	# Install APK
	if ! pm install --user 0 -i com.google.android.inputmethod.latin -r -d "$APK_PATH" >/dev/null 2>&1; then
		ui_print "! APK installation failed"
		return 1
	fi

	# Update version info
	get_version
	ui_print "- Gboard Lite $VERSION installed successfully!"

	# Update module.prop with new version
	if [ -n "$VERSION" ] && [ "$VERSION" != "unknown" ]; then
		sed -i "s/^version=.*/version=$VERSION/g" "$MODPATH/module.prop"
	fi

	return 0
}

# Function to optimize Gboard Lite
optimize_gboard() {
	ui_print "- Optimizing Gboard Lite $VERSION"

	# Force stop before optimization
	am force-stop com.google.android.inputmethod.latin 2>/dev/null

	# Compile/optimize the app
	nohup cmd package compile --reset com.google.android.inputmethod.latin >/dev/null 2>&1 &

	return 0
}

# Main installation function
on_install() {
	# Check API level
	if [ -n "$MINAPI" ] && [ "$API" -lt "$MINAPI" ]; then
		abort "- Your system API ($API) is lower than minimum required API ($MINAPI)! Aborting!"
	fi

	# Create necessary directories
	mkdir -p "$MODPATH/bin" "$MODPATH/system/product/app/gboardlite_apmods" || {
		ui_print "! Failed to create directories"
		abort "Installation failed"
	}

	# Extract curl and cmpr binaries
	ui_print "- Extracting required binaries"
	if ! unzip -oj "$ZIPFILE" "bin/$ARCH/curl" -d "$MODPATH/bin" >/dev/null 2>&1; then
		ui_print "! Failed to extract curl binary"
		abort "Installation failed"
	fi

	if ! unzip -oj "$ZIPFILE" "bin/$ARCH/cmpr" -d "$MODPATH/bin" >/dev/null 2>&1; then
		ui_print "! Failed to extract cmpr binary"
		abort "Installation failed"
	fi

	# Verify curl extraction
	if [ ! -f "$MODPATH/bin/curl" ]; then
		ui_print "! curl binary not found after extraction"
		abort "Installation failed"
	fi

	# Set permissions for binaries
	set_perm "$MODPATH/bin/curl" root root 755
	set_perm "$MODPATH/bin/cmpr" root root 755
	export PATH="$MODPATH/bin:$PATH"

	# Extract system files
	ui_print "- Extracting system files"
	unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >/dev/null 2>&1

	# Get current Gboard version
	get_version
	ui_print "- Current Gboard version: $VERSION"

	# Download Gboard Lite
	ui_print "- Checking for latest Gboard Lite version..."
	if ! download_gboard_lite; then
		abort "Failed to download Gboard Lite"
	fi

	# Handle existing Gboard installation
	handle_existing_gboard

	# Install Gboard Lite
	if ! install_gboard_lite; then
		abort "Failed to install Gboard Lite"
	fi

	# Check if Gboard is system app
	local system_package=$(pm list packages -s com.google.android.inputmethod.latin 2>/dev/null | grep -v nga)
	if [ -z "$system_package" ]; then
		ui_print "- Setting Gboard Lite as system app..."
	else
		ui_print "- Gboard Lite is now a system app"
	fi

	# Optimize the installation
	optimize_gboard

	ui_print "- Installation completed successfully!"
}

# Function to set final permissions
set_permissions() {
	set_perm_recursive "$MODPATH" 0 0 0755 0644
	set_perm "$MODPATH/bin"/* 0 0 0755

	ui_print "- Visit our Telegram: @apmods"
	ui_print "- Visit our Spotify: Diman Ap"
	sleep 2

	# Open Telegram links (non-blocking)
	nohup am start -a android.intent.action.VIEW -d "https://t.me/apmods" >/dev/null 2>&1 &
	sleep 5
	nohup am start -a android.intent.action.VIEW -d "https://www.youtube.com/channel/UCBRuuYwPDgH4wPJimY-YBgw" >/dev/null 2>&1 &
}
