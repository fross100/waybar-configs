#!/bin/bash

HISTORY_FILE="/tmp/network_down_history"
UP_HISTORY_FILE="/tmp/network_up_history"
STATS_FILE="/tmp/network_stats"

add_to_history() {
    local new_val=$1
    local max_points=40
    local file=$2
    local history=""

    if [ -f "$file" ]; then
        history=$(cat "$file")
        local count=$(echo "$history" | wc -l)
        if [ "$count" -ge "$max_points" ]; then
            history=$(echo "$history" | tail -n +2)
        fi
    fi

    while [ $(echo "$history" | wc -l) -lt $((max_points - 1)) ]; do
        history="0"$'\n'"$history"
    done

    echo "$history"
    echo "$new_val"
}

make_graph() {
    local history="$1"
    local width=40
    local chars="▁▂▃▄▅▆▇█"
    local graph=""

    while IFS= read -r val; do
        if [ -z "$val" ] || ! [[ "$val" =~ ^[0-9.]+$ ]]; then
            continue
        fi
        local idx=$(( (val * 8 / 100) ))
        [ "$idx" -gt 7 ] && idx=7
        local char="${chars:$idx:1}"
        graph+="$char"
        if [ ${#graph} -ge "$width" ]; then
            break
        fi
    done <<< "$history"

    echo "$graph"
}

make_bar() {
    local percent=$1
    local width=6
    local filled=$(awk "BEGIN {printf \"%.0f\", $percent * $width / 100}")
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$((width - filled))
    [ "$filled" -gt 0 ] && printf "█%.0s" $(seq 1 $filled)
    [ "$empty" -gt 0 ] && printf "░%.0s" $(seq 1 $empty)
}

make_display_bar() {
    local percent=$1
    local width=6
    local filled=$(awk "BEGIN {printf \"%.0f\", $percent * $width / 100}")
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$((width - filled))
    [ "$filled" -gt 0 ] && printf "█%.0s" $(seq 1 $filled)
    [ "$empty" -gt 0 ] && printf "░%.0s" $(seq 1 $empty)
}

MAX_SPEED=1000

get_all_interface_stats() {
    local primary_iface=$(ip route show default 2>/dev/null | awk '/dev/ {print $5}' | head -1)
    if [ -z "$primary_iface" ]; then
        primary_iface="enp5s0"
    fi

    local rx=0
    local tx=0

    if [ -f "/proc/net/dev" ]; then
        while IFS=: read -r iface rest; do
            iface=$(echo "$iface" | tr -d ' ')
            if [ "$iface" = "$primary_iface" ]; then
                rx=$(echo "$rest" | awk '{print $1}')
                tx=$(echo "$rest" | awk '{print $9}')
                break
            fi
        done < /proc/net/dev
    fi

    echo "$rx|$tx"
}

get_network_info() {
    local primary_iface=$(ip route show default 2>/dev/null | awk '/dev/ {print $5}' | head -1)
    if [ -z "$primary_iface" ]; then
        primary_iface="enp5s0"
    fi

    local iface_type="Ethernet"
    if echo "$primary_iface" | grep -qi "wlan\|wl\|wifi\|wireless"; then
        iface_type="WiFi"
    fi

    local ip_addr=$(ip -4 addr show "$primary_iface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    if [ -z "$ip_addr" ]; then
        ip_addr="N/A"
    fi

    local speed=""
    if [ -f "/sys/class/net/$primary_iface/speed" ]; then
        speed=$(cat "/sys/class/net/$primary_iface/speed" 2>/dev/null)
        if [ -n "$speed" ]; then
            speed="${speed} Mbps"
        else
            speed="Unknown"
        fi
    else
        speed="N/A"
    fi

    local mac_addr=$(cat "/sys/class/net/$primary_iface/address" 2>/dev/null || echo "N/A")

    echo "${primary_iface}|${iface_type}|${ip_addr}|${speed}|${mac_addr}"
}

STATS_DATA=$(get_all_interface_stats)
total_rx=$(echo "$STATS_DATA" | cut -d'|' -f1)
total_tx=$(echo "$STATS_DATA" | cut -d'|' -f2)

NOW=$(date +%s%3N)

if [ -f "$STATS_FILE" ]; then
    prev_time=$(head -1 "$STATS_FILE")
    prev_total_rx=$(tail -1 "$STATS_FILE" | cut -d'|' -f1)
    prev_total_tx=$(tail -1 "$STATS_FILE" | cut -d'|' -f2)

    if [ -n "$prev_total_rx" ] && [ -n "$prev_total_tx" ] && [ -n "$prev_time" ]; then
        time_diff=$((NOW - prev_time))
        if [ "$time_diff" -gt 0 ] && [ "$time_diff" -lt 10000 ]; then
            rx_diff=$((total_rx - prev_total_rx))
            tx_diff=$((total_tx - prev_total_tx))

            rx_kbps=$(awk "BEGIN {printf \"%.1f\", $rx_diff * 8 / $time_diff * 1000 / 1000}")
            tx_kbps=$(awk "BEGIN {printf \"%.1f\", $tx_diff * 8 / $time_diff * 1000 / 1000}")
            rx_mbps=$(awk "BEGIN {printf \"%.1f\", $rx_diff * 8 / $time_diff * 1000 / 1000000}")
            tx_mbps=$(awk "BEGIN {printf \"%.1f\", $tx_diff * 8 / $time_diff * 1000 / 1000000}")

            rx_mbps_val=$(awk "BEGIN {print ($rx_mbps >= 1 ? $rx_mbps : 0)}")
            tx_mbps_val=$(awk "BEGIN {print ($tx_mbps >= 1 ? $tx_mbps : 0)}")

            if (( $(echo "$rx_mbps < 1" | bc -l 2>/dev/null) )); then
                down_speed="${rx_kbps} Kbps"
            else
                down_speed="${rx_mbps} Mbps"
            fi

            if (( $(echo "$tx_mbps < 1" | bc -l 2>/dev/null) )); then
                up_speed="${tx_kbps} Kbps"
            else
                up_speed="${tx_mbps} Mbps"
            fi

            rx_mbps_int=${rx_mbps%.*}
            tx_mbps_int=${tx_mbps%.*}
            [ -z "$rx_mbps_int" ] && rx_mbps_int=0
            [ -z "$tx_mbps_int" ] && tx_mbps_int=0

            [ "$rx_mbps_int" -gt "$MAX_SPEED" ] && rx_mbps_int=$MAX_SPEED
            [ "$tx_mbps_int" -gt "$MAX_SPEED" ] && tx_mbps_int=$MAX_SPEED

            down_bar=$(make_bar $rx_mbps_int)
            up_bar=$(make_bar $tx_mbps_int)

            new_down_history=$(add_to_history "$rx_mbps_int" "$HISTORY_FILE")
            echo "$new_down_history" > "$HISTORY_FILE"
            down_graph=$(make_graph "$new_down_history")

            new_up_history=$(add_to_history "$tx_mbps_int" "$UP_HISTORY_FILE")
            echo "$new_up_history" > "$UP_HISTORY_FILE"
            up_graph=$(make_graph "$new_up_history")

            down_display=$(make_display_bar $rx_mbps_int)
            up_display=$(make_display_bar $tx_mbps_int)

            text="<span font='6'> </span><span font='6'>${down_display}</span>
<span font='6'> </span><span font='6'>${up_display}</span>"

            NETWORK_INFO=$(get_network_info)
            interface=$(echo "$NETWORK_INFO" | cut -d'|' -f1)
            iface_type=$(echo "$NETWORK_INFO" | cut -d'|' -f2)
            ip_addr=$(echo "$NETWORK_INFO" | cut -d'|' -f3)
            speed_info=$(echo "$NETWORK_INFO" | cut -d'|' -f4)
            mac_addr=$(echo "$NETWORK_INFO" | cut -d'|' -f5)

            tooltip="<b>${iface_type}</b>

<span font='10'>Down      : [${down_graph}] ${down_speed}</span>
<span font='10'>Up        : [${up_graph}] ${up_speed}</span>

<span font='10'>Interface : ${interface}</span>
<span font='10'>IP        : ${ip_addr}</span>
<span font='10'>Link      : ${speed_info}</span>
<span font='10'>MAC       : ${mac_addr}</span>"
        else
            down_display=$(make_display_bar 0)
            up_display=$(make_display_bar 0)
        text="<span font='6'> </span><span font='6'>${down_display}</span>
<span font='6'> </span><span font='6'>${up_display}</span>"
            NETWORK_INFO=$(get_network_info)
            interface=$(echo "$NETWORK_INFO" | cut -d'|' -f1)
            iface_type=$(echo "$NETWORK_INFO" | cut -d'|' -f2)
            ip_addr=$(echo "$NETWORK_INFO" | cut -d'|' -f3)
            speed_info=$(echo "$NETWORK_INFO" | cut -d'|' -f4)
            mac_addr=$(echo "$NETWORK_INFO" | cut -d'|' -f5)
            tooltip="<b>${iface_type}</b>

Interface: ${interface}
IP: ${ip_addr}
Link: ${speed_info}
MAC: ${mac_addr}"
        fi
    else
        down_display=$(make_display_bar 0)
        up_display=$(make_display_bar 0)
    text="<span font='6'> </span><span font='6'>${down_display}</span>
<span font='6'> </span><span font='6'>${up_display}</span>"
        NETWORK_INFO=$(get_network_info)
        interface=$(echo "$NETWORK_INFO" | cut -d'|' -f1)
        iface_type=$(echo "$NETWORK_INFO" | cut -d'|' -f2)
        ip_addr=$(echo "$NETWORK_INFO" | cut -d'|' -f3)
        speed_info=$(echo "$NETWORK_INFO" | cut -d'|' -f4)
        mac_addr=$(echo "$NETWORK_INFO" | cut -d'|' -f5)
        tooltip="<b>${iface_type}</b>

Interface: ${interface}
IP: ${ip_addr}
Link: ${speed_info}
MAC: ${mac_addr}"
    fi
else
    down_display=$(make_display_bar 0)
    up_display=$(make_display_bar 0)
    text="<span font='6'></span> <span font='6'> ${down_display}</span><span font='6'> </span> <span font='6'> ${up_display}</span>"
    NETWORK_INFO=$(get_network_info)
    interface=$(echo "$NETWORK_INFO" | cut -d'|' -f1)
    iface_type=$(echo "$NETWORK_INFO" | cut -d'|' -f2)
    ip_addr=$(echo "$NETWORK_INFO" | cut -d'|' -f3)
    speed_info=$(echo "$NETWORK_INFO" | cut -d'|' -f4)
    mac_addr=$(echo "$NETWORK_INFO" | cut -d'|' -f5)
    tooltip="<b>${iface_type}</b>

Interface: ${interface}
IP: ${ip_addr}
Link: ${speed_info}
MAC: ${mac_addr}"
fi

echo "$NOW" > "$STATS_FILE"
echo "$total_rx|$total_tx" >> "$STATS_FILE"

jq -c -n --arg text "$text" --arg tooltip "$tooltip" \
  '{text:$text, tooltip:$tooltip}'
