#!/bin/bash

# 检查当前用户是否为 root
if [ "$(id -u)" != "0" ]; then
    echo "错误：请使用 root 权限运行该脚本" 1>&2
    exit 1
fi

# 定义要创建的用户名和密码
new_username="user1950"
new_password="ATJd3MwwUDbjwFgUJe3666"

# 创建用户
useradd $new_username

# 设置用户密码
echo "$new_username:$new_password" | chpasswd

# 将用户添加到 sudoers 文件以赋予 root 权限
echo "$new_username ALL=(ALL) ALL" >> /etc/sudoers

echo "用户 $new_username 创建成功，并且已赋予 root 权限。"
