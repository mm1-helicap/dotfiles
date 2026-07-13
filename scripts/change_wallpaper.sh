#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers/walls"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: Directory $WALLPAPER_DIR does not exist"
    exit 1
fi

WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) | shuf -n 1)

if [ -z "$WALLPAPER" ]; then
    echo "Error: No image files found in $WALLPAPER_DIR"
    exit 1
fi

if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER"
    echo "Wallpaper changed to: $WALLPAPER"
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (i=0;i<allDesktops.length;i++) {
            d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
            d.writeConfig('Image', 'file://$WALLPAPER');
        }
    "
    echo "Wallpaper changed to: $WALLPAPER"
elif [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER"
    echo "Wallpaper changed to: $WALLPAPER"
else
    if command -v feh &> /dev/null; then
        feh --bg-fill "$WALLPAPER"
        echo "Wallpaper changed to: $WALLPAPER"
    else
        echo "Error: Could not detect desktop environment. Please install 'feh' or set wallpaper manually."
        echo "Selected wallpaper: $WALLPAPER"
        exit 1
    fi
fi
