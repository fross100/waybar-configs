#!/bin/bash

get_net_speed() {
    local interface
    interface=$(ip route | awk '/default/ {print $5; exit}')
    [[ -z "$interface" ]] && echo '{"text": "󰤮", "tooltip": "Disconnected"}' && return

    local state
    state=$(cat /sys/class/net/"$interface"/operstate 2>/dev/null)

    local icon
    case "$state" in
        up)
            if [[ "$interface" == "wl"* ]]; then
                local signal
                signal=$(iw "$interface" link 2>/dev/null | grep signal | awk '{print $2}')
                if [[ -z "$signal" ]] || [[ "$signal" -lt -70 ]]; then
                    icon="󰤯"
                elif [[ "$signal" -lt -60 ]]; then
                    icon="󰤟"
                elif [[ "$signal" -lt -50 ]]; then
                    icon="󰤢"
                else
                    icon="󰤥"
                fi
            else
                icon="󰈀"
            fi
            ;;
        *) icon="󰤮" ;;
    esac

    local rx1 tx1 rx2 tx2
    read -r rx1 tx1 < <(cat /sys/class/net/"$interface"/statistics/{rx,tx}_bytes 2>/dev/null)
    sleep 1
    read -r rx2 tx2 < <(cat /sys/class/net/"$interface"/statistics/{rx,tx}_bytes 2>/dev/null)

    local rx_rate=$(( (rx2 - rx1) / 1024 ))
    local tx_rate=$(( (tx2 - tx1) / 1024 ))

    local rx_unit="KB/s"
    local tx_unit="KB/s"

    if (( rx_rate >= 1024 )); then
        rx_rate=$(( rx_rate / 1024 ))
        rx_unit="MB/s"
    fi

    if (( tx_rate >= 1024 )); then
        tx_rate=$(( tx_rate / 1024 ))
        tx_unit="MB/s"
    fi

    local tooltip="↓${rx_rate}${rx_unit}  ↑${tx_rate}${tx_unit}"

    echo "{\"text\": \"$icon\", \"tooltip\": \"$tooltip\", \"class\": \"$state\"}"
}

get_net_speed
