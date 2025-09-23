#!/system/bin/sh
# Gboard Lite post-fs-data script
# Aplica system.prop y monta solo los recursos necesarios cuando se ejecuta bajo KernelSU

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
		if [ -d "$target" ]; then
			return 0
		fi
		mkdir -p "$target" 2>/dev/null
		return $?
	else
		local parent="${target%/*}"
		if [ -n "$parent" ] && [ "$parent" != "$target" ]; then
			if ! ensure_path "$parent" dir; then
				return 1
			fi
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
		log_msg "Origen inexistente, sin montar: $src"
		return 1
	fi

	if is_mounted "$dst"; then
		log_msg "Destino ya montado: $dst"
		return 0
	fi

	if ! ensure_path "$dst" "$type"; then
		log_msg "No se pudo preparar el destino: $dst"
		return 1
	fi

	if mount -o bind "$src" "$dst" 2>/dev/null; then
		log_msg "Montado bind: $src -> $dst"
		return 0
	fi

	log_msg "Fallo al montar $dst"
	return 1
}

set_theme_permissions() {
	if [ -d "$THEME_DST" ]; then
		chmod 755 "$THEME_DST" 2>/dev/null
		find "$THEME_DST" -type f -exec chmod 644 {} \; 2>/dev/null
		find "$THEME_DST" -type d -exec chmod 755 {} \; 2>/dev/null
		log_msg "Permisos de temas aplicados"
	fi
}

apply_system_props() {
	if [ ! -f "$PROPFILE" ]; then
		return
	fi

	if [ -d "/dev/.magisk_unblock" ]; then
		log_msg "Magisk en modo desinstalacion, no se aplican props"
		return
	fi

	log_msg "Aplicando system.prop"
	while IFS='=' read -r key value || [ -n "$key" ]; do
		# limpiar \r y espacios invisibles
		key=$(echo "$key" | tr -d '\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
		value=$(echo "$value" | tr -d '\r' | sed 's/^[ \t]*//;s/[ \t]*$//')

		# saltar líneas vacías o comentarios
		if [ -z "$key" ] || [ "${key#\#}" != "$key" ]; then
			continue
		fi

		# intentar con resetprop -n (para ro.*)
		if resetprop -n "$key" "$value" 2>/dev/null; then
			log_msg "Propiedad aplicada: $key=$value (resetprop -n)"
		elif setprop "$key" "$value" 2>/dev/null; then
			log_msg "Propiedad aplicada: $key=$value (setprop)"
		else
			log_msg "⚠️ Error: no se pudo aplicar $key=$value"
		fi
	done <"$PROPFILE"
}

main() {
	detect_root_impl
	log_msg "Root manager detectado: $ROOT_IMPL"

	# 1. Primero montar recursos
	if [ "$ROOT_IMPL" = "ksu" ]; then
		if [ -d "$APP_SRC_DIR" ]; then
			bind_mount "$APP_SRC_DIR" "$APP_DST_DIR"
		else
			log_msg "Directorio APK no encontrado: $APP_SRC_DIR"
		fi

		if [ -d "$THEME_SRC" ]; then
			if bind_mount "$THEME_SRC" "$THEME_DST"; then
				set_theme_permissions
			fi
		else
			log_msg "Directorio de temas no encontrado: $THEME_SRC"
		fi
	else
		log_msg "Sin acciones de montaje adicionales para $ROOT_IMPL"
	fi

	# 2. Luego aplicar system.prop (cuando la ruta ya existe)
	apply_system_props

	log_msg "Script post-fs-data completado"
}

main "$@"
apply_theme() {
	light="$1"
	dark="$2"

	# Elimina configuraciones previas
	sed -i '/ro.com.google.ime.theme_file=/d' "$PROPFILE"
	sed -i '/ro.com.google.ime.d_theme_file=/d' "$PROPFILE"

	# Escribe nuevas
	echo "ro.com.google.ime.theme_file=$light" >>"$PROPFILE"
	echo "ro.com.google.ime.d_theme_file=$dark" >>"$PROPFILE"
}
