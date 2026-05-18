# My Vertical Waybar Themes

Hey there! Welcome to my little collection of Waybar configurations. These are my custom vertical waybar themes that I've been hacking away at and having fun customizing. Hope you enjoy them as much as I do!

Big thanks to these awesome folks for the inspiration and base configs:
- [HANCORE-linux/waybar-themes](https://github.com/HANCORE-linux/waybar-themes) - The OG Omarchy-based themes that started it all
- [atif-1402/minimal-waybar-themes](https://github.com/atif-1402/minimal-waybar-themes) - Minimal and clean vibes

---

## Previews

| v1 | v2 | v3 | v4 |
|---|---|---|---|
| ![Preview](adna_waybar_v1/preview_adna_waybar_v1.png) | ![Preview](adna_waybar_v2/preview_adna_waybar_v2.png) | ![Preview](adna_waybar_v3/preview_adna_waybar_v3.png) | ![Preview](adna_waybar_v4/preview_adna_waybar_v4.png) |

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/fross100/waybar-configs.git ~/waybar-configs
cd ~/waybar-configs
```

### 2. Install the Desired Version

Copy the desired version folder to your Waybar config directory:

```bash
cp -r adna_waybar_vX ~/.config/waybar/
```

### 3. For adna_waybar_v2, v3, v4 (Custom Font Required)

These versions use a custom font `omavy.ttf`:

**User install:**
```bash
mkdir -p ~/.local/share/fonts
cp omavy.ttf ~/.local/share/fonts/
fc-cache -f -v
```

**System-wide install:**
```bash
sudo cp omavy.ttf /usr/share/fonts/
sudo fc-cache -f -v
```

### 4. Make Scripts Executable

```bash
chmod +x adna_waybar_vX/scripts/*.sh
```

---

## Reset to Default Omarchy Style

Want to go back to the original Omarchy Waybar? No problem! Here's how:

### Method 1: Omarchy Menu (Recommended)

1. Open the Omarchy Menu: Press **Super + Alt + Space**
2. Select **Update**
3. Select **Config**
4. Select **Waybar**

This will:
- Reset `~/.config/waybar` to the stock Omarchy version
- Backup your current config (e.g. `config.bak`, `style.css.bak`)
- Reload Waybar automatically

---

Enjoy your new waybar! Feel free to tweak and break things - that's the fun part! 🛠️
