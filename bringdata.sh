#!/bin/bash

# 1. Fuzzy search for zip files in downloads
ZIP_FILE=$(fd -e zip . ~/storage/downloads/ | fzf --prompt="Select ZIP: ")

# Exit if no file selected
[ -z "$ZIP_FILE" ] && echo "No file selected. Exiting." && exit 1

# 2. Copy selected file to current folder
cp "$ZIP_FILE" .
LOCAL_ZIP=$(basename "$ZIP_FILE")

# 3. Unzip into a temporary directory to keep things clean
TEMP_DIR="temp_unzip_$(date +%s)"
mkdir "$TEMP_DIR"
unzip -q "$LOCAL_ZIP" -d "$TEMP_DIR"

# 4. Fuzzy search which extracted file/folder to preserve
# We search inside the temp dir, but strip the prefix for a cleaner view
PRESERVE=$(fd . "$TEMP_DIR" | sed "s|^$TEMP_DIR/||" | fzf --prompt="Select item to keep: ")

[ -z "$PRESERVE" ] && echo "Nothing selected to keep. Cleaning up..." && rm -rf "$TEMP_DIR" "$LOCAL_ZIP" && exit 1

# 5. Move selected to current folder, delete the rest
mv "$TEMP_DIR/$PRESERVE" .
rm -rf "$TEMP_DIR"
rm "$LOCAL_ZIP"

echo "Done! Preserved: $PRESERVE"
