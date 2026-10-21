# WPS troubleshooting on Termux (RTL8822BU)

## Environment
- Device: Realme C51 (Android 12/14, kernel 5.4.254, aarch64)
- Adapter: TP-Link Archer T3U Plus, RTL8822BU, USB ID 2357:012e
- Driver: rtw88 (rtw_core, rtw_8822b, rtw_usb, rtw_8822bu)
- Tools: Termux, root via Magisk, reaver/wash from source, airgeddon

## Known issue: USB reset during reaver

Symptom:
- dmesg shows: usb 1-1: reset high-speed USB device number 3 using musb-hdrc
- dmesg shows: rtw_8822bu 1-1:1.0: failed to get tx report from firmware
- wlan1 goes back to managed mode
- reaver exits with: pcap_activate status -9 - That device is not up

Cause:
- reaver's pcap_sleep() closed the pcap handle, slept, then reopened it.
- On RTL8822BU this close/open sequence could trigger USB reset and driver reload.

Fix (patch src/misc.c):
- Replace pcap_sleep() body with a simple sleep, without pcap_close/capture_init.
- Rebuild and reinstall reaver. Keep the pcap handle open across retry delays.

Verification:
- Run reaver for at least 90 seconds against an authorized AP.
- No pcap_activate error should appear.
- Check dmesg for "usb 1-1: reset" during the run.

## Known issue: airgeddon regex error on pixiedust

Symptom:
- airgeddon WPS attack log repeats:
  [[: invalid regular expression .*?\[\+\][[:space:]]WPA[[:space:]]PSK:[[:space:]]'(.*)''
  repetition-operator operand invalid

Cause:
- Bash [[ =~ ]] uses POSIX ERE and does not support lazy quantifier .*?

Fix:
- In ~/airgeddon/airgeddon.sh find:
  success_attack_goodpixie_password_regexp=".*?\[\+\][[:space:]]WPA[[:space:]]PSK:[[:space:]]'(.*)'"
- Replace with:
  success_attack_goodpixie_password_regexp=".*\[\+\][[:space:]]WPA[[:space:]]PSK:[[:space:]]'(.*)'"
- Also patch the generated script in $PREFIX/tmp/ag*/ag.wpsattack.sh if it already exists.

Verification:
- bash -n $PREFIX/tmp/ag*/ag.wpsattack.sh should pass.
- Test regex: item="[+] WPA PSK: 'test'" should capture "test".

## Useful commands

Interface and monitor mode:
    iw dev
    iw dev wlan1 info
    ip link set wlan1 down
    iw dev wlan1 set type monitor
    ip link set wlan1 up
    iw dev wlan1 set channel 4

WPS scan:
    wash -i wlan1 -c 4 -a --scan

Pixie Dust attempt:
    reaver -i wlan1 -b <BSSID> -c <CH> -K 1 -N -vvv

Normal PIN attempt:
    reaver -i wlan1 -b <BSSID> -c <CH> -N -d 2 -vvv

Check locks:
    wash -i wlan1 -c <CH> -a --scan

## Limitations

- USB adapter may still reset under long monitor/injection load; use a powered USB hub for stability.
- Some APs (Keenetic, TP-Link Archer AX12 with WPS 2.0) reject or rate-limit WPS PIN and Pixie Dust.
  Reaver messages: "WPS pin not found", "Detected AP rate limiting, waiting 60 seconds".
  This is AP-side protection, not a driver bug.
- Pixie Dust works only on vulnerable WPS implementations.

## Safety

Use only on networks you own or are explicitly authorized to test.
WPS attacks can lock the AP and disrupt clients.
