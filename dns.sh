#!/bin/bash

# Author : MXiDev
# Website : https://mxidev.com

# 函数定义开始

# 获取操作系统名称
get_os_name() {
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
    else
        DISTRO='unknown'
    fi

    if [ "$DISTRO" != 'unknown' ]; then
        echo -e "检测到您的系统为: $DISTRO"
    else
        echo -e "不支持的操作系统，请更换为 CentOS / Debian / Ubuntu 后重试。"
        exit 1
    fi
}

# 捕获用户输入字符
get_char() {
    SAVEDSTTY=$(stty -g)
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty "$SAVEDSTTY"
}

# 欢迎信息和DNS确认
welcome() {
    echo -e '正在检测您的操作系统...'
    get_os_name
    echo -e "您确定要使用下面的DNS地址吗？\n主DNS: $1"
    [ -n "$2" ] && echo -e "备DNS: $2"
    echo -e "\n请按任意键继续，如有配置错误请使用 Ctrl+C 退出。"
    get_char
}

# 修改DNS配置
change_dns() {
    echo -e '\n正在备份当前DNS配置文件...'
    cp /etc/resolv.conf /etc/resolv.conf.backup
    echo -e '备份完成，正在修改DNS配置文件...'
    {
        echo "nameserver $1"
        [ -n "$2" ] && echo "nameserver $2"
    } > /etc/resolv.conf
    echo -e 'DNS配置文件修改完成。\n'
}

# 恢复DNS配置
restore_dns() {
    echo -e '正在恢复默认DNS配置文件...'
    mv /etc/resolv.conf.backup /etc/resolv.conf
    echo -e 'DNS配置文件恢复完成。\n'
}

# 主逻辑开始

if [ "$1" != 'restore' ]; then
    # 检查是否提供了至少一个DNS地址
    if [ -z "$1" ]; then
        echo "用法错误：需要指定至少一个DNS地址或使用 'restore' 选项。"
        exit 1
    fi
    welcome "$1" "$2"
    change_dns "$1" "$2"
else
    restore_dns
fi

echo -e '感谢您的使用, 如果您想恢复备份，请在执行脚本文件时使用参数 restore 。'
