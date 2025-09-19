#!/system/bin/sh
# Gboard Lite Module Uninstaller
# Restores system to original state before module installation

# Module configuration
MODDIR=${0%/*}
MODID="gboardlite_apmods"
INFO="/data/adb/modules/.gboardlite_apmods-files"
GBOARD_PACKAGE="com.google.android.inputmethod.latin"
LOG_FILE="/cache/gboardlite_uninstall.log"
LANG_ES=false

# Counters for statistics
FILES_RESTORED=0
FILES_REMOVED=0
DIRS_CLEANED=0
ERRORS=0

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

# Function to log localized messages with timestamp
log_msg_lang() {
	local key="$1"
	local param1="$2"
	local param2="$3"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local message=""

	case "$key" in
	"uninstall_started")
		if [ "$LANG_ES" = true ]; then
			message="Iniciando desinstalación del módulo Gboard Lite"
		else
			message="Starting Gboard Lite module uninstall"
		fi
		;;
	"module_dir")
		if [ "$LANG_ES" = true ]; then
			message="Directorio del módulo: $param1"
		else
			message="Module directory: $param1"
		fi
		;;
	"info_file_location")
		if [ "$LANG_ES" = true ]; then
			message="Archivo de información: $param1"
		else
			message="Info file: $param1"
		fi
		;;
	"force_stop_gboard")
		if [ "$LANG_ES" = true ]; then
			message="Forzando parada de Gboard"
		else
			message="Force stopping Gboard"
		fi
		;;
	"gboard_stopped")
		if [ "$LANG_ES" = true ]; then
			message="Gboard detenido exitosamente"
		else
			message="Gboard stopped successfully"
		fi
		;;
	"gboard_stop_warning")
		if [ "$LANG_ES" = true ]; then
			message="Advertencia: No se pudo detener Gboard (puede que no esté ejecutándose)"
		else
			message "Warning: Could not stop Gboard (may not be running)"
		fi
		;;
	"no_info_file")
		if [ "$LANG_ES" = true ]; then
			message="No se encontró archivo de información en $param1"
		else
			message="No info file found at $param1"
		fi
		;;
	"partial_install_warning")
		if [ "$LANG_ES" = true ]; then
			message="El módulo puede haber sido instalado parcialmente o ya fue limpiado"
		else
			message="Module may have been partially installed or already cleaned"
		fi
		;;
	"processing_restoration")
		if [ "$LANG_ES" = true ]; then
			message="Procesando lista de restauración de archivos..."
		else
			message="Processing file restoration list..."
		fi
		;;
	"processing_line")
		if [ "$LANG_ES" = true ]; then
			message="Procesando línea $param1: $param2"
		else
			message="Processing line $param1: $param2"
		fi
		;;
	"processed_lines")
		if [ "$LANG_ES" = true ]; then
			message="Procesadas $param1 líneas del archivo de información"
		else
			message="Processed $param1 lines from info file"
		fi
		;;
	"removing_info_file")
		if [ "$LANG_ES" = true ]; then
			message="Removiendo archivo de información: $param1"
		else
			message="Removing info file: $param1"
		fi
		;;
	"info_file_removed")
		if [ "$LANG_ES" = true ]; then
			message="Archivo de información removido exitosamente"
		else
			message="Info file removed successfully"
		fi
		;;
	"info_file_warning")
		if [ "$LANG_ES" = true ]; then
			message="Advertencia: No se pudo remover archivo de información"
		else
			message="Warning: Could not remove info file"
		fi
		;;
	"uninstall_completed")
		if [ "$LANG_ES" = true ]; then
			message="Desinstalación del módulo Gboard Lite completada"
		else
			message="Gboard Lite module uninstall completed"
		fi
		;;
	"critical_error")
		if [ "$LANG_ES" = true ]; then
			message="Error crítico durante la desinstalación"
		else
			message="Critical error during uninstall"
		fi
		;;
	"skipping_backup")
		if [ "$LANG_ES" = true ]; then
			message="Saltando marcador de respaldo: $param1"
		else
			message="Skipping backup marker: $param1"
		fi
		;;
	"restoring_backup")
		if [ "$LANG_ES" = true ]; then
			message="Restaurando desde respaldo: $param1"
		else
			message="Restoring from backup: $param1"
		fi
		;;
	"restore_success")
		if [ "$LANG_ES" = true ]; then
			message="Restaurado exitosamente: $param1"
		else
			message="Successfully restored: $param1"
		fi
		;;
	"restore_error")
		if [ "$LANG_ES" = true ]; then
			message="Error: Falló al restaurar $param1 desde respaldo"
		else
			message="Error: Failed to restore $param1 from backup"
		fi
		;;
	"removing_file")
		if [ "$LANG_ES" = true ]; then
			message="Removiendo archivo del módulo: $param1"
		else
			message="Removing module file: $param1"
		fi
		;;
	"remove_success")
		if [ "$LANG_ES" = true ]; then
			message="Removido exitosamente: $param1"
		else
			message="Successfully removed: $param1"
		fi
		;;
	"remove_error")
		if [ "$LANG_ES" = true ]; then
			message="Error: Falló al remover $param1"
		else
			message="Error: Failed to remove $param1"
		fi
		;;
	"file_not_found")
		if [ "$LANG_ES" = true ]; then
			message="Archivo no encontrado (ya limpio): $param1"
		else
			message="File not found (already clean): $param1"
		fi
		;;
	"skipping_critical_path")
		if [ "$LANG_ES" = true ]; then
			message="Saltando ruta crítica: $param1"
		else
			message="Skipping critical path: $param1"
		fi
		;;
	"reached_boundary")
		if [ "$LANG_ES" = true ]; then
			message="Alcanzado límite del sistema: $param1"
		else
			message="Reached system boundary: $param1"
		fi
		;;
	"removing_empty_dir")
		if [ "$LANG_ES" = true ]; then
			message="Removiendo directorio vacío: $param1"
		else
			message="Removing empty directory: $param1"
		fi
		;;
	"failed_remove_dir")
		if [ "$LANG_ES" = true ]; then
			message="Falló al remover directorio: $param1"
		else
			message="Failed to remove directory: $param1"
		fi
		;;
	"dir_not_empty")
		if [ "$LANG_ES" = true ]; then
			message="Directorio no vacío, deteniendo limpieza: $param1"
		else
			message="Directory not empty, stopping cleanup: $param1"
		fi
		;;
	"dir_not_exist")
		if [ "$LANG_ES" = true ]; then
			message="Directorio no existe: $param1"
		else
			message "Directory doesn't exist: $param1"
		fi
		;;
	"max_depth_warning")
		if [ "$LANG_ES" = true ]; then
			message="Advertencia: Alcanzada profundidad máxima de limpieza"
		else
			message="Warning: Reached maximum cleanup depth"
		fi
		;;
	"uninstall_gboard_user")
		if [ "$LANG_ES" = true ]; then
			message="Intentando desinstalar Gboard del espacio de usuario"
		else
			message="Attempting to uninstall Gboard from user space"
		fi
		;;
	"gboard_uninstalled_user")
		if [ "$LANG_ES" = true ]; then
			message="Gboard desinstalado del espacio de usuario"
		else
			message="Gboard uninstalled from user space"
		fi
		;;
	"gboard_uninstall_note")
		if [ "$LANG_ES" = true ]; then
			message="Nota: No se pudo desinstalar Gboard del espacio de usuario (aplicación del sistema)"
		else
			message="Note: Could not uninstall Gboard from user space (system app)"
		fi
		;;
	"gboard_not_found_user")
		if [ "$LANG_ES" = true ]; then
			message="Gboard no encontrado en espacio de usuario"
		else
			message="Gboard not found in user space"
		fi
		;;
	"summary_header")
		if [ "$LANG_ES" = true ]; then
			message="=== RESUMEN DE DESINSTALACIÓN ==="
		else
			message="=== UNINSTALL SUMMARY ==="
		fi
		;;
	"files_restored_count")
		if [ "$LANG_ES" = true ]; then
			message="Archivos restaurados: $param1"
		else
			message="Files restored: $param1"
		fi
		;;
	"files_removed_count")
		if [ "$LANG_ES" = true ]; then
			message="Archivos removidos: $param1"
		else
			message="Files removed: $param1"
		fi
		;;
	"dirs_cleaned_count")
		if [ "$LANG_ES" = true ]; then
			message="Directorios limpiados: $param1"
		else
			message="Directories cleaned: $param1"
		fi
		;;
	"errors_count")
		if [ "$LANG_ES" = true ]; then
			message="Errores encontrados: $param1"
		else
			message="Errors encountered: $param1"
		fi
		;;
	"uninstall_success")
		if [ "$LANG_ES" = true ]; then
			message="✅ Desinstalación completada exitosamente"
		else
			message="✅ Uninstall completed successfully"
		fi
		;;
	"uninstall_with_errors")
		if [ "$LANG_ES" = true ]; then
			message="⚠️ Desinstalación completada con $param1 errores"
		else
			message="⚠️ Uninstall completed with $param1 errors"
		fi
		;;
	"summary_footer")
		if [ "$LANG_ES" = true ]; then
			message="=========================="
		else
			message "=========================="
		fi
		;;
	esac

	echo "[$timestamp] [UNINSTALL] $message" | tee -a "$LOG_FILE" 2>/dev/null
}

# Function to safely remove empty directories
safe_remove_empty_dirs() {
	local target_path="$1"
	local max_depth=10 # Prevent infinite loops
	local current_depth=0

	if [ -z "$target_path" ] || [ "$target_path" = "/" ] || [ "$target_path" = "/system" ]; then
		log_msg_lang "Skipping critical path: $target_path"
		return 1
	fi

	while [ $current_depth -lt $max_depth ]; do
		# Get parent directory
		target_path=$(dirname "$target_path")

		# Stop at critical system paths
		case "$target_path" in
		"/" | "/system" | "/data" | "/data/adb" | "/data/adb/modules")
			log_msg_lang "Reached system boundary: $target_path"
			break
			;;
		esac

		# Check if directory exists and is empty
		if [ -d "$target_path" ]; then
			if [ -z "$(ls -A "$target_path" 2>/dev/null)" ]; then
				log_msg_lang "Removing empty directory: $target_path"
				if rm -rf "$target_path" 2>/dev/null; then
					DIRS_CLEANED=$((DIRS_CLEANED + 1))
				else
					log_msg_lang "Failed to remove directory: $target_path"
					ERRORS=$((ERRORS + 1))
					break
				fi
			else
				log_msg_lang "Directory not empty, stopping cleanup: $target_path"
				break
			fi
		else
			log_msg_lang "Directory doesn't exist: $target_path"
			break
		fi

		current_depth=$((current_depth + 1))
	done

	if [ $current_depth -eq $max_depth ]; then
		log_msg_lang "Warning: Reached maximum cleanup depth"
	fi
}

# Function to restore a single file
restore_file() {
	local file_path="$1"
	local backup_path="${file_path}~"

	# Skip lines ending with ~
	if [ "$(echo -n "$file_path" | tail -c 1)" = "~" ]; then
		log_msg_lang "Skipping backup marker: $file_path"
		return 0
	fi

	# Case 1: Backup exists - restore original file
	if [ -f "$backup_path" ]; then
		log_msg_lang "Restoring from backup: $file_path"
		if mv "$backup_path" "$file_path" 2>/dev/null; then
			FILES_RESTORED=$((FILES_RESTORED + 1))
			log_msg_lang "Successfully restored: $file_path"
		else
			log_msg_lang "Error: Failed to restore $file_path from backup"
			ERRORS=$((ERRORS + 1))
		fi

	# Case 2: No backup - file was created by module, remove it
	elif [ -f "$file_path" ] || [ -L "$file_path" ]; then
		log_msg_lang "Removing module file: $file_path"
		if rm -f "$file_path" 2>/dev/null; then
			FILES_REMOVED=$((FILES_REMOVED + 1))
			log_msg_lang "Successfully removed: $file_path"

			# Clean up empty parent directories
			safe_remove_empty_dirs "$file_path"
		else
			log_msg_lang "Error: Failed to remove $file_path"
			ERRORS=$((ERRORS + 1))
		fi

	# Case 3: File doesn't exist (already cleaned or never existed)
	else
		log_msg_lang "File not found (already clean): $file_path"
	fi
}

# Function to force stop Gboard
stop_gboard() {
	log_msg_lang "Force stopping Gboard"
	if am force-stop "$GBOARD_PACKAGE" 2>/dev/null; then
		log_msg_lang "Gboard stopped successfully"
	else
		log_msg_lang "Warning: Could not stop Gboard (may not be running)"
	fi
}

# Function to uninstall Gboard Lite from user space
uninstall_gboard_user() {
	local package_info=$(pm list packages "$GBOARD_PACKAGE" 2>/dev/null)

	if [ -n "$package_info" ]; then
		log_msg_lang "Attempting to uninstall Gboard from user space"
		if pm uninstall --user 0 "$GBOARD_PACKAGE" >/dev/null 2>&1; then
			log_msg_lang "Gboard uninstalled from user space"
		else
			log_msg_lang "Note: Could not uninstall Gboard from user space (system app)"
		fi
	else
		log_msg_lang "Gboard not found in user space"
	fi
}

# Function to display uninstall summary
show_summary() {
	log_msg_lang "=== UNINSTALL SUMMARY ==="
	log_msg_lang "Files restored: $FILES_RESTORED"
	log_msg_lang "Files removed: $FILES_REMOVED"
	log_msg_lang "Directories cleaned: $DIRS_CLEANED"
	log_msg_lang "Errors encountered: $ERRORS"

	if [ $ERRORS -eq 0 ]; then
		log_msg_lang "✅ Uninstall completed successfully"
	else
		log_msg_lang "⚠️ Uninstall completed with $ERRORS errors"
	fi
	log_msg_lang "=========================="
}

# Main uninstall function
main() {
	log_msg_lang "Starting Gboard Lite module uninstall"
	log_msg_lang "Module directory: $MODDIR"
	log_msg_lang "Info file: $INFO"

	# Stop Gboard before making changes
	stop_gboard

	# Check if info file exists
	if [ ! -f "$INFO" ]; then
		log_msg_lang "No info file found at $INFO"
		log_msg_lang "Module may have been partially installed or already cleaned"
		uninstall_gboard_user
		show_summary
		return 0
	fi

	log_msg_lang "Processing file restoration list..."

	# Read and process each line from the info file
	local line_count=0
	while IFS= read -r line || [ -n "$line" ]; do
		# Skip empty lines
		if [ -z "$line" ]; then
			continue
		fi

		line_count=$((line_count + 1))
		log_msg_lang "Processing line $line_count: $line"

		# Restore/remove the file
		restore_file "$line"

	done <"$INFO"

	log_msg_lang "Processed $line_count lines from info file"

	# Remove the info file itself
	log_msg_lang "Removing info file: $INFO"
	if rm -f "$INFO" 2>/dev/null; then
		log_msg_lang "Info file removed successfully"
	else
		log_msg_lang "Warning: Could not remove info file"
		ERRORS=$((ERRORS + 1))
	fi

	# Try to uninstall Gboard from user space
	uninstall_gboard_user

	# Show final summary
	show_summary

	log_msg_lang "Gboard Lite module uninstall completed"
}

# Execute main function with error handling
if ! main "$@"; then
	log_msg_lang "Critical error during uninstall"
	exit 1
fi
