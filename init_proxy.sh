#!/bin/bash

useradd -m -d /home/squid -s /bin/bash squid
usermod -a -G sudo squid
passwd squid

su - squid

sudo faillog -m 3 -l 3600

sudo apt-get update
sudo apt-get upgrade

sudo apt-get build-dep squid3
sudo apt-get build-dep openssl
sudo apt-get install libssl-dev
sudo apt-get install openssl
sudo apt-get install apache2-utils

#bug in squid requires such workaround
sudo chmod 777 /tmp
sudo mkdir /var/logs
sudo chmod 777 /var/logs

wget http://www.squid-cache.org/Versions/v3/3.5/squid-3.5.21.tar.gz
tar xzf squid-3.5.21.tar.gz
cd squid-3.5.21
./configure --prefix=/usr --includedir=${prefix}/include --enable-ssl --mandir=${prefix}/share/man --infodir=${prefix}/share/info --sysconfdir=/etc --localstatedir=/var --libexecdir=${prefix}/lib/squid3 --disable-maintainer-mode --disable-dependency-tracking --srcdir=. --datadir=/usr/share/squid3 --sysconfdir=/etc/squid3 --mandir=/usr/share/man --enable-inline --enable-async-io=8 --enable-storeio=ufs,aufs,diskd --enable-removal-policies=lru,heap --enable-delay-pools --enable-cache-digests --enable-underscores --enable-icap-client --enable-follow-x-forwarded-for --enable-basic-auth-helpers=MSNT,NCSA,SASL,SMB,YP,getpwnam,multi-domain-NTLM --enable-ntlm-auth-helpers=SMB --enable-digest-auth-helpers=password --with-filedescriptors=65536 --with-default-user=proxy --enable-epoll --enable-linux-netfilter -with-openssl=/usr/include/openssl/
make
sudo make install


#gen CA, rootCA.pem should be installed in browser
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem

openssl genrsa -out proxy.key 2048
openssl req -new -key proxy.key -out proxy.csr
openssl x509 -req -in proxy.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out proxy.crt -days 1024 -sha256

sudo cp proxy.crt /etc/squid3/
sudo cp proxy.key /etc/squid3/

sudo htpasswd -c /etc/squid3/passwords guest
sudo htpasswd /etc/squid3/passwords sergey

sudo chmod -R 777 /var/cache/squid
sudo /usr/sbin/squid -z

sudo /usr/sbin/squid -k restart
sudo /usr/sbin/squid -k rotate

#add running on startup /etc/rc.local
sudo /usr/sbin/squid

sudo iptables -t filter -A INPUT -i lo -j ACCEPT
sudo iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 3129 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 3129 -j ACCEPT
sudo iptables -t filter -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
sudo iptables -t filter -P INPUT DROP

sudo iptables -t filter -P FORWARD DROP

sudo iptables-save > /etc/iptables.rules
sudo cp iptablesload /etc/network/if-pre-up.d/
sudo chmod +x /etc/network/if-pre-up.d/iptablesload

