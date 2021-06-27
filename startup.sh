#!/bin/bash

HOSTNAME="firecracker"
hostnamectl set-hostname $HOSTNAME

# Get firecracker
cd /root
release_url="https://github.com/firecracker-microvm/firecracker/releases"
latest=$(basename $(curl -fsSLI -o /dev/null -w  %{url_effective} ${release_url}/latest))
arch=`uname -m`
curl -L ${release_url}/download/${latest}/firecracker-${latest}-${arch}.tgz | tar -xz &>/dev/null &&
cd release-${latest} &&
mv firecracker-${latest}-$(uname -m) /usr/local/sbin/firecracker

# Post-setup firecracker
fc_dir="/var/lib/firecracker"
mkdir -p $fc_dir

# -----------------------------------------------------------------

# Forward all
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# VM network
  # Create 10 TAP interfaces
for tap in tap{1..10}; do
    ip link del $tap 2> /dev/null || true
    ip tuntap add dev $tap mode tap
    sysctl -w net.ipv4.conf.$tap.proxy_arp=1 > /dev/null
    sysctl -w net.ipv6.conf.$tap.disable_ipv6=1 > /dev/null
    ip link set dev $tap up
done
  # Setup bridge
cat <<EOF > /etc/netplan/bridge.yaml
---
network:
    version: 2
    renderer: networkd
    ethernets:
      taps:
        match: { name: "tap*" }
    bridges:
        vbridge:
            addresses: [ "192.168.228.1/24" ]
            dhcp4: no
            dhcp6: no
            interfaces: [taps]
EOF

netplan apply
iptables -t nat -A POSTROUTING -s 192.168.228.0/24 -o eth0 -j MASQUERADE

  # Setup DHCP
apt-get install -y dnsmasq-base
mkdir -p $fc_dir/dnsmasq
cat <<EOF > $fc_dir/dnsmasq/firecracker.conf
strict-order
pid-file=/var/run/dnsmasq/firecracker.pid
except-interface=lo
bind-dynamic
interface=vbridge
server=208.67.222.222
server=208.67.220.220
dhcp-range=192.168.228.100,192.168.228.200,255.255.255.0
dhcp-option=option:router,192.168.228.1
dhcp-option=option:dns-server,192.168.228.1
dhcp-no-override
dhcp-authoritative
dhcp-lease-max=254
dhcp-hostsfile=${fc_dir}/dnsmasq/fc.hostsfile
addn-hosts=${fc_dir}/dnsmasq/fc.addnhosts
EOF

dnsmasq --conf-file=$fc_dir/dnsmasq/firecracker.conf --leasefile-ro &
# -----------------------------------------------------------------

# Setup instances
mkdir -p $fc_dir/instances/instance0
cd $fc_dir/instances/instance0

set -eu
# download a kernel and filesystem image
[ -e hello-vmlinux.bin ] || wget https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin
[ -e hello-rootfs.ext4 ] || wget -O hello-rootfs.ext4 https://raw.githubusercontent.com/firecracker-microvm/firecracker-demo/main/xenial.rootfs.ext4

KERNEL_BOOT_ARGS="ro console=ttyS0 noapic reboot=k panic=1 pci=off nomodules random.trust_cpu=on ip=dhcp"
# make a configuration file
cat <<EOF > vmconfig.json
{
  "boot-source": {
    "kernel_image_path": "hello-vmlinux.bin",
    "boot_args": "$KERNEL_BOOT_ARGS"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "hello-rootfs.ext4",
      "is_root_device": true,
      "is_read_only": false
    }
  ],
  "network-interfaces": [
      {
          "iface_id": "eth0",
          "host_dev_name": "tap0"
      }
  ],
  "machine-config": {
    "vcpu_count": 1,
    "mem_size_mib": 512,
    "ht_enabled": false
  }
}
EOF

# start firecracker
#firecracker --no-api --config-file vmconfig.json
