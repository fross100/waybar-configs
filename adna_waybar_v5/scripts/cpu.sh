#!/bin/bash

# State file to track toggle
STATE_FILE="/tmp/waybar_cpu_state"

# Initialize state if not exists
if [ ! -f "$STATE_FILE" ]; then
  echo "usage" > "$STATE_FILE"
fi

CURRENT_STATE=$(cat "$STATE_FILE")

# Function to return the pie icon based on value (0-100) - 8 variants
get_pie_icon() {
  local VAL=$1
  if [ "$VAL" -ge 88 ]; then echo "󰪥"      # 88-100: full
  elif [ "$VAL" -ge 75 ]; then echo "󰪤"   # 75-87
  elif [ "$VAL" -ge 63 ]; then echo "󰪣"   # 63-74
  elif [ "$VAL" -ge 50 ]; then echo "󰪢"   # 50-62
  elif [ "$VAL" -ge 38 ]; then echo "󰪡"   # 38-49
  elif [ "$VAL" -ge 25 ]; then echo "󰪠"   # 25-37
  elif [ "$VAL" -ge 13 ]; then echo "󰪟"   # 13-24
  else echo "󰪞"                            # 0-12: empty
  fi
}

# Get CPU Usage
CPU_UTIL=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1 | tr -dc '0-9')
CPU_UTIL=${CPU_UTIL:-0}

# Get CPU Temp
TEMP_PATH=$(grep -l "coretemp\|k10temp\|zenpower" /sys/class/hwmon/hwmon*/name | head -n1 | sed 's/name/temp1_input/')

if [ -f "$TEMP_PATH" ]; then
  RAW_TEMP=$(cat "$TEMP_PATH")
  if [ "$RAW_TEMP" -gt 1000 ]; then
    CPU_TEMP=$((RAW_TEMP / 1000))
  else
    CPU_TEMP=$RAW_TEMP
  fi
else
  CPU_TEMP=$(sensors | grep -E 'Package id 0|Tdie|Tctl' | awk '{print $4}' | head -n1 | tr -dc '0-9')
fi
CPU_TEMP=${CPU_TEMP:-0}

# Determine what to show based on state
if [ "$CURRENT_STATE" = "temp" ]; then
  # Showing temperature
  ICON=$(get_pie_icon "$CPU_TEMP")
  TEXT="$ICON"
  
  # Color class based on temperature
  if [ "$CPU_TEMP" -ge 80 ]; then
    CLASS="temp-high"
  elif [ "$CPU_TEMP" -ge 55 ]; then
    CLASS="temp-med"
  else
    CLASS="temp-low"
  fi
else
  # Showing usage
  ICON=$(get_pie_icon "$CPU_UTIL")
  TEXT="$ICON"
  
  # Color class based on usage
  if [ "$CPU_UTIL" -ge 90 ]; then
    CLASS="critical"
  elif [ "$CPU_UTIL" -ge 70 ]; then
    CLASS="hot"
  else
    CLASS="normal"
  fi
fi

# Tooltip always shows both values
TOOLTIP="CPU Usage: ${CPU_UTIL}% | Temp: ${CPU_TEMP}°C (Click to toggle)"

# Output JSON
echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
