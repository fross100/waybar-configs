#!/bin/bash

# State file to track toggle
STATE_FILE="/tmp/waybar_gpu_state"

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

# Fetch GPU Data
DATA=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | tr -d '[:space:]')

if [ -z "$DATA" ]; then
  echo '{"text": "󰘙", "class": "normal", "tooltip": "No GPU detected"}'
  exit 0
fi

UTIL=$(echo "$DATA" | cut -d',' -f1)
TEMP=$(echo "$DATA" | cut -d',' -f2)

# Determine what to show based on state
if [ "$CURRENT_STATE" = "temp" ]; then
  # Showing temperature
  ICON=$(get_pie_icon "$TEMP")
  TEXT="$ICON"
  
  # Color class based on temperature
  if [ "$TEMP" -ge 80 ]; then
    CLASS="temp-high"
  elif [ "$TEMP" -ge 55 ]; then
    CLASS="temp-med"
  else
    CLASS="temp-low"
  fi
else
  # Showing usage
  ICON=$(get_pie_icon "$UTIL")
  TEXT="$ICON"
  
  # Color class based on usage
  if [ "$UTIL" -ge 90 ]; then
    CLASS="critical"
  elif [ "$UTIL" -ge 70 ]; then
    CLASS="hot"
  else
    CLASS="normal"
  fi
fi

# Tooltip always shows both values
TOOLTIP="GPU Usage: ${UTIL}% | Temp: ${TEMP}°C (Click to toggle)"

# Output JSON
echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
