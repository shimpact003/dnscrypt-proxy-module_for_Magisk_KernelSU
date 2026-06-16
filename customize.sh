#!/system/bin/sh

ui_print " "
ui_print "******************************"
ui_print "*   dnscrypt-proxy-android   *"
ui_print "*        (Latest)             *"
ui_print "******************************"
ui_print "*           M0H4N            *"
ui_print "******************************"
ui_print " "

# Determine architecture and binary filename
case "$ARCH" in
  arm)
    BINARY_NAME="dnscrypt-proxy-android-arm"
    ;;
  arm64)
    BINARY_NAME="dnscrypt-proxy-android-arm64"
    ;;
  x86)
    BINARY_NAME="dnscrypt-proxy-android-i386"
    ;;
  x64)
    BINARY_NAME="dnscrypt-proxy-android-x86_64"
    ;;
  *)
    abort "Unsupported architecture: $ARCH"
    ;;
esac

# Temporary directory for downloads
TEMP_DIR="$MODPATH/tmp"
mkdir -p "$TEMP_DIR"

# Fetch latest release info from GitHub API
ui_print "* Fetching latest dnscrypt-proxy release..."
RELEASE_INFO=$(curl -s "https://api.github.com/repos/dnscrypt/dnscrypt-proxy/releases/latest")

if [ -z "$RELEASE_INFO" ]; then
  abort "Failed to fetch release information. Check internet connection."
fi

# Extract version and download URL
LATEST_VERSION=$(echo "$RELEASE_INFO" | grep -o '"tag_name":"[^"]*' | cut -d'"' -f4)
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o "\"browser_download_url\":\"[^\"]*$BINARY_NAME[^\"]*\"" | head -1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
  abort "Could not find binary for $ARCH architecture in the latest release."
fi

ui_print "* Latest version: $LATEST_VERSION"
ui_print "* Downloading dnscrypt-proxy for $ARCH..."

# Download the binary
BINARY_FILE="$TEMP_DIR/$BINARY_NAME"
if ! curl -L -o "$BINARY_FILE" "$DOWNLOAD_URL" 2>/dev/null; then
  abort "Failed to download dnscrypt-proxy binary."
fi

# Verify the binary was downloaded
if [ ! -f "$BINARY_FILE" ]; then
  abort "Binary file not found after download."
fi

# Create necessary directories
ui_print "* Creating binary path..."
mkdir -p "$MODPATH/system/bin"

ui_print "* Creating configuration path..."
mkdir -p /storage/emulated/0/dnscrypt-proxy

# Copy and setup the binary
ui_print "* Installing dnscrypt-proxy binary..."
cp -f "$BINARY_FILE" "$MODPATH/system/bin/dnscrypt-proxy"

if [ ! -f "$MODPATH/system/bin/dnscrypt-proxy" ]; then
  abort "Failed to copy binary file."
fi

# Backup existing config
CONFIG_FILE="/storage/emulated/0/dnscrypt-proxy/dnscrypt-proxy.toml"
if [ -f "$CONFIG_FILE" ]; then
  ui_print "* Backing up existing configuration..."
  cp -f "$CONFIG_FILE" "${CONFIG_FILE}-$(date +%Y%m%d%H%M).bak"
fi

# Copy configuration files
if [ -d "$MODPATH/config" ]; then
  ui_print "* Copying configuration files..."
  cp -rf "$MODPATH/config"/* /storage/emulated/0/dnscrypt-proxy/
else
  ui_print "! Warning: Configuration files not found in module."
fi

# Set permissions
ui_print "* Setting permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0755
set_perm "$MODPATH/system/bin/dnscrypt-proxy" 0 0 0755

# Disable Android 9+ Private DNS mode
ui_print "* Disabling Android 9+ Private DNS mode..."
settings put global private_dns_mode off

# Save version info for future updates
ui_print "* Saving version information..."
echo "$LATEST_VERSION" > "$MODPATH/INSTALLED_VERSION"

# Cleanup
ui_print "* Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

ui_print " "
ui_print "* Installation complete!"
ui_print "* Installed version: $LATEST_VERSION"
ui_print " "
