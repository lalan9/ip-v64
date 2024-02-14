#!/bin/bash

export LC_ALL=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    sudoCmd="sudo"
else
    sudoCmd=""
fi

# 字体颜色设置
red(){
    echo -e "\033[31m$1\033[0m"
}
green(){
    echo -e "\033[32m$1\033[0m"
}
yellow(){
    echo -e "\033[33m$1\033[0m"
}
blue(){
    echo -e "\033[36m$1\033[0m"
}

Green_font_prefix="\033[32m" 
Red_font_prefix="\033[31m" 
Green_background_prefix="\033[42;37m" 
Red_background_prefix="\033[41;37m" 
Font_color_suffix="\033[0m"

osInfo=""
osRelease=""
osReleaseVersion=""
osReleaseVersionNo=""
osReleaseVersionCodeName="CodeName"
osSystemPackage=""
osSystemMdPath=""
osSystemShell="bash"

osKernelVersionFull=$(uname -r)
osKernelVersionBackup=$(uname -r | awk -F "-" '{print $1}')
osKernelVersionShort=$(uname -r | cut -d- -f1 | awk -F "." '{print $1"."$2}')
osKernelBBRStatus=""
systemBBRRunningStatus="no"
systemBBRRunningStatusText=""

# 检测系统版本号
getLinuxOSVersion(){
    if [[ -s /etc/redhat-release ]]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/issue)
    fi

    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        osInfo=$NAME
        osReleaseVersionNo=$VERSION_ID

        if [ -n $VERSION_CODENAME ]; then
            osReleaseVersionCodeName=$VERSION_CODENAME
        fi
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        osInfo=$(lsb_release -si)
        osReleaseVersionNo=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        osInfo=$DISTRIB_ID
        
        osReleaseVersionNo=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        osInfo=Debian
        osReleaseVersion=$(cat /etc/debian_version)
        osReleaseVersionNo=$(sed 's/\..*//' /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        osInfo=$(uname -s)
        osReleaseVersionNo=$(uname -r)
    fi
}


# 检测系统发行版代号
function getLinuxOSRelease(){
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /etc/issue | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /proc/version | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    fi

    getLinuxOSVersion
}

# Check if the system is running a virtual environment
virt_check(){
    virtualx=$(dmesg) 2>/dev/null

    if  [ $(which dmidecode) ]; then
        sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
        sys_product=$(dmidecode -s system-product-name) 2>/dev/null
        sys_ver=$(dmidecode -s system-version) 2>/dev/null
    else
        sys_manu=""
        sys_product=""
        sys_ver=""
    fi
    
    if grep docker /proc/1/cgroup -qa; then
        virtual="Docker"
    elif grep lxc /proc/1/cgroup -qa; then
        virtual="Lxc"
    elif grep -qa container=lxc /proc/1/environ; then
        virtual="Lxc"
    elif [[ -f /proc/user_beancounters ]]; then
        virtual="OpenVZ"
    elif [[ "$virtualx" == *kvm-clock* ]]; then
        virtual="KVM"
    elif [[ "$cname" == *KVM* ]]; then
        virtual="KVM"
    elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
        virtual="VMware"
    elif [[ "$virtualx" == *"VirtualBox"* ]]; then
        virtual="VirtualBox"
    elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
        virtual="Parallels"
    elif [[ "$sys_manu" == *"Microsoft Corporation"* ]] && [[ "$sys_product" == *"Virtual Machine"* ]]; then
        virtual="HyperV"
    else
        virtual="None"
    fi
}

# 检查是否支持ipv6
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
}

# 检查是否支持TCP BBR
checkBBRStatus(){
    systemBBRRunningStatus=$(lsmod | grep "tcp_bbr")
    if [[ "$systemBBRRunningStatus" == "" ]]; then
        systemBBRRunningStatus="no"
        systemBBRRunningStatusText=$(red "未启动")
    else
        systemBBRRunningStatus="yes"
        systemBBRRunningStatusText=$(green "已启动")
    fi

    if [[ -e /etc/sysctl.d/tcp_bbr.conf ]]; then
        osKernelBBRStatus=$(cat /etc/sysctl.d/tcp_bbr.conf | grep "net.core.default_qdisc" | awk -F "=" '{print $2}')
    else
        osKernelBBRStatus=""
    fi
}

