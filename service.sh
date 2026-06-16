#!/system/bin/sh

MODDIR=${0%/*}

# Check and start dnscrypt-proxy if not running
while true; do
  if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
    "$MODDIR/system/bin/dnscrypt-proxy" -config /storage/emulated/0/dnscrypt-proxy/dnscrypt-proxy.toml
  fi
  sleep 15
done
