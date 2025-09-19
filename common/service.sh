#!/system/bin/sh
# Gboard Lite Module Service Script
# This script runs at boot to verify module status

# Module configuration
MODDIR=${0%/*}
MODID="gboardlite_apmods"
GBOARD_PACKAGE="com.google.android.inputmethod.latin"
PROPFILE="$MODDIR/module.prop"

# Status messages
MSG_WORKING="[ ✅ Module is working ]"
MSG_MANUAL_INSTALL="[ 🙁 Module installed but you need to install Gboard Lite manually ]"
MSG_ERROR="[ ❌ Module error - check logs ]"

# Function to log messages
log_msg() {
	echo "[$MODID] $1" >>/cache/magisk.log 2>/dev/null
}

# Function to update module description
update_description() {
	local new_desc="$1"
	if [ -f "$PROPFILE" ]; then
		sed -Ei "s/^description=(\[.*\][[:space:]]*)?/description=$new_desc /g" "$PROPFILE"
		log_msg "Updated description: $new_desc"
	else
		log_msg "Error: module.prop not found at $PROPFILE"
	fi
}

# Function to update author info
update_author() {
	if [ -f "$PROPFILE" ]; then
		sed -i "s/^author=.*/author=@artistaproducer/g" "$PROPFILE"
	fi
}

# Function to check if Android system is ready
is_system_ready() {
	# Check if package manager is available and system is initialized
	if [ ! -d "/data/misc/shared_relro" ]; then
		log_msg "System not ready - shared_relro directory missing"
		return 1
	fi

	# Check if package manager is responsive
	if ! timeout 10 pm list packages >/dev/null 2>&1; then
		log_msg "Package manager not responsive"
		return 1
	fi

	return 0
}

# Function to check if Gboard package is installed
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

# Main execution
main() {
	log_msg "Service script started"

	# Wait for system to be ready (with timeout)
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

	# Check if we timed out
	if [ $retry_count -eq $max_retries ]; then
		log_msg "System readiness timeout - updating with error status"
		update_description "$MSG_ERROR"
		update_author
		exit 1
	fi

	# Check Gboard installation status
	if is_gboard_installed; then
		log_msg "Module verification successful"
		update_description "$MSG_WORKING"
	else
		log_msg "Gboard not found - manual installation required"
		update_description "$MSG_MANUAL_INSTALL"
	fi

	# Always update author info
	update_author

	log_msg "Service script completed"
}

# Execute main function
main "$@"
