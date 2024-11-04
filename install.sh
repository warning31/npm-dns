#!/usr/bin/env sh

main() {

    START_PATH=${PWD}
    touch ${START_PATH}/npm.log
    OUTPUTLOG=${START_PATH}/npm.log

    printf "\033c"

    echo  "NPM Kurulumuna Hosgeldiniz"
    echo

    sleep 5

    echo
    echo "Kurulumu Basliyor"
    echo

    exec 3>&1 1>>${OUTPUTLOG} 2>&1

    _updateyapiliyor
    
    _paketlerikaldir

    _klasorolustur

    _repoekleniyor

    _dockerkuruluyor

    _docketcomposekur

    _dockercomposeymlolustur

    _npminstall
    
    _clean

if $(YesOrNo "Sunucuyu Yeniden Baslat"); then
        1>&3
        echo "Sunucuyu Yeniden Baslat" 1>&3
        /sbin/reboot
    else
        cd /root
    fi


}

_updateyapiliyor() {
    echo  "Sistem update Yapiliyor" 1>&3
    apt-get install -y dialog whiptail nano
    apt-get -y update
    apt -y update
    apt-get -y upgrade
    apt -y upgrade
    echo  "Sistem update Yapiliyor" 1>&3

}

_paketlerikaldir() {
    echo  "Paketler Kaldiriliyor" 1>&3
    apt-get update
    apt-get  -y remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo  "Paketler Kaldirildi" 1>&3

}

_klasorolustur() {
    echo  "Klasor Olusturluyor" 1>&3
    mkdir -p /opt/npm
    mkdir -p /opt/npm/data
    echo "Klasor Olusturuldu" 1>&3
}

_repoekleniyor() {
    echo  "Repo Ekleniyor" 1>&3
    apt-get update
    apt-get install  -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    echo "Repo Eklendi" 1>&3

}

_dockerkuruluyor() { 
    echo  "Docker Kuruluyor" 1>&3
      apt-get update
      apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo  "Docker Kuruldu" 1>&3
}

_docketcomposekur() {
    echo  "Docker Compose Kuruluyor" 1>&3
   curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   chmod +x /usr/local/bin/docker-compose
   ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "Docker Compose Kuruldu" 1>&3
}

_dockercomposeymlolustur() {
    echo  "Dockercompose yml Olusturluyor" 1>&3
    cat <<EOF >/opt/npm/docker-compose.yml
version: '3.1'

services:
  mysql:
    image: mysql:5.7
    container_name: powerdns-mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: powerdns
      MYSQL_USER: powerdns
      MYSQL_PASSWORD: powerdnspassword
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"
    restart: always

  powerdns:
    image: psitrax/powerdns:latest
    container_name: powerdns
    environment:
      PDNS_gmysql_host: mysql
      PDNS_gmysql_user: powerdns
      PDNS_gmysql_password: powerdnspassword
      PDNS_gmysql_dbname: powerdns
      PDNS_api: 'yes'
      PDNS_api_key: your_api_key
      PDNS_webserver: 'yes'
      PDNS_webserver_address: '0.0.0.0'
      PDNS_webserver_port: 8081
    depends_on:
      - mysql
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "8081:8081"
      - "91.107.237.246:53:53/udp"
      - "91.107.237.246:53:53/tcp"
    restart: always

  poweradmin:
    image: mbentley/poweradmin:latest
    container_name: poweradmin
    environment:
      DBHOST: mysql
      DBNAME: powerdns
      DBUSER: powerdns
      DBPASS: powerdnspassword
    depends_on:
      - mysql
    ports:
      - "8080:80"
      - "91.107.237.246:80:8080"
    restart: always

volumes:
  mysql_data:

EOF
    
    echo "Dockercompose yml Olusturuldu" 1>&3
}

_npminstall() {
    echo  "Npm Kuruluyor" 1>&3
    cd /opt/npm
    docker-compose up -d
    echo "Npm Kuruldu" 1>&3
}

_clean() {
     echo  "Temizlik Yapiliyor" 1>&3
    rm -rf /root/install.sh
    rm -rf /root/npm.log
    echo "Temizlik Yapildi." 1>&3

}

YesOrNo() {
    while :; do
        echo -n "$1 (yes/no?): " 1>&3
        read -p "$1 (yes/no?): " answer
        case "${answer}" in
        [yY] | [yY][eE][sS]) exit 0 ;;
        [nN] | [nN][oO]) exit 1 ;;
        esac
    done
}

main