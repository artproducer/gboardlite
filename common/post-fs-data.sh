#!/system/bin/sh
# Aplicar system.prop manualmente en KernelSU

MODDIR=${0%/*}
PROPFILE="$MODDIR/system.prop"

# Detectar si Magisk ya aplica system.prop
# Magisk crea /dev/.magisk_unblock para system.prop, así que si existe, no hacemos nada.
if [ -f "$PROPFILE" ] && [ ! -d "/dev/.magisk_unblock" ]; then
    while IFS='=' read -r key value; do
        # ignorar líneas vacías y comentarios
        if [ -n "$key" ] && [ "${key#\#}" = "$key" ]; then
            resetprop "$key" "$value" 2>/dev/null || setprop "$key" "$value"
        fi
    done < "$PROPFILE"
fi
