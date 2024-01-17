#!/bin/bash

# 获取IPv4地址
ipv4=$(curl -s https://ipinfo.io/ip)

# 获取IPv6地址
ipv6=$(ip -6 addr show scope global | grep inet6 | awk '{print $2}' | cut -d '/' -f 1)

# 显示结果
echo "IPv4地址: $ipv4"
echo "IPv6地址: $ipv6"
