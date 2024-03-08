#!/bin/bash

# 定义颜色输出函数
color_echo() {
    case $1 in
        red) color_code="\033[31m\033[01m";;
        green) color_code="\033[32m\033[01m";;
        yellow) color_code="\033[33m\033[01m";;
        *) color_code="\033[0m";;
    esac
    echo -e "${color_code}$2\033[0m"
}

# 系统检测与软件安装函数
check_and_install() {
    local package_manager=(${@})
    [[ ! -f /etc/ssh/sshd_config ]] && sudo ${package_manager[0]} update && sudo ${package_manager[1]} openssh-server
    [[ -z $(type -P curl) ]] && sudo ${package_manager[0]} update && sudo ${package_manager[1]} curl
}

# 系统检测
detect_system() {
    local sys_info=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
    case "$sys_info" in
        debian|ubuntu) SYSTEM="Debian"; check_and_install "apt" "apt -y install";;
        centos|fedora|rhel) SYSTEM="CentOS"; check_and_install "yum" "yum -y install";;
        *) color_echo red "脚本暂时不支持当前系统，请使用主流操作系统"; exit 1;;
    esac
}

# 输入处理
read_input() {
    read -p "输入设置的SSH端口（默认22）：" sshport
    sshport=${sshport:-22}
    read -p "输入设置的root密码：" password
    password=${password:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13)}
}

# 修改SSH配置并重启服务
configure_ssh() {
    sudo sed -i "/^#\?Port /c\Port $sshport" /etc/ssh/sshd_config
    sudo sed -i "/^#\?PermitRootLogin /c\PermitRootLogin yes" /etc/ssh/sshd_config
    sudo sed -i "/^#\?PasswordAuthentication /c\PasswordAuthentication yes" /etc/ssh/sshd_config
    echo root:$password | sudo chpasswd
    sudo systemctl restart sshd || sudo service ssh restart
}

# 主逻辑
main() {
    detect_system
    read_input
    configure_ssh
    color_echo yellow "VPS root登录信息设置完成！"
    color_echo green "VPS登录端口为：$sshport"
    color_echo green "用户名：root"
    color_echo green "密码：$password"
    color_echo yellow "请妥善保存好登录信息！然后重启VPS确保设置已保存！"
}

main
