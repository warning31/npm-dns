#!/usr/bin/env sh

main() {

    START_PATH=${PWD}
    touch ${START_PATH}/npm.log
    OUTPUTLOG=${START_PATH}/npm.log

    printf "\033c"

    echo "NPM ve PowerDNS Kurulumuna Hoşgeldiniz"
    echo
    sleep 5

    echo
    echo "Kurulum Başlıyor"
    echo

    exec 3>&1 1>>${OUTPUTLOG} 2>&1

    _updateyapiliyor
    _paketlerikaldir
    _klasorolustur
    _repoekleniyor
    _dockerkuruluyor
    _docketcomposekur
    _dockercomposeymlolustur
    _powerdnskuruluyor
    _poweradminkuruluyor
    _npminstall
    _clean

    if $(YesOrNo "Sunucuyu Yeniden Başlat"); then
        1>&3
        echo "Sunucuyu Yeniden Başlat" 1>&3
        /sbin/reboot
    else
        cd /root
    fi
}

_updateyapiliyor() {
    echo "Sistem update yapılıyor" 1>&3
    apt-get install -y dialog whiptail nano
    apt-get -y update
    apt-get -y upgrade
    echo "Sistem update yapıldı" 1>&3
}

_paketlerikaldir() {
    echo "Paketler kaldırılıyor" 1>&3
    apt-get update
    apt-get -y remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "Paketler kaldırıldı" 1>&3
}

_klasorolustur() {
    echo "Klasör oluşturuluyor" 1>&3
    mkdir -p /opt/npm
    mkdir -p /opt/npm/data
    echo "Klasör oluşturuldu" 1>&3
}

_repoekleniyor() {
    echo "Repo ekleniyor" 1>&3
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    echo "Repo eklendi" 1>&3
}

_dockerkuruluyor() {
    echo "Docker kuruluyor" 1>&3
    apt-get update
    apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "Docker kuruldu" 1>&3
}

_docketcomposekur() {
    echo "Docker Compose kuruluyor" 1>&3
    curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "Docker Compose kuruldu" 1>&3
}

_dockercomposeymlolustur() {
    echo "Docker Compose yml oluşturuluyor" 1>&3
    cat <<EOF >/opt/npm/docker-compose.yml
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager'
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "npm"
      DB_MYSQL_NAME: "npm"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - db

  db:
    image: 'jc21/mariadb-aria'
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - ./mysql:/var/lib/mysql

  powerdns:
    image: 'powerdns/pdns-server:latest'
    environment:
      PDNS_gmysql_host: "db"
      PDNS_gmysql_user: "pdns"
      PDNS_gmysql_password: "pdns"
      PDNS_gmysql_dbname: "pdns"
      PDNS_api_key: "mysecretapikey"
    ports:
      - '53:53/udp'
      - '53:53/tcp'
      - '8081:8081'
    volumes:
      - ./pdns-data:/data

  poweradmin:
    image: 'poweradmin/poweradmin'
    environment:
      DB_HOST: "db"
      DB_USER: "pdns"
      DB_PASS: "pdns"
    ports:
      - '8080:80'
    depends_on:
      - db
EOF

    echo "Docker Compose yml oluşturuldu" 1>&3
}

_powerdnskuruluyor() {
    echo "PowerDNS kuruluyor" 1>&3
    apt-get install -y pdns-server pdns-backend-mysql
    echo "PowerDNS kuruldu" 1>&3
}

_poweradminkuruluyor() {
    echo "PowerAdmin kuruluyor" 1>&3
    apt-get install -y apache2 php php-mysql
    echo "PowerAdmin kuruldu" 1>&3
}

_npminstall() {
    echo "Npm kuruluyor" 1>&3
    cd /opt/npm
    docker-compose up -d
    echo "Npm kuruldu" 1>&3
}

_clean() {
    echo "Temizlik yapılıyor" 1>&3
    rm -rf /root/install.sh
    rm -rf /root/npm.log
    echo "Temizlik yapıldı" 1>&3
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
