#!/system/bin/sh
# Gboard Lite post-fs-data script
# Applies system.prop and mounts resources when running under KernelSU

MODDIR=${0%/*}
PROPFILE="$MODDIR/system.prop"
THEME_SRC="$MODDIR/system/etc/gboard_theme"
THEME_DST="/system/etc/gboard_theme"
APP_SRC_DIR="$MODDIR/system/product/app/gboardlite_apmods"
APP_DST_DIR="/product/app/gboardlite_apmods"

log_msg() {
	echo "[POST-FS-DATA] $1" >>/cache/magisk.log 2>/dev/null
}

detect_root_impl() {
	if [ -n "$KSU" ] || [ -d /data/adb/ksu ] || [ -n "$(getprop ro.kernel.su.version 2>/dev/null)" ]; then
		ROOT_IMPL="ksu"
	elif [ -n "$MAGISK_VER_CODE" ] || command -v magisk >/dev/null 2>&1; then
		ROOT_IMPL="magisk"
	else
		ROOT_IMPL="unknown"
	fi
}

is_mounted() {
	grep -q " $1 " /proc/mounts 2>/dev/null
}

ensure_path() {
	local target="$1"
	local type="$2"

	if [ "$type" = "dir" ]; then
		[ -d "$target" ] && return 0
		mkdir -p "$target" 2>/dev/null
		return $?
	else
		local parent="${target%/*}"
		if [ -n "$parent" ] && [ "$parent" != "$target" ]; then
			ensure_path "$parent" dir || return 1
		fi
		[ -e "$target" ] || touch "$target" 2>/dev/null
		return $?
	fi
}

bind_mount() {
	local src="$1"
	local dst="$2"
	local type

	if [ -d "$src" ]; then
		type="dir"
	elif [ -f "$src" ]; then
		type="file"
	else
		log_msg "Source not found, not mounting: $src"
		return 1
	fi

	if is_mounted "$dst"; then
		log_msg "Destination already mounted: $dst"
		return 0
	fi

	if ! ensure_path "$dst" "$type"; then
		log_msg "Could not prepare destination: $dst"
		return 1
	fi

	if mount -o bind "$src" "$dst" 2>/dev/null; then
		log_msg "Bind mounted: $src -> $dst"
		return 0
	fi

	log_msg "Failed to mount $dst"
	return 1
}

set_theme_permissions() {
	if [ -d "$THEME_DST" ]; then
		chmod 755 "$THEME_DST" 2>/dev/null
		find "$THEME_DST" -type f -exec chmod 644 {} \; 2>/dev/null
		find "$THEME_DST" -type d -exec chmod 755 {} \; 2>/dev/null
		log_msg "Theme permissions applied"
	fi
}

# Apply theme configuration to system.prop
# Called from WebUI CGI scripts
apply_theme() {
	local light="$1"
	local dark="$2"

	# Remove previous configurations
	sed -i '/ro.com.google.ime.theme_file=/d' "$PROPFILE"
	sed -i '/ro.com.google.ime.d_theme_file=/d' "$PROPFILE"

	# Write new ones
	echo "ro.com.google.ime.theme_file=$light" >>"$PROPFILE"
	echo "ro.com.google.ime.d_theme_file=$dark" >>"$PROPFILE"
}

apply_system_props() {
	[ ! -f "$PROPFILE" ] && return

	if [ -d "/dev/.magisk_unblock" ]; then
		log_msg "Magisk in uninstall mode, not applying props"
		return
	fi

	log_msg "Applying system.prop"
	while IFS='=' read -r key value || [ -n "$key" ]; do
		# Clean \r and invisible spaces
		key=$(echo "$key" | tr -d '\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
		value=$(echo "$value" | tr -d '\r' | sed 's/^[ \t]*//;s/[ \t]*$//')

		# Skip empty lines or comments
		[ -z "$key" ] || [ "${key#\#}" != "$key" ] && continue

		# Try with resetprop -n (for ro.*)
		if resetprop -n "$key" "$value" 2>/dev/null; then
			log_msg "Property applied: $key=$value (resetprop -n)"
		elif setprop "$key" "$value" 2>/dev/null; then
			log_msg "Property applied: $key=$value (setprop)"
		else
			log_msg "Error: could not apply $key=$value"
		fi
	done <"$PROPFILE"
}

main() {
	detect_root_impl
	log_msg "Root manager detected: $ROOT_IMPL"

	# 1. Mount resources (KSU only)
	if [ "$ROOT_IMPL" = "ksu" ]; then
		if [ -d "$APP_SRC_DIR" ]; then
			bind_mount "$APP_SRC_DIR" "$APP_DST_DIR"
		else
			log_msg "APK directory not found: $APP_SRC_DIR"
		fi

		if [ -d "$THEME_SRC" ]; then
			if bind_mount "$THEME_SRC" "$THEME_DST"; then
				set_theme_permissions
			fi
		else
			log_msg "Theme directory not found: $THEME_SRC"
		fi
	else
		log_msg "No additional mount actions for $ROOT_IMPL"
	fi

	# 2. Apply system.prop
	apply_system_props

	log_msg "post-fs-data script completed"
}

main "$@"
