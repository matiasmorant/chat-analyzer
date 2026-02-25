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
PRESERVE=$(fd . "$TEMP_DIR" | sed "s|^$TEMP_DIR/||" | fzf --prompt="Select item to keep: ")

[ -z "$PRESERVE" ] && echo "Nothing selected to keep. Cleaning up..." && rm -rf "$TEMP_DIR" "$LOCAL_ZIP" && exit 1

# Move selected to current folder and clean up zip/temp
mv "$TEMP_DIR/$PRESERVE" .
rm -rf "$TEMP_DIR"
rm "$LOCAL_ZIP"

# 5. Conditional Python Execution
# Convert to lowercase for easier comparison
LOWER_PRESERVE=$(echo "$LOCAL_ZIP" | tr '[:upper:]' '[:lower:]')

if [[ "$LOWER_PRESERVE" == *"instagram"* ]]; then
    echo "Instagram data detected. Running parser..."
    python -c "from statsAvg2 import *; write_csv(parse_instagram('$(basename "$PRESERVE")'))"
elif [[ "$LOWER_PRESERVE" == *"whatsapp"* ]]; then
    echo "WhatsApp data detected. Running parser..."
    python -c "from statsAvg2 import *; write_csv(parse_whatsapp('$(basename "$PRESERVE")'))"
fi

echo "Done! Preserved: $PRESERVE"
