#!/bin/bash

# Kullanıcıdan domain ve IP bilgilerini alın
read -p "Domain adını girin (örneğin, example.com): " domain
read -p "$domain için IP adresini girin: " ip_address

# Zone dosyası yolu
zone_file="/etc/bind/zone/${domain}.db"

# named.conf.local dosyasına zone tanımı ekleyin
echo "zone \"${domain}\" {" | sudo tee -a /etc/bind/named.conf.local
echo "    type master;" | sudo tee -a /etc/bind/named.conf.local
echo "    file \"$zone_file\";" | sudo tee -a /etc/bind/named.conf.local
echo "};" | sudo tee -a /etc/bind/named.conf.local

# Zone dizinini kontrol et ve yoksa oluştur
if [ ! -d "/etc/bind/zone" ]; then
    sudo mkdir -p /etc/bind/zone
fi

# Zone dosyasını oluştur
sudo touch "$zone_file"

# Rastgele doğrulama kodu oluştur (sadece harf ve rakamlarla)
verification_code=$(openssl rand -hex 16)

# Zone dosyasına temel DNS kayıtlarını ekleyin
cat <<EOL | sudo tee "$zone_file"
\$TTL 86400
@    IN    SOA   ns1.${domain}. hostmaster.${domain}. (
                  2023110801 ; Seri numarası
                  3600       ; Refresh
                  1800       ; Retry
                  604800     ; Expire
                  86400 )    ; Minimum TTL

; NS kayıtları
@    IN    NS    ns1.${domain}.
@    IN    NS    ns2.${domain}.

; A kayıtları
@    IN    A     ${ip_address}
ns1  IN    A     ${ip_address}
ns2  IN    A     ${ip_address}
mail IN    A     ${ip_address}

; CNAME kaydı
www  IN    CNAME @

; MX kaydı
@    IN    MX    10 mail.${domain}.

; SSL doğrulama için rastgele oluşturulmuş TXT kaydı
_acme-challenge IN TXT "${verification_code}"
EOL

# named.conf.local ve zone dosyası için yapılandırma kontrolü
echo "Yapılandırma dosyalarını kontrol ediliyor..."
sudo named-checkconf
sudo named-checkzone "${domain}" "$zone_file"

# Bind servisini yeniden başlat
echo "BIND servisini yeniden başlatılıyor..."
sudo systemctl restart bind9

echo "DNS yapılandırması tamamlandı. ${domain} için DNS kayıtları ve rastgele SSL doğrulama TXT kaydı oluşturuldu."
echo "Oluşturulan doğrulama kodu: ${verification_code}"
