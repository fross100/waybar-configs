# Waybar Configurations

Collection of 4 Waybar configurations with different styles.

## Previews

### adna_waybar_v1
![Preview](preview_adna_waybar_v1.png)

### adna_waybar_v2
![Preview](preview_adna_waybar_v2.png)

### adna_waybar_v3
![Preview](preview_adna_waybar_v3.png)

### adna_waybar_v4
![Preview](preview_adna_waybar_v4.png)

## Installation

### For All Versions
1. Copy the desired version folder to your Waybar config directory:
   ```bash
   cp -r adna_waybar_vX ~/.config/waybar/
   ```

2. Update your Waybar config path in your startup script if needed

### For adna_waybar_v2, v3, v4 (Custom Font Required)

These versions require the custom font `omavy.ttf` to be installed:

1. Copy the font to your fonts directory:
   ```bash
   cp omavy.ttf ~/.local/share/fonts/
   ```

2. Refresh fonts:
   ```bash
   fc-cache -f -v
   ```

3. Alternatively, you can install system-wide:
   ```bash
   sudo cp omavy.ttf /usr/share/fonts/
   sudo fc-cache -f -v
   ```

### Custom Scripts

Some modules require custom scripts. The scripts are included in each version's `scripts/` folder. Make sure they are executable:
```bash
chmod +x scripts/*.sh
```