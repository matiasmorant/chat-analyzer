#!/bin/bash

while true; do
    # 1. Select ZIP
    ZIP_FILE=$(fd -e zip . ~/storage/downloads/ | fzf --prompt="Select ZIP: ")
    [ -z "$ZIP_FILE" ] && echo "No file selected. Exiting." && break

    # 2. Extract
    cp "$ZIP_FILE" .
    LOCAL_ZIP=$(basename "$ZIP_FILE")
    TEMP_DIR="temp_unzip_$(date +%s)"
    mkdir "$TEMP_DIR"
    unzip -q "$LOCAL_ZIP" -d "$TEMP_DIR"

    # 3. Recursive Clean: Only mv if name changes
    # We use -depth (via find or natural fd behavior) to rename children before parents
    fd -H . "$TEMP_DIR" -x bash -c '
        s="$1"; d=$(dirname "$s"); b=$(basename "$s")
        new="${b// /_}"; new="${new//[^[:ascii:]]/}"
        [ "$b" != "$new" ] && mv "$s" "$d/$new"
    ' _ {}

    # 4. Select item to keep
    cd "$TEMP_DIR"
    PRESERVE_PATH=$(fd . | fzf --prompt="Select item to keep: ")

    if [ -n "$PRESERVE_PATH" ]; then
        FINAL_NAME=$(basename "$PRESERVE_PATH")
        mv "$PRESERVE_PATH" "../$FINAL_NAME"
        cd ..
        rm -rf "$TEMP_DIR" "$LOCAL_ZIP"

        # 5. Process
        LOWER_ZIP=$(echo "$LOCAL_ZIP" | tr '[:upper:]' '[:lower:]')
        if [[ "$LOWER_ZIP" == *"instagram"* ]]; then
            python -c "from statsAvg2 import *; write_csv(parse_instagram('$FINAL_NAME'))"
        elif [[ "$LOWER_ZIP" == *"whatsapp"* ]]; then
            python -c "from statsAvg2 import *; write_csv(parse_whatsapp('$FINAL_NAME'))"
        fi

        rm -rf "$FINAL_NAME"
        echo "Processed: $FINAL_NAME"
    else
        cd ..
        rm -rf "$TEMP_DIR" "$LOCAL_ZIP"
    fi

    # 6. Loop Control
    read -p "Add another? (y/n): " CHOICE
    [[ "$CHOICE" =~ ^[yY] ]] || {
        [ -f "data.csv" ] && python -c "from statsAvg2 import *; plot_avg(read_csv('data.csv'))"
        break
    }
done

IMG=$(fd -e png)
mv "$IMG"  ~/storage/downloads/
# termux-open ~/storage/downloads/"$(basename "$IMG")"

