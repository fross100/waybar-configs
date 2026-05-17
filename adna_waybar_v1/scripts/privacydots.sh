#!/usr/bin/env bash
# privacy dots for Waybar
# mic:  green, cam: orange, location: blue

set -euo pipefail

# Dependencies: pipewire (pw-dump), jq, dbus-send (dbus)
JQ_BIN="${JQ:-jq}"
PW_DUMP_CMD="${PW_DUMP:-pw-dump}"
DBUS_SEND="${DBUS_SEND:-dbus-send}"

mic=0
cam=0
loc=0

# mic & camera
if command -v "$PW_DUMP_CMD" >/dev/null 2>&1 && command -v "$JQ_BIN" >/dev/null 2>&1; then
  dump="$($PW_DUMP_CMD 2>/dev/null || true)"

  mic="$(
    printf '%s' "$dump" \
    | $JQ_BIN -r '
      [ .[]
        | select(.type=="PipeWire:Interface:Node")
        | select((.info.props."media.class"=="Audio/Source" or .info.props."media.class"=="Audio/Source/Virtual"))
        | select((.info.state=="running") or (.state=="running"))
      ] | (if length>0 then 1 else 0 end)
    ' 2>/dev/null || echo 0
  )"

  cam="$(
    printf '%s' "$dump" \
    | $JQ_BIN -r '
      [ .[]
        | select(.type=="PipeWire:Interface:Node")
        | select(.info.props."media.class"=="Video/Source")
        | select((.info.state=="running") or (.state=="running"))
      ] | (if length>0 then 1 else 0 end)
    ' 2>/dev/null || echo 0
  )"
fi

# location
# add location here

# Colors
green="#30D158"   # mic
orange="#FF9F0A"  # cam
blue="#0A84FF"    # location
grey="#555555"    # off

# Fungsi dot yang diperbaiki: kembalikan string kosong jika sensor off
dot() {
  local on="$1" color="$2"
  if [[ "$on" -eq 1 ]]; then
    printf '<span foreground="%s">●</span>' "$color"
  else
    # Jangan kembalikan apa pun jika off
    printf ""
  fi
}

# Hitung total sensor aktif
total_active=$((mic + cam + loc))

# JIKA tidak ada yang aktif, BERHENTI dan jangan beri output apa pun
if [[ $total_active -eq 0 ]]; then
    exit 0
fi

# Jika ada yang aktif, buat string teks (hanya yang aktif yang muncul)
# Gunakan array atau handle spasi agar tidak berantakan
text=""
[[ $mic -eq 1 ]] && text+="$(dot "$mic" "$green")"
[[ $cam -eq 1 ]] && { [[ -n $text ]] && text+="<br>"; text+="$(dot "$cam" "$orange")"; }
[[ $loc -eq 1 ]] && { [[ -n $text ]] && text+="<br>"; text+="$(dot "$loc" "$blue")"; }

tooltip="Mic: $([[ $mic -eq 1 ]] && echo on || echo off) | Cam: $([[ $cam -eq 1 ]] && echo on || echo off) | Location: $([[ $loc -eq 1 ]] && echo on || echo off)"

classes="privacydot"
[[ $mic -eq 1 ]] && classes="$classes mic-on"
[[ $cam -eq 1 ]] && classes="$classes cam-on"
[[ $loc -eq 1 ]] && classes="$classes loc-on"

# Fungsi dot yang diperbaiki: kembalikan string kosong jika sensor off
dot() {
  local on="$1" color="$2"
  if [[ "$on" -eq 1 ]]; then
    printf '<span foreground="%s">●</span>' "$color"
  else
    # Jangan kembalikan apa pun jika off
    printf ""
  fi
}

# Jika ada yang aktif, buat string teks (hanya yang aktif yang muncul)
# Gunakan array atau handle spasi agar tidak berantakan
text=""
[[ $mic -eq 1 ]] && text+="$(dot "$mic" "$green")"
[[ $cam -eq 1 ]] && { [[ -n $text ]] && text+="<br>"; text+="$(dot "$cam" "$orange")"; }
[[ $loc -eq 1 ]] && { [[ -n $text ]] && text+="<br>"; text+="$(dot "$loc" "$blue")"; }

# Kirim ke Waybar
jq -c -n --arg text "$text" --arg tooltip "$tooltip" --arg class "$classes" \
  '{text:$text, tooltip:$tooltip, class:$class}'
