#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Lỗi: ${plain} Bắt đầu lại với quyền root！\n" && exit 1

if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}System version not detected, please contact the author!${plain}\n" && exit 1
fi

install() {
    if [[ -e /usr/local/AikoR/ ]]; then
        rm /usr/local/AikoR/ -rf
    fi

    mkdir /usr/local/AikoR/ -p
	cd /usr/local/AikoR/
    
    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/AikoCute-Offical/AikoR/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}AikoR version detection failed, maybe GIthub API limit exceeded, please try again later or specify AikoR version setting manually${plain}"
            exit 1
        fi
        echo -e "The latest version of AikoR has been detected：${last_version}，Start the installation"
        wget -N --no-check-certificate -O /usr/local/AikoR/AikoR-linux.zip https://github.com/AikoCute-Offical/AikoR/releases/download/${last_version}/AikoR-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}AikoR download failed, make sure your server can download Github files${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/AikoCute-Offical/AikoR/releases/download/${last_version}/AikoR-linux-${arch}.zip"
        echo -e "AikoR starts up v$1"
        wget -N --no-check-certificate -O /usr/local/AikoR/AikoR-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download AikoR v$1 Failed, make sure this version exists${plain}"
            exit 1
        fi
    fi

    unzip AikoR-linux.zip
    rm AikoR-linux.zip -f
    chmod +x AikoR
    mkdir /etc/AikoR/ -p
    rm /etc/systemd/system/AikoR.service -f
    echo -e "${green}AikoR ${last_version}${plain} The installation is complete, it is already set to start automatically"
    cp geoip.dat /etc/AikoR/
    cp geosite.dat /etc/AikoR/ 

    if [[ ! -f /etc/AikoR/aiko.yml ]]; then
        cp aiko.yml /etc/AikoR/
        echo -e ""
        echo -e "New installation, please refer to previous tutorial：https://github.com/AikoCute-Offical/AikoR，Configure required content"
    else
        systemctl start AikoR
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}AikoR reboot successfully${plain}"
        else
            echo -e "${red}AikoR May not start, please use the following AikoR log Check the log information, if it fails to start, the configuration format may have been changed, please go to the wiki to check：https://github.com/AikoCute-Offical/AikoR${plain}"
        fi
    fi

    if [[ ! -f /etc/AikoR/dns.json ]]; then
        cp dns.json /etc/AikoR/
    fi
    if [[ ! -f /etc/AikoR/route.json ]]; then
        cp route.json /etc/AikoR/
    fi
    if [[ ! -f /etc/AikoR/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/AikoR/
    fi
    curl -o /usr/bin/AikoR -Ls https://raw.githubusercontent.com/AikoCute-Offical/AikoR-install/master/AikoR.sh
    chmod +x /usr/bin/AikoR
    ln -s /usr/bin/AikoR /usr/bin/aikor # compatible lowercase
    chmod +x /usr/bin/aikor
}

update_shell(){
    wget -O /usr/bin/AikoR -N --no-check-certificate https://raw.githubusercontent.com/AikoCute-Offical/AikoR-install/master/AikoR.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Script failed to download, please check if machine can connect to Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/aikor
        echo -e "${green} Script upgrade successful, please run the script again ${plain}" && exit 0
    fi
}

show_usage() {
    echo -e ""
    echo " How to use the AikoR . management script " 
    echo "------------------------------------------"
    echo "           AikoR   - Show admin menu      "
    echo "              AikoR by AikoCute           "
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}AikoR Các tập lệnh quản lý phụ trợ，${plain}${red}không hoạt động với docker${plain}
--- https://github.com/AikoCute-Offical/AikoR ---
  ${green}0.${plain} Setting Config
————————————————
  ${green}1.${plain} Install AikoR
  ${green}2.${plain} Update AikoR
  ${green}3.${plain} Uninstall AikoR
————————————————
  ${green}4.${plain} Launch AikoR
  ${green}5.${plain} Stop AikoR
  ${green}6.${plain} Khởi động lại AikoR
  ${green}7.${plain} View AikoR status
  ${green}8.${plain} View AikoR logs
————————————————
  ${green}9.${plain} Set AikoR to start automatically
 ${green}10.${plain} Canceling AikoR autostart
————————————————
 ${green}11.${plain} Install BBR
 ${green}12.${plain} View AikoR version
 ${green}13.${plain} Update AikoR shell
 "
 # Cập nhật tiếp theo có thể được thêm vào chuỗi trên
    show_status
    echo && read -p "Please enter an option [0-13]: " num

    case "${num}" in
        0) config
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && start
        ;;
        5) check_install && stop
        ;;
        6) check_install && restart
        ;;
        7) check_install && status
        ;;
        8) check_install && show_log
        ;;
        9) check_install && enable
        ;;
        10) check_install && disable
        ;;
        11) install_bbr
        ;;
        12) check_install && show_AikoR_version
        ;;
        13) update_shell
        ;;
        *) echo -e "${red}Please enter the correct number [0-13]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 $2
        ;;
        "config") config $*
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_AikoR_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi