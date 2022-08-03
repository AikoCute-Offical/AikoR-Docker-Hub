#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} Vui lòng sử dụng quyền Root\n" && exit 1

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

install_docker(){
    if [[ ${release} == "centos" ]]; then
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
yum install unzip
systemctl start docker
systemctl enable docker

    else
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
apt install unzip
systemctl start docker
systemctl enable docker
    fi
}

install_docker_compose(){
curl -fsSL https://get.docker.com | bash -s docker
curl -L "https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
}


install_aikor() {
    if [[ -e /usr/local/AikoR/ ]]; then
        rm /usr/local/AikoR/ -rf
    fi

    mkdir /usr/local/AikoR/ -p
	cd /usr/local/AikoR/
    
    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/AikoCute-Offical/AikoR-DockerInstall/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}AikoR version detection failed, maybe GIthub API limit exceeded, please try again later or specify AikoR version setting manually${plain}"
            exit 1
        fi
        echo -e "The latest version of AikoR has been detected：${last_version}，Start the installation"
        wget -N --no-check-certificate -O /usr/local/AikoR/AikoR.zip https://github.com/AikoCute-Offical/AikoR-DockerInstall/releases/download/${last_version}/AikoR-DockerInstall.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}AikoR download failed, make sure your server can download Github files${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/AikoCute-Offical/AikoR-DockerInstall/releases/download/${last_version}/AikoR-DockerInstall.zip"
        echo -e "AikoR starts up v$1"
        wget -N --no-check-certificate -O /usr/local/AikoR/AikoR.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download AikoR v$1 Failed, make sure this version exists${plain}"
            exit 1
        fi
    fi

    unzip AikoR.zip
    rm AikoR-linux.zip -f
    chmod +x AikoR
    mkdir /etc/AikoR/ -p
    mkdir /etc/AikoR/AikoR -p
    echo -e "${green}AikoR ${last_version}${plain} The installation is complete, it is already set to start automatically"

    if [[ ! -f /etc/AikoR/AikoR/aiko.yml ]]; then
        cp aiko.yml /etc/AikoR/AikoR
        echo -e ""
        echo -e "New installation, please refer to previous tutorial：https://github.com/AikoCute-Offical/AikoR，Configure required content"
    else
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}AikoR reboot successfully${plain}"
        else
            echo -e "${red}AikoR May not start, please use the following AikoR log Check the log information, if it fails to start, the configuration format may have been changed, please go to the wiki to check：https://github.com/AikoCute-Offical/AikoR${plain}"
        fi
    fi

    if [[ ! -f /etc/AikoR/dns.json ]]; then
        cp AikoR/dns.json /etc/AikoR/AikoR
    fi
    if [[ ! -f /etc/AikoR/route.json ]]; then
        cp AikoR/route.json /etc/AikoR/AikoR
    fi
    if [[ ! -f /etc/AikoR/custom_outbound.json ]]; then
        cp AikoR/custom_outbound.json /etc/AikoR/AikoR
    fi
    if [[ ! -f /etc/AikoR/AikoR/rulelist ]]; then
        cp AikoR/rulelist /etc/AikoR/AikoR
    fi
    if [[ ! -f /etc/AikoR/docker-compose.yml ]]; then
        cp docker-compose.yml /etc/AikoR
    fi

    
    curl -o /usr/bin/AikoR -Ls https://raw.githubusercontent.com/AikoCute-Offical/AikoR-DockerInstall/master/AikoR.sh
    chmod +x /usr/bin/AikoR
    ln -s /usr/bin/AikoR /usr/bin/aikor # compatible lowercase
    chmod +x /usr/bin/aikor
}

update_shell(){
    wget -O /usr/bin/AikoR -N --no-check-certificate https://raw.githubusercontent.com/AikoCute-Offical/AikoR-DockerInstall/master/AikoR.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Script failed to download, please check if machine can connect to Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/aikor
        echo -e "${green} Script upgrade successful, please run the script again ${plain}" && exit 0
    fi
}

configuration(){
    echo -e "AikoR Configuration"
    echo -e "1. Quit"
    echo -e "2. Configure AikoR"
    echo -e "3. Editing some other files in AikoR"

    read -p "Please enter your choice [1-3]: " config_num
    if [[ "$config_num" == "1" ]]; then
        exit 0
    elif [[ "$config_num" == "2" ]]; then
        nano /etc/AikoR/aiko.yml
    echo -e "${green}AikoR configuration completed${plain}" 
    elif [[ "$config_num" == "3" ]]; then
        echo -e "1. Configure DNS"
        echo -e "2. Configure custom_inbound.json"
        echo -e "3. Configure custom_outbound.json"
        echo -e "4. Configure route.json"
        echo -e "5. Configure rulelist"
        read -p "Please enter your choice [1-5]: " configv1_num

        if [[ "$configv1_num" == "1" ]]; then
            nano /etc/AikoR/AikoR/dns.json
            config
        elif [[ "$configv1_num" == "2" ]]; then
            nano /etc/AikoR/AikoR/custom_inbound.json
            config
        elif [[ "$configv1_num" == "3" ]]; then
            nano /etc/AikoR/AikoR/custom_outbound.json
            config
        elif [[ "$configv1_num" == "4" ]]; then
            nano /etc/AikoR/AikoR/route.json
            config
        elif [[ "$configv1_num" == "5" ]]; then
            nano /etc/AikoR/AikoR/rulelist
            config
        else
            echo -e "${red}Please enter the correct number${plain}"
            configuration
        fi
    else
        echo -e "${red}Please enter the correct number${plain}"
        config
    fi   
}

find_docker(){
    cd /etc/AikoR
}

update_aikor(){
    find_docker
    docker-compose pull
    docker-compose up -d
}

install(){
    find_docker
    install_docker
    install_docker_compose
    install_aikor
    configuration
    update_aikor
}

uninstall_aikor(){
    find_docker
    docker-compose down
    rm /usr/bin/AikoR -f
    rm /etc/XrayR -f
}

check_log(){
    find_docker
    docker-compose logs
}

restart_aikor(){
    find_docker
    docker-compose down
    docker-compose up -d
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
  ${green}AikoR Backend management scripts，${plain}${green} Works with docker${plain}
--- https://github.com/AikoCute-Offical/AikoR ---
  ${green}0.${plain} Quit
————————————————
  ${green}1.${plain} Install AikoR
  ${green}2.${plain} Update AikoR
  ${green}3.${plain} Uninstall AikoR
————————————————
  ${green}4.${plain} Configuration
  ${green}5.${plain} Launch AikoR
  ${green}6.${plain} Stop AikoR
  ${green}7.${plain} Restart AikoR
  ${green}8.${plain} View AikoR logs
  ${green}9.${plain} Update Shell
 "
 # Cập nhật tiếp theo có thể được thêm vào chuỗi trên
    echo && read -p "Please enter an option [0-7]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) install
        ;;
        2) update_aikor
        ;;
        3) uninstall_aikor
        ;;
        4) configuration
        ;;
        5) update_aikor
        ;;
        6) docker-compose down
        ;;
        7) restart_aikor
        ;;
        8) check_log
        ;;
        9) update_shell
        ;;
        *) echo -e "${red}Please enter the correct number [0-9]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") update_aikor
        ;;
        "stop") docker-compose down
        ;;
        "restart") restart_aikor
        ;;
        "log") check_log
        ;;
        "update") update_aikor
        ;;
        "config") configuration
        ;;
        "install") install 0
        ;;
        "uninstall") uninstall_aikor
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi