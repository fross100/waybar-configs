# Waybar Configurations

Collection of 4 Waybar configurations with different styles.

## Previews

| v1 | v2 | v3 | v4 |
|---|---|---|---|
| ![Preview](preview_adna_waybar_v1.png) | ![Preview](preview_adna_waybar_v2.png) | ![Preview](preview_adna_waybar_v3.png) | ![Preview](preview_adna_waybar_v4.png) |

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

Update your Waybar config path in your startup script if needed.

### 3. For adna_waybar_v2, v3, v4 (Custom Font Required)

These versions require the custom font `omavy.ttf` to be installed:

Copy the font to your fonts directory:
```bash
cp omavy.ttf ~/.local/share/fonts/
fc-cache -f -v
```

Or install system-wide:
```bash
sudo cp omavy.ttf /usr/share/fonts/
sudo fc-cache -f -v
```

### 4. Custom Scripts

Make sure scripts are executable:
```bash
chmod +x adna_waybar_vX/scripts/*.sh
```