# 设置TCP BBR
enableBBR(){
    checkBBRStatus
    if [[ "$systemBBRRunningStatus" == "yes" ]]; then
        echo -e "TCP BBR已经启动，无需重复操作！"
        return
    fi

    echo -e "启动 TCP BBR..."

    if [[ "$osRelease" == "centos" ]]; then
        if [[ "$osReleaseVersionNo" -ge "7" ]]; then
            if [[ "$osKernelVersionShort" = "4.9" || "$osKernelVersionShort" = "4.10" || "$osKernelVersionShort" = "4.11" || "$osKernelVersionShort" = "4.12" || "$osKernelVersionShort" = "4.13" || "$osKernelVersionShort" = "4.14" || "$osKernelVersionShort" = "4.15" || "$osKernelVersionShort" = "4.16" || "$osKernelVersionShort" = "4.17" || "$osKernelVersionShort" = "4.18" || "$osKernelVersionShort" = "4.19" || "$osKernelVersionShort" = "4.20" || "$osKernelVersionShort" = "5.0" || "$osKernelVersionShort" = "5.1" || "$osKernelVersionShort" = "5.2" || "$osKernelVersionShort" = "5.3" || "$osKernelVersionShort" = "5.4" || "$osKernelVersionShort" = "5.5" || "$osKernelVersionShort" = "5.6" || "$osKernelVersionShort" = "5.7" || "$osKernelVersionShort" = "5.8" || "$osKernelVersionShort" = "5.9" || "$osKernelVersionShort" = "5.10" || "$osKernelVersionShort" = "5.11" || "$osKernelVersionShort" = "5.12" || "$osKernelVersionShort" = "5.13" || "$osKernelVersionShort" = "5.14" || "$osKernelVersionShort" = "5.15" || "$osKernelVersionShort" = "5.16" ]]; then
                echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/tcp_bbr.conf
                echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/tcp_bbr.conf
                sysctl -p
            else
                echo -e "${Red_font_prefix}您的内核版本为[$osKernelVersionFull]，不支持TCP BBR，请更换内核版本！${Font_color_suffix}"
                return
            fi
        else
            echo -e "${Red_font_prefix}您的系统版本为[$osReleaseVersionNo]，不支持TCP BBR，请更换系统版本！${Font_color_suffix}"
            return
        fi
    elif [[ "$osRelease" == "ubuntu" || "$osRelease" == "debian" ]]; then
        if [[ "$osKernelVersionShort" = "4.9" || "$osKernelVersionShort" = "4.10" || "$osKernelVersionShort" = "4.11" || "$osKernelVersionShort" = "4.12" || "$osKernelVersionShort" = "4.13" || "$osKernelVersionShort" = "4.14" || "$osKernelVersionShort" = "4.15" || "$osKernelVersionShort" = "4.16" || "$osKernelVersionShort" = "4.17" || "$osKernelVersionShort" = "4.18" || "$osKernelVersionShort" = "4.19" || "$osKernelVersionShort" = "4.20" || "$osKernelVersionShort" = "5.0" || "$osKernelVersionShort" = "5.1" || "$osKernelVersionShort" = "5.2" || "$osKernelVersionShort" = "5.3" || "$osKernelVersionShort" = "5.4" || "$osKernelVersionShort" = "5.5" || "$osKernelVersionShort" = "5.6" || "$osKernelVersionShort" = "5.7" || "$osKernelVersionShort" = "5.8" || "$osKernelVersionShort" = "5.9" || "$osKernelVersionShort" = "5.10" || "$osKernelVersionShort" = "5.11" || "$osKernelVersionShort" = "5.12" || "$osKernelVersionShort" = "5.13" || "$osKernelVersionShort" = "5.14" || "$osKernelVersionShort" = "5.15" || "$osKernelVersionShort" = "5.16" ]]; then
                echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/tcp_bbr.conf
                echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/tcp_bbr.conf
                sysctl -p
            else
                echo -e "${Red_font_prefix}您的内核版本为[$osKernelVersionFull]，不支持TCP BBR，请更换内核版本！${Font_color_suffix}"
                return
            fi
    fi

    checkBBRStatus
    if [[ "$systemBBRRunningStatus" == "yes" ]]; then
        echo -e "TCP BBR启动成功！"
    else
        echo -e "TCP BBR启动失败！"
    fi
}

main(){
    getLinuxOSRelease
    virt_check
    checkIPV6
    checkBBRStatus

    echo -e "系统信息:"
    echo -e "------------------------------------------"
    echo -e "操作系统           : ${osInfo}"
    echo -e "系统版本           : ${osReleaseVersion} (${osReleaseVersionCodeName})"
    echo -e "内核版本           : ${osKernelVersionFull}"
    echo -e "虚拟化             : ${virtual}"
    echo -e "------------------------------------------"
    echo -e "TCP BBR            : ${systemBBRRunningStatusText}"
    echo -e "------------------------------------------"
    echo -e "注: TCP BBR 开启后，重启系统即可生效"
}

main
