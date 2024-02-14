#!/bin/bash

# 函数：检查IPv6是否已启用
ipv6_enabled() {
    if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6)" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# 函数：获取IPv6网关地址
get_ipv6_gateway() {
    ip -6 route show default | awk '/via/ {print $3}'
}

# 函数：设置默认IPv6路由
set_ipv6_route() {
    gateway="$1"
    ip -6 route add default via "$gateway" dev "$(ip -6 route show default | awk '/via/ {print $5}')"
}

# 主脚本
if ipv6_enabled; then
    ipv6_gateway=$(get_ipv6_gateway)
    if [ -n "$ipv6_gateway" ]; then
        echo "IPv6已启用，正在使用网关地址: $ipv6_gateway"
        set_ipv6_route "$ipv6_gateway"
    else
        echo "无法获取IPv6网关地址."
    fi
else
    echo "IPv6未启用."
fi
