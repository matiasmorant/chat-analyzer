#!/bin/bash

while true; do
    # 1. Fuzzy search for zip files
    ZIP_FILE=$(fd -e zip . ~/storage/downloads/ | fzf --prompt="Select ZIP: ")
    [ -z "$ZIP_FILE" ] && echo "No file selected. Exiting." && break

    # 2. Copy and prepare
    cp "$ZIP_FILE" .
    LOCAL_ZIP=$(basename "$ZIP_FILE")
    TEMP_DIR="temp_unzip_$(date +%s)"
    mkdir "$TEMP_DIR"
    unzip -q "$LOCAL_ZIP" -d "$TEMP_DIR"

    # s/ /_/g replaces spaces
    # s/[^\x00-\x7F]//g removes non-ASCII (emojis/special chars)
    # find "$TEMP_DIR" -depth -exec rename 's/ /_/g; s/[^\x00-\x7F]//g' {} +
    # fd -H -d 10 . "$TEMP_DIR" -x rename 's/ /_/g; s/[^\x00-\x7F]//g'
    fd -H . "$TEMP_DIR" -x bash -c 'mv "$1" "${1//[^[:ascii:]]/}"' _ {}
    
    fd .

    # 3. Fuzzy search which cleaned item to keep
    PRESERVE_PATH=$(fd . "$TEMP_DIR" | fzf --prompt="Select item to keep: ")

    if [ -z "$PRESERVE_PATH" ]; then
        echo "Nothing selected. Cleaning up..."
        rm -rf "$TEMP_DIR" "$LOCAL_ZIP"
    else
        # Move the now-clean file to current directory
        FINAL_NAME=$(basename "$PRESERVE_PATH")
        mv "$PRESERVE_PATH" "./$FINAL_NAME"
        
        # Cleanup internals
        rm -rf "$TEMP_DIR" "$LOCAL_ZIP"

        # 4. Conditional Python Execution
        LOWER_ZIP=$(echo "$LOCAL_ZIP" | tr '[:upper:]' '[:lower:]')

        if [[ "$LOWER_ZIP" == *"instagram"* ]]; then
            echo "Processing Instagram: $FINAL_NAME"
            python -c "from statsAvg2 import *; write_csv(parse_instagram('$FINAL_NAME'))"
        elif [[ "$LOWER_ZIP" == *"whatsapp"* ]]; then
            echo "Processing WhatsApp: $FINAL_NAME"
            python -c "from statsAvg2 import *; write_csv(parse_whatsapp('$FINAL_NAME'))"
        fi

        rm -rf "$FINAL_NAME"
        echo "Successfully processed data."
    fi

    # 5. Loop control
    read -p "Add another file? (y/n): " CHOICE
    case "$CHOICE" in
        [yY]*) echo "Restarting..." ;;
        *) 
            if [ -f "data.csv" ]; then
                echo 'plotting'
                python -c "from statsAvg2 import *; plot_avg(read_csv('data.csv'))"
            else
                echo "No data to plot."
            fi
            break 
            ;;
    esac
done

echo "Done!"
