#!/bin/bash

# 1. Improved Icon Function (using -ge for better logic)
get_icon() {
    local VAL=$1
    if [ "$VAL" -ge 95 ]; then echo "󰪢"
    elif [ "$VAL" -ge 90 ]; then echo "󰪥"
    elif [ "$VAL" -ge 70 ]; then echo "󰪤"
    elif [ "$VAL" -ge 50 ]; then echo "󰪣"
    elif [ "$VAL" -ge 30 ]; then echo "󰪟"
    elif [ "$VAL" -ge 10 ]; then echo "󰪞"
    else echo "󰝦"
    fi
}

# 2. Get CPU Usage (Force to Integer)
CPU_UTIL=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1 | tr -dc '0-9')
CPU_UTIL=${CPU_UTIL:-0}

# 3. Get CPU Temp
TEMP_PATH=$(grep -l "coretemp\|k10temp\|zenpower" /sys/class/hwmon/hwmon*/name | head -n1 | sed 's/name/temp1_input/')

if [ -f "$TEMP_PATH" ]; then
    RAW_TEMP=$(cat "$TEMP_PATH")
    if [ "$RAW_TEMP" -gt 1000 ]; then
        CPU_TEMP=$((RAW_TEMP / 1000))
    else
        CPU_TEMP=$RAW_TEMP
    fi
else
    # Fallback to sensors
    CPU_TEMP=$(sensors | grep -E 'Package id 0|Tdie|Tctl' | awk '{print $4}' | head -n1)
fi

# --- THE AGGRESSIVE CLEANING STEP ---
# This removes EVERYTHING (symbols, letters, dots) except the numbers.
CPU_TEMP=$(echo "$CPU_TEMP" | tr -dc '0-9')
CPU_TEMP=${CPU_TEMP:-0}

# 4. Generate Icons
ICON_UTIL=$(get_icon "$CPU_UTIL")
ICON_TEMP=$(get_icon "$CPU_TEMP")

# 5. Determine State Class
if [ "$CPU_UTIL" -ge 90 ] || [ "$CPU_TEMP" -ge 80 ]; then
    STATE="critical"
elif [ "$CPU_UTIL" -ge 70 ] || [ "$CPU_TEMP" -ge 70 ]; then
    STATE="hot"
elif [ "$CPU_UTIL" -ge 30 ] || [ "$CPU_TEMP" -ge 55 ]; then
    STATE="warm"
else
    STATE="cold"
fi

# 6. Final JSON Output
echo "{\"text\": \"$ICON_UTIL\", \"alt\": \"$ICON_TEMP\", \"class\": \"$STATE\", \"tooltip\": \"CPU: $CPU_UTIL% | Temp: $CPU_TEMP°C\"}"
