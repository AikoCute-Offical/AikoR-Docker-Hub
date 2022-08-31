# !/bin/bash
# 
# automatically configure AikoR by docker-compose
# Only test on Ubuntu 20.04 LTS Ubuntu 22.04 LTS

AikoR_PATH="/opt/AikoR"

DC_URL="https://raw.githubusercontent.com/AikoCute-Offical/AikoR-DockerInstall/dev/docker-compose.yml"
CONFIG_URL="https://raw.githubusercontent.com/AikoCute-Offical/AikoR-DockerInstall/dev/aiko.yml"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
export PATH=$PATH:/usr/local/bin

os_arch=""

Get_Docker_URL="https://get.docker.com"
GITHUB_URL="github.com"

# Vui lòng điền vào tên miền v2board của bạn, ví dụ: https://v2board.com/
V2BOARD_URL="https://v2board.com/"
# Vui lòng điền vào khóa api giao diện người dùng, ví dụ: 123456789
V2BOARD_API_KEY="your_api_key"

pre_check() {
    # check root
    [[ $EUID -ne 0 ]] && echo -e "${red}Lỗi: ${plain} Tập lệnh này phải được chạy với tư cách người dùng root!\n" && exit 1

    ## os_arch
    if [[ $(uname -m | grep 'x86_64') != "" ]]; then
        os_arch="amd64"
    elif [[ $(uname -m | grep 'i386\|i686') != "" ]]; then
        os_arch="386"
    elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
        os_arch="arm64"
    elif [[ $(uname -m | grep 'arm') != "" ]]; then
        os_arch="arm"
    elif [[ $(uname -m | grep 's390x') != "" ]]; then
        os_arch="s390x"
    elif [[ $(uname -m | grep 'riscv64') != "" ]]; then
        os_arch="riscv64"
    fi
}

install_base() {
    (command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v getenforce >/dev/null 2>&1) ||
        (install_soft curl wget)
}

install_soft() {
    # Thư viện chính thức của Arch không chứa các thành phần như selinux
    (command -v yum >/dev/null 2>&1 && yum makecache && yum install $* selinux-policy -y) ||
    (command -v apt >/dev/null 2>&1 && apt update && apt install $* selinux-utils -y) ||
    (command -v pacman >/dev/null 2>&1 && pacman -Syu $*) ||
    (command -v apt-get >/dev/null 2>&1 && apt-get update && apt-get install $* selinux-utils -y)
}

install() {
    install_base

    echo -e "> Cài đặt AikoR"

    # check directory
    if [ ! -d "$AikoR_PATH" ]; then
        mkdir -p $AikoR_PATH
    else
        echo "Có thể bạn đã cài đặt AikoR, cài đặt nhiều lần sẽ ghi đè dữ liệu, hãy chú ý sao lưu."
        read -e -r -p "Có thoát khỏi cài đặt hay không? [Y/n] " input
        case $input in
        [yY][eE][sS] | [yY])
            echo "Thoát khỏi cài đặt"
            exit 0
            ;;
        [nN][oO] | [nN])
            echo "Tiếp tục cài đặt"
            ;;
        *)
            echo "Thoát khỏi cài đặt"
            exit 0
            ;;
        esac
    fi
    chmod 777 -R $AikoR_PATH

    # check docker
    command -v docker >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "Đang cài đặt Docker"
        bash <(curl -sL ${Get_Docker_URL}) >/dev/null 2>&1
        if [[ $? != 0 ]]; then
            echo -e "${red}Tập lệnh tải xuống không thành công, vui lòng kiểm tra xem máy có thể kết nối được không ${Get_Docker_URL}${plain}"
            return 0
        fi
        systemctl enable docker.service
        systemctl start docker.service
        echo -e "${green}Docker${plain} Cài đặt thành công"
    fi

    # check docker compose
    command -v docker-compose >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "Đang cài đặt Docker Compose"
        wget -t 2 -T 10 -O /usr/local/bin/docker-compose "https://${GITHUB_URL}/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" >/dev/null 2>&1
        if [[ $? != 0 ]]; then
            echo -e "${red}Tập lệnh tải xuống không thành công, vui lòng kiểm tra xem máy có thể kết nối được không ${GITHUB_URL}${plain}"
            return 0
        fi
        chmod +x /usr/local/bin/docker-compose
        echo -e "${green}Docker Compose${plain} Cài đặt thành công"
    fi

    modify_AikoR_config 0

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

