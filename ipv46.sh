#!/bin/bash

# 获取所有IPv4地址
ipv4_list=$(curl -s https://ipinfo.io/ip)

# 获取IPv6地址
ipv6=$(ip -6 addr show scope global | grep inet6 | awk '{print $2}' | cut -d '/' -f 1)

# 显示结果
echo "IPv4地址列表:"
echo "$ipv4_list"
echo "IPv6地址: $ipv6"
