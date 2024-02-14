#!/bin/bash

# 检查是否支持IPv6并设置为默认优先
checkIPV6(){
    echo -e "检查是否支持IPv6..."
    if [[ -f /proc/net/if_inet6 ]]; then
        echo -e "IPv6已开启"
    else
        echo -e "IPv6未开启，正在尝试开启IPv6..."
        modprobe ipv6
        echo "ipv6" >> /etc/modules-load.d/modules.conf
        echo "net.ipv6.conf.all.disable_ipv6 = 0" >> /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 0" >> /etc/sysctl.conf
        echo "net.ipv6.conf.lo.disable_ipv6 = 0" >> /etc/sysctl.conf
        sysctl -p
        echo -e "IPv6开启成功！"
    fi

    # 设置IPv6优先级
    echo -e "设置IPv6为默认优先..."
    echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
}

main(){
    # 导出环境变量
    export LC_ALL=C
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US.UTF-8

    # 检查是否为root用户
    if [[ $(/usr/bin/id -u) -ne 0 ]]; then
        sudoCmd="sudo"
    else
        sudoCmd=""
    fi

    # 检查是否支持并设置IPv6优先
    checkIPV6

    # 其他功能
}

main
