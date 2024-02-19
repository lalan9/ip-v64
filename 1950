#!/bin/bash  
  
# 添加用户1950  
useradd 1950  
  
# 为用户1950设置密码  
echo "1950:ATJd3MwwUDbjwFgUJe3ooY3KiuL7sDWMYYd" | chpasswd  
  
# 为1950用户添加sudo权限，允许其无需密码切换到root  
echo "1950 ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers  
  
# 刷新sudo权限，使更改生效  
visudo -c  
  
echo "用户1950已添加，并已设置密码和sudo权限。"
