#!/system/bin/sh
# 88x2bu loader for Realme C51 (RMX3834). Root required.
# Usage:
#   su -c 'sh install.sh /data/local/tmp/88x2bu/88x2bu-5.4.233.ko'
# If no path is given, it picks the module next to this script (5.4.254).

set -u

DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
KO="${1:-$DIR/88x2bu-device.ko}"

[ -f "$KO" ] || { echo "module not found: $KO"; exit 1; }

echo "[*] running kernel : $(uname -r)"
echo "[*] module         : $KO"
echo -n "[*] module vermagic: "; grep -a -o 'vermagic=[^[:cntrl:]]*' "$KO" | head -1
echo -n "[*] module signer  : "; grep -a -o 'signer=[^[:cntrl:]]*' "$KO" | head -1

# Unload a previous instance so insmod does not fail with EEXIST.
if rmmod 88x2bu 2>/dev/null; then
    echo "[*] previous 88x2bu unloaded"
fi

echo "[*] insmod ..."
if ! insmod "$KO"; then
    echo "[!] insmod failed (see dmesg below)"
fi
sleep 3

echo "[*] dmesg:"
dmesg 2>/dev/null | grep -iE '88x2bu|rtl8822|version magic|disagrees|Unknown symbol|firmware|cfg80211' | tail -50

echo "[*] interfaces:"
ip link 2>/dev/null | grep -iE 'wlan|wlx' || ifconfig -a 2>/dev/null | grep -iE 'wlan|wlx'

echo
echo "[*] next: iw dev ; iw phy | grep -i monitor"
