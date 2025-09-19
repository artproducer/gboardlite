#!/system/bin/sh
# Gboard Lite Module Uninstaller
# Restores system to original state before module installation

# Module configuration
MODDIR=${0%/*}
MODID="gboardlite_apmods"
INFO="/data/adb/modules/.gboardlite_apmods-files"
GBOARD_PACKAGE="com.google.android.inputmethod.latin"
LOG_FILE="/cache/gboardlite_uninstall.log"

# Counters for statistics
FILES_RESTORED=0
FILES_REMOVED=0
DIRS_CLEANED=0
ERRORS=0

# Function to log messages with timestamp
log_msg() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [UNINSTALL] $1" | tee -a "$LOG_FILE" 2>/dev/null
}

# Function to safely remove empty directories
safe_remove_empty_dirs() {
    local target_path="$1"
    local max_depth=10  # Prevent infinite loops
    local current_depth=0
    
    if [ -z "$target_path" ] || [ "$target_path" = "/" ] || [ "$target_path" = "/system" ]; then
        log_msg "Skipping critical path: $target_path"
        return 1
    fi
    
    while [ $current_depth -lt $max_depth ]; do
        # Get parent directory
        target_path=$(dirname "$target_path")
        
        # Stop at critical system paths
        case "$target_path" in
            "/" | "/system" | "/data" | "/data/adb" | "/data/adb/modules")
                log_msg "Reached system boundary: $target_path"
                break
                ;;
        esac
        
        # Check if directory exists and is empty
        if [ -d "$target_path" ]; then
            if [ -z "$(ls -A "$target_path" 2>/dev/null)" ]; then
                log_msg "Removing empty directory: $target_path"
                if rm -rf "$target_path" 2>/dev/null; then
                    DIRS_CLEANED=$((DIRS_CLEANED + 1))
                else
                    log_msg "Failed to remove directory: $target_path"
                    ERRORS=$((ERRORS + 1))
                    break
                fi
            else
                log_msg "Directory not empty, stopping cleanup: $target_path"
                break
            fi
        else
            log_msg "Directory doesn't exist: $target_path"
            break
        fi
        
        current_depth=$((current_depth + 1))
    done
    
    if [ $current_depth -eq $max_depth ]; then
        log_msg "Warning: Reached maximum cleanup depth"
    fi
}

# Function to restore a single file
restore_file() {
    local file_path="$1"
    local backup_path="${file_path}~"
    
    # Skip lines ending with ~
    if [ "$(echo -n "$file_path" | tail -c 1)" = "~" ]; then
        log_msg "Skipping backup marker: $file_path"
        return 0
    fi
    
    # Case 1: Backup exists - restore original file
    if [ -f "$backup_path" ]; then
        log_msg "Restoring from backup: $file_path"
        if mv "$backup_path" "$file_path" 2>/dev/null; then
            FILES_RESTORED=$((FILES_RESTORED + 1))
            log_msg "Successfully restored: $file_path"
        else
            log_msg "Error: Failed to restore $file_path from backup"
            ERRORS=$((ERRORS + 1))
        fi
        
    # Case 2: No backup - file was created by module, remove it
    elif [ -f "$file_path" ] || [ -L "$file_path" ]; then
        log_msg "Removing module file: $file_path"
        if rm -f "$file_path" 2>/dev/null; then
            FILES_REMOVED=$((FILES_REMOVED + 1))
            log_msg "Successfully removed: $file_path"
            
            # Clean up empty parent directories
            safe_remove_empty_dirs "$file_path"
        else
            log_msg "Error: Failed to remove $file_path"
            ERRORS=$((ERRORS + 1))
        fi
        
    # Case 3: File doesn't exist (already cleaned or never existed)
    else
        log_msg "File not found (already clean): $file_path"
    fi
}

# Function to force stop Gboard
stop_gboard() {
    log_msg "Force stopping Gboard"
    if am force-stop "$GBOARD_PACKAGE" 2>/dev/null; then
        log_msg "Gboard stopped successfully"
    else
        log_msg "Warning: Could not stop Gboard (may not be running)"
    fi
}

# Function to uninstall Gboard Lite from user space
uninstall_gboard_user() {
    local package_info=$(pm list packages "$GBOARD_PACKAGE" 2>/dev/null)
    
    if [ -n "$package_info" ]; then
        log_msg "Attempting to uninstall Gboard from user space"
        if pm uninstall --user 0 "$GBOARD_PACKAGE" >/dev/null 2>&1; then
            log_msg "Gboard uninstalled from user space"
        else
            log_msg "Note: Could not uninstall Gboard from user space (system app)"
        fi
    else
        log_msg "Gboard not found in user space"
    fi
}

# Function to display uninstall summary
show_summary() {
    log_msg "=== UNINSTALL SUMMARY ==="
    log_msg "Files restored: $FILES_RESTORED"
    log_msg "Files removed: $FILES_REMOVED" 
    log_msg "Directories cleaned: $DIRS_CLEANED"
    log_msg "Errors encountered: $ERRORS"
    
    if [ $ERRORS -eq 0 ]; then
        log_msg "✅ Uninstall completed successfully"
    else
        log_msg "⚠️ Uninstall completed with $ERRORS errors"
    fi
    log_msg "=========================="
}

# Main uninstall function
main() {
    log_msg "Starting Gboard Lite module uninstall"
    log_msg "Module directory: $MODDIR"
    log_msg "Info file: $INFO"
    
    # Stop Gboard before making changes
    stop_gboard
    
    # Check if info file exists
    if [ ! -f "$INFO" ]; then
        log_msg "No info file found at $INFO"
        log_msg "Module may have been partially installed or already cleaned"
        uninstall_gboard_user
        show_summary
        return 0
    fi
    
    log_msg "Processing file restoration list..."
    
    # Read and process each line from the info file
    local line_count=0
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        if [ -z "$line" ]; then
            continue
        fi
        
        line_count=$((line_count + 1))
        log_msg "Processing line $line_count: $line"
        
        # Restore/remove the file
        restore_file "$line"
        
    done < "$INFO"
    
    log_msg "Processed $line_count lines from info file"
    
    # Remove the info file itself
    log_msg "Removing info file: $INFO"
    if rm -f "$INFO" 2>/dev/null; then
        log_msg "Info file removed successfully"
    else
        log_msg "Warning: Could not remove info file"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Try to uninstall Gboard from user space
    uninstall_gboard_user
    
    # Show final summary
    show_summary
    
    log_msg "Gboard Lite module uninstall completed"
}

# Execute main function with error handling
if ! main "$@"; then
    log_msg "Critical error during uninstall"
    exit 1
fi