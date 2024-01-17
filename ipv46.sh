#!/bin/bash

# 获取IPv4地址
ipv4=$(curl -s https://ipinfo.io/ip)

# 获取IPv6地址
ipv6=$(curl -s https://ipinfo.io/ip6)

# 显示结果
echo "IPv4地址: $ipv4"
echo "IPv6地址: $ipv6"
