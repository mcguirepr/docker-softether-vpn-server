#!/bin/sh

set -e

if [ -z "$SET_DNS_TO_CONTAINER" ]; then
    echo "SET_DNS_TO_CONTAINER not set."
else 
    #get dns server ip
    dnsserver=$(ping -c 1 $SET_DNS_TO_CONTAINER | awk -F'[()]' '/PING/{print $2}')
    #set all nameservers to 
    if [ -z "$dnsserver" ]; then
        echo "Couldn't find dns server IP address"
    else
        echo "Previous nameserver settings"
        cat /etc/resolv.conf
        echo "Setting DNS Server To $SET_DNS_TO_CONTAINER which is at $dnsserver"
        #echo "nameserver $dnsserver" >> /etc/resolv.conf
        sed "s/nameserver.*/nameserver $dnsserver/" /etc/resolv.conf > /tmp/resolv.conf.new 
        cat /tmp/resolv.conf.new > /etc/resolv.conf
        echo "New nameserver settings"
        cat /etc/resolv.conf
    fi
fi

if [ "x$1" = 'x/usr/vpnserver/vpnserver' ]; then

    # Linking Logs
    for d in server_log security_log packet_log;
    do
        if [ ! -L /usr/vpnserver/$d ]; then
          mkdir -p /var/log/vpnserver/$d
          ln -s /var/log/vpnserver/$d /usr/vpnserver/$d
        fi
    done

    # Allow app to use ports < 1024 without root
    chown -R softether:softether /usr/vpnserver
    setcap 'cap_net_bind_service=+ep' /usr/vpnserver/vpnserver

    # Starting
    echo "Starting SoftEther VPN Server"
    exec su-exec softether sh -c "`echo $@`"
else
    exec "$@"
fi
