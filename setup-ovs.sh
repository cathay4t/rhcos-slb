#!/usr/bin/env bash

set -ex

if [[ ! -f /boot/mac_addresses ]] ; then
  echo "no mac address configuration file found .. exiting"
  exit 1
fi

echo "configure ovs bonding"
primary_mac=$(cat /boot/mac_addresses | \
  awk -F= '/PRIMARY_MAC/ {print toupper($2)}')
secondary_mac=$(cat /boot/mac_addresses | \
  awk -F= '/SECONDARY_MAC/ {print toupper($2)}')

echo "---
capture:
  primary_port: interfaces.permanent-mac-address==\"$primary_mac\"
  secondary_port: interfaces.permanent-mac-address==\"$secondary_mac\"
desired:
  interfaces:
  - name: brcnv
    type: ovs-interface
    copy-mac-from: \"{{ capture.primary_port.interfaces.0.name }}\"
    ipv4:
      enabled: true
      dhcp: true
  - name: brcnv
    type: ovs-bridge
    state: up
    bridge:
      port:
      - name: brcnv
      - name: bond0
        link-aggregation:
          mode: balance-slb
          port:
            - name: \"{{ capture.primary_port.interfaces.0.name }}\"
            - name: \"{{ capture.secondary_port.interfaces.0.name }}\"
" | nmstatectl apply -
