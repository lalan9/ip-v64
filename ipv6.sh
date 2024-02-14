#!/bin/bash

# Function to check if IPv6 is enabled
ipv6_enabled() {
    if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6)" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to get the IPv6 gateway address
get_ipv6_gateway() {
    ip -6 route show default | awk '/via/ {print $3}'
}

# Function to set the default IPv6 route
set_ipv6_route() {
    gateway="$1"
    ip -6 route add default via "$gateway" dev "$(ip -6 route show default | awk '/via/ {print $5}')" metric 1024
}

# Main script
if ipv6_enabled; then
    ipv6_gateway=$(get_ipv6_gateway)
    if [ -n "$ipv6_gateway" ]; then
        echo "IPv6 is enabled, using gateway: $ipv6_gateway"
        set_ipv6_route "$ipv6_gateway"
    else
        echo "Failed to obtain IPv6 gateway address."
    fi
else
    echo "IPv6 is not enabled."
fi
