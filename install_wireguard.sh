#!/bin/bash

# Log all output to a file for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update and install WireGuard
apt-get update
apt-get upgrade -y
apt-get install -y wireguard

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Create WireGuard directory
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

# Generate server keys
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
chmod 600 /etc/wireguard/server_private.key

# Get server private key
SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server_private.key)

# Create a basic server configuration file
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = ${SERVER_PRIVATE_KEY}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens5 -j MASQUERADE

# --- ADD YOUR PEERS (Clients) BELOW ---
#
# [Peer] # Jellyfin PC
# PublicKey = <PASTE_JELLYFIN_PC_PUBLIC_KEY_HERE>
# AllowedIPs = 10.8.0.2/32
#
# [Peer] # Remote Device
# PublicKey = <PASTE_REMOTE_DEVICE_PUBLIC_KEY_HERE>
# AllowedIPs = 10.8.0.3/32

EOF

# Enable the WireGuard service to start on boot
systemctl enable wg-quick@wg0

echo "WireGuard installation and initial configuration complete."