#!/bin/bash

# Function to return the icon based on a value (0-100)
get_icon() {
    local VAL=$1
    case $VAL in
        [0-9]) echo "󰝦" ;;           # 0-9%
        [1-2][0-9]) echo "󰪞" ;;      # 10-29%
        [3-4][0-9]) echo "󰪟" ;;      # 30-49%
        [5-6][0-9]) echo "󰪣" ;;      # 50-69%
        [7-8][0-9]) echo "󰪤" ;;      # 70-89%
        9[0-4]) echo "󰪥" ;;         # 90-94%
        9[5-9]|100) echo "󰪢" ;;     # 95-100%
        *) echo "󰪠" ;;               # Default
    esac
}

# 1. Fetch Data
DATA=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | tr -d '[:space:]')
UTIL=$(echo "$DATA" | cut -d',' -f1)
TEMP=$(echo "$DATA" | cut -d',' -f2)

# 2. Get Icons
ICON_UTIL=$(get_icon "$UTIL")
ICON_TEMP=$(get_icon "$TEMP")

# 3. Determine Color Class
if [ "$UTIL" -ge 90 ] || [ "$TEMP" -ge 80 ]; then
    STATE="critical"
elif [ "$UTIL" -ge 70 ] || [ "$TEMP" -ge 70 ]; then
    STATE="hot"
elif [ "$UTIL" -ge 30 ] || [ "$TEMP" -ge 55 ]; then
    STATE="warm"
else
    STATE="cold"
fi

# 4. Output JSON (Notice: No extra text in 'alt' now)
echo "{\"text\": \"$ICON_UTIL\", \"alt\": \"$ICON_TEMP\", \"class\": \"$STATE\", \"tooltip\": \"GPU: $UTIL% | Temp: $TEMP°C\"}"