modify_AikoR_config() {
    echo -e "> Sửa đổi cấu hình AikoR"

    # download docker-compose.yml
    wget -t 2 -T 10 -O /tmp/docker-compose.yml ${DC_URL} >/dev/null 2>&1
    
    if [[ $? != 0 ]]; then
        echo -e "${red}Không thể tải xuống docker-compose.yml, vui lòng kiểm tra xem máy có thể kết nối được không ${DC_URL}${plain}"
        return 0
    fi

    # download aiko.yml
    wget -t 2 -T 10 -O /tmp/aiko.yml ${CONFIG_URL} >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "${red}Không tải được aiko.yml, vui lòng kiểm tra xem máy có thể kết nối được không ${CONFIG_URL}${plain}"
        return 0
    fi

    # modify aiko.yml
    ## modify v2board info
    echo -e "> Sửa đổi tên miền V2board"
    read -e -r -p "Vui lòng nhập tên miền v2board (mặc định:${V2BOARD_URL}）：" input
    if [[ $input != "" ]]; then
        V2BOARD_URL=$input
    fi
    read -e -r -p "Vui lòng nhập khóa api v2board (mặc định:${V2BOARD_API_KEY}）：" input
    if [[ $input != "" ]]; then
        V2BOARD_API_KEY=$input
    fi
    V2BOARD_URL=$(echo $V2BOARD_URL | sed -e 's/[]\/&$*.^[]/\\&/g')
    V2BOARD_API_KEY=$(echo $V2BOARD_API_KEY | sed -e 's/[]\/&$*.^[]/\\&/g')
    sed -i "s/USER_V2BOARD_DOMAIN/${V2BOARD_URL}/g" /tmp/aiko.yml
    sed -i "s/USER_V2BOARD_API_KEY/${V2BOARD_API_KEY}/g" /tmp/aiko.yml
    echo -e "> Tên miền hiện tại: ${green}${V2BOARD_URL}${plain}"
    echo -e "> Khóa api hiện tại: ${green}${V2BOARD_API_KEY}${plain}"

    ## read NODE_ID
    read -e -r -p "Vui lòng nhập ID nút (phải giống với ID do v2board đặt):" input
    NODE_ID=$input
    echo -e "ID nút mới là: ${green}${NODE_ID}${plain}"
    sed -i "s/USER_NODE_ID/${NODE_ID}/g" /tmp/aiko.yml

    ## read NODE_TYPE
    echo -e "
    ${green}Loại nút:${plain}
    ${green}1.${plain}  V2ray
    ${green}2.${plain}  ShadowSocks
    ${green}3.${plain}  Trojan
    "
    read -e -r -p "Vui lòng nhập lựa chọn [1-3]:" num
    case "$num" in
    1)
        NODE_TYPE="V2ray"
        ;;
    2)
        NODE_TYPE="Shadowsocks"
        ;;
    3)
        NODE_TYPE="Trojan"
        ;;
    *)
        echo -e "${red}Vui lòng nhập lựa chọn chính xác[1-3]${plain}"
        exit 1
        ;;
    esac
    sed -i "s/USER_NODE_TYPE/${NODE_TYPE}/g" /tmp/aiko.yml && echo -e "Đã sửa đổi thành công loại nút thành: ${green}${NODE_TYPE}${plain}"
    

    ## read tls
    echo -e "
    ${green}Cách đăng ký chứng chỉ: ${plain}
    ${green}1.${plain}  (none)Không đăng ký chứng chỉ (chọn tùy chọn này nếu bạn sử dụng nginx cho cấu hình TLS)
    ${green}2.${plain}  (file)Mang theo tệp chứng chỉ của riêng bạn (sau này trong${green}${AikoRPATH}/AikoR/cert/${plain}sửa đổi thư mục)
    ${green}3.${plain}  (http)Tập lệnh áp dụng cho chứng chỉ thông qua http (yêu cầu phân giải trước tên miền thành ip cục bộ và mở cổng 80)
    ${green}4.${plain}  (dns)Tập lệnh áp dụng cho chứng chỉ thông qua dns (tập lệnh chỉ hỗ trợ cloudflare tạm thời và yêu cầu email và khóa api toàn cầu của cloudflare)
    "

    read -e -r -p "Vui lòng nhập một lựa chọn[1-4]：" num
    case "$num" in
    1)
        echo -e "Không đăng ký chứng chỉ"
        sed -i "s/USER_CERT_MODE/none/g" /tmp/aiko.yml
        ;;     
    2)
        echo -e "Tệp chứng chỉ tự cung cấp"
        echo -e "hiện hữu ${green}${AikoRPATH}/AikoR/cert/${plain}Sửa đổi thư mục ${green}Tên miền nút.cert Tên miền nút.key${plain}tài liệu)"
        sed -i "s/USER_CERT_MODE/file/g" /tmp/aiko.yml
        TLS=true
        ;;
    3)
        echo -e "Tập lệnh áp dụng cho chứng chỉ thông qua http"
        sed -i "s/USER_CERT_MODE/http/g" /tmp/aiko.yml
        TLS=true
        ;;
    4)
        echo -e "Tập lệnh áp dụng cho chứng chỉ thông qua dns"
        sed -i "s/USER_CERT_MODE/dns/g" /tmp/aiko.yml
        TLS=true
        read -e -r -p "Vui lòng nhập khóa api toàn cầu của cloudflare:" input
        CLOUDFLARE_GLOBAL_API_KEY=$input
        read -e -r -p "Vui lòng nhập email của cloudflare:" input
        CLOUDFLARE_EMAIL=$input
        CLOUDFLARE_GLOBAL_API_KEY=$(echo $CLOUDFLARE_GLOBAL_API_KEY | sed -e 's/[]\/&$*.^[]/\\&/g')
        CLOUDFLARE_EMAIL=$(echo $CLOUDFLARE_EMAIL | sed -e 's/[]\/&$*.^[]/\\&/g')
        sed -i "s/USER_CLOUDFLARE_API_KEY/${CLOUDFLARE_GLOBAL_API_KEY}/g" /tmp/aiko.yml
        sed -i "s/USER_CLOUDFLARE_EMAIL/${CLOUDFLARE_EMAIL}/g" /tmp/aiko.yml
        ;;
    *)
        echo -e "${red}Lỗi đầu vào, vui lòng nhập lại[1-4]${plain}"
        if [[ $# == 0 ]]; then
        modify_AikoR_config
        else
            modify_AikoR_config 0
        fi
        exit 0
        ;;
    esac

    if [ -z "${TLS}" ]; then
        echo -e "> Không đăng ký chứng chỉ"
    else
        read -e -r -p "Vui lòng nhập tên miền:" input
        NODE_DOMAIN=$input
        echo -e "> Tên miền nút là: ${green}${NODE_DOMAIN}${plain}"
        sed -i "s/USER_NODE_DOMAIN/${NODE_DOMAIN}/g" /tmp/aiko.yml
    fi

    # replace aiko.yml
    mv /tmp/aiko.yml $AikoR_PATH/aiko.yml
    mv /tmp/docker-compose.yml $AikoR_PATH/docker-compose.yml
    echo -e "AikoR配置 ${green}Sửa đổi thành công, vui lòng đợi khởi động lại có hiệu lực${plain}"
    # get NODE_IP
    NODE_IP=`curl -s https://ipinfo.io/ip`
    
    
    if [[ -z "${TLS}" ]]; then
        echo -e "> Không đăng ký chứng chỉ"
    else
        echo -e "> Tên miền của nút là:${yellow}${NODE_DOMAIN}${plain}"
    fi
    echo -e "> Node IP là:${yellow}${NODE_IP}${plain}"

    # show config
    show_config 0

    # restart AikoR
    restart_and_update 0

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    echo -e "> Khởi động AikoR"
    # start docker-compose
    cd $AikoR_PATH && docker-compose up -d
    if [[ $? == 0 ]]; then
        echo -e "${green}Đã bắt đầu thành công${plain}"
    else
        echo -e "${red}Khởi động không thành công, vui lòng kiểm tra thông tin nhật ký sau${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    echo -e "> Dừng AikoR"

    cd $AikoR_PATH && docker-compose down
    if [[ $? == 0 ]]; then
        echo -e "${green}Stop thành công${plain}"
    else
        echo -e "${red}Dừng không thành công, vui lòng kiểm tra thông tin nhật ký sau${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart_and_update() {
    echo -e "> Khởi động lại AikoR"
    cd $AikoR_PATH
    docker-compose pull
    docker-compose down
    docker-compose up -d
    if [[ $? == 0 ]]; then
        echo -e "${green}khởi động lại thành công${plain}"
    else
        echo -e "${red}Khởi động lại không thành công, vui lòng kiểm tra thông tin nhật ký sau${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    echo -e "> Nhận nhật ký AikoR"

    cd $AikoR_PATH && docker-compose logs -f

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_config() {
    echo -e "> Xem cấu hình AikoR"

    cd $AikoR_PATH
    
    V2BOARD_URL=$(cat aiko.yml | grep "ApiHost" | awk -F ':' '{print $2 $3}' | awk -F '"' '{print $2}')
    V2BOARD_API_KEY=$(cat aiko.yml | grep "ApiKey" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    NODE_IP=$(curl -s ip.sb)
    NODE_ID=$(cat aiko.yml | grep "NodeID" | awk -F ':' '{print $2}')
    NODE_TYPE=$(cat aiko.yml | grep "NodeType" | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}')
    CertMode=$(cat aiko.yml | grep "CertMode" | head -n 1 | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}')
    CertFile=$(cat aiko.yml | grep "CertFile" | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}')
    KeyFile=$(cat aiko.yml | grep "KeyFile" | awk -F ':' '{print $2}')
    NODE_DOMAIN=$(cat aiko.yml | grep "CertDomain" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    CLOUDFLARE_EMAIL=$(cat aiko.yml | grep "CLOUDFLARE_EMAIL" | awk -F ':' '{print $2}')
    CLOUDFLARE_API_KEY=$(cat aiko.yml | grep "CLOUDFLARE_API_KEY" | awk -F ':' '{print $2}')

    echo -e "
    Tên miền front-end v2board:${green}${V2BOARD_URL}${plain}
    khóa api v2board:${green}${V2BOARD_API_KEY}${plain}
    Node IP:${green}${NODE_IP}${plain}
    ID nút:${green}${NODE_ID}${plain}
    Loại nút:${green}${NODE_TYPE}${plain}
    Chế độ chứng chỉ:${green}${CertMode}${plain}
    Tệp chứng chỉ:${green}${CertFile}${plain}
    Tệp khóa cá nhân:${green}${KeyFile}${plain}
    Tên miền nút:${green}${NODE_DOMAIN}${plain}
    Cloudflare Email：${green}${CLOUDFLARE_EMAIL}${plain}
    Cloudflare API Key：${green}${CLOUDFLARE_API_KEY}${plain}
    "
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

uninstall() {
    echo -e "> Gỡ cài đặt AikoR"

    cd $AikoR_PATH && docker-compose down
    rm -rf $AikoR_PATH
    docker rmi -f aikocute/aikor:latest > /dev/null 2>&1
    clean_all

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}* Nhấn enter để quay lại menu chính *${plain}" && read temp
    show_menu
}

clean_all() {
    clean_all() {
    if [ -z "$(ls -A ${AikoR_PATH})" ]; then
        rm -rf ${AikoR_PATH}
    fi
}
}

show_menu() {
    echo -e "
    ${green}AikoR Tập lệnh quản lý cài đặt Docker${plain}
    ${green}1.${plain}  Cài đặt AikoR
    ${green}2.${plain}  Sửa đổi cấu hình AikoR
    ${green}3.${plain}  Khởi động AikoR
    ${green}4.${plain}  Dừng AikoR
    ${green}5.${plain}  Khởi động lại và cập nhật AikoR (chưa có bản cập nhật!)
    ${green}6.${plain}  Xem nhật ký AikoR
    ${green}7.${plain}  Xem cấu hình AikoR
    ${green}8.${plain}  Gỡ cài đặt AikoR
    ————————————————
    ${green}0.${plain}  Thoát
    "
    echo && read -ep "Vui lòng nhập một lựa chọn [0-8]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        install
        ;;
    2)
        modify_AikoR_config
        ;;
    3)
        start
        ;;
    4)
        stop
        ;;
    5)
        restart_and_update
        ;;
    6)
        show_log
        ;;
    7)
        show_config
        ;;
    8)
        uninstall
        ;;
    *)
        echo -e "${red}Vui lòng nhập số chính xác [0-8]${plain}"
        ;;
    esac
}

clear
pre_check
show_menu