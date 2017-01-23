#!/usr/bin/env bash

set_hostname() {
    default_iface=$(awk '$2 == 00000000 { print $1   }' /proc/net/route | uniq)
    
    printf "Default interface: ${default_iface}\n"
    default_iface=`echo ${default_iface} | awk '{ print $1  }'`
    mac_addr=`ip addr show dev ${default_iface} | awk '$1 ~ /^link\// { print $2  }'`
    
    printf "Interface: ${default_iface} MAC address: ${mac_addr}\n"
    
    hostname_str=${mac_addr//:/-}
    echo ${hostname_str} >/etc/hostname
}

set_docker() {
    # For install multi-kernel, set the first line kernel in grub list as default to boot
    grub2-set-default 0
    # load overlay for docker storage driver
    echo "overlay" > /etc/modules-load.d/overlay.conf
    # set overaly as docker storage driver instead of devicemapper (the default one on centos)
    sed -i -e '/^ExecStart=/ s/$/ --storage-driver=overlay/' /usr/lib/systemd/system/docker.service

    # Explicit Docker option
    sed -i -e '/^ExecStart=/ s/$/ $DOCKER_OPT_BIP $DOCKER_OPT_IPMASQ $DOCKER_OPT_MTU $DOCKER_NETWORK_OPTIONS/' /usr/lib/systemd/system/docker.service
}

set_ssh_config() {
    mkdir -p /root/.ssh
    chomd 700 /root/.ssh
    cat > /root/.ssh/config <<EOF
Host *
GSSAPIAuthentication no
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null

    EOF

    chomd 600 /root/.ssh/config

}

set_hostname
set_docker
set_ssh_config

