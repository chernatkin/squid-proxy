#!/bin/bash

useradd -m -d /home/squid -s /bin/bash squid
usermod -a -G sudo squid
passwd squid

su - squid

sudo add-apt-repository "deb-src http://archive.ubuntu.com/ubuntu xenial main restricted universe"
sudo add-apt-repository "deb-src http://archive.ubuntu.com/ubuntu xenial-updates main restricted universe"
sudo add-apt-repository "deb-src http://security.ubuntu.com/ubuntu xenial-security main restricted universe multiverse"
sudo add-apt-repository "deb-src http://archive.canonical.com/ubuntu xenial partner"


sudo apt-get update

sudo apt-get build-dep squid3
sudo apt-get build-dep openssl
sudo apt-get install libssl-dev
sudo apt-get install openssl
sudo apt-get install squid

#bug in squid requires such workaround
sudo chmod 777 /tmp
sudo chmod 777 /var/logs

wget http://www.squid-cache.org/Versions/v3/3.5/squid-3.5.21.tar.gz
tar xzf squid-3.5.21.tar.gz
./configure --prefix=/usr --includedir=${prefix}/include --enable-ssl --mandir=${prefix}/share/man --infodir=${prefix}/share/info --sysconfdir=/etc --localstatedir=/var --libexecdir=${prefix}/lib/squid3 --disable-maintainer-mode --disable-dependency-tracking --srcdir=. --datadir=/usr/share/squid3 --sysconfdir=/etc/squid3 --mandir=/usr/share/man --enable-inline --enable-async-io=8 --enable-storeio=ufs,aufs,diskd --enable-removal-policies=lru,heap --enable-delay-pools --enable-cache-digests --enable-underscores --enable-icap-client --enable-follow-x-forwarded-for --enable-basic-auth-helpers=MSNT,NCSA,SASL,SMB,YP,getpwnam,multi-domain-NTLM --enable-ntlm-auth-helpers=SMB --enable-digest-auth-helpers=password --with-filedescriptors=65536 --with-default-user=proxy --enable-epoll --enable-linux-netfilter -with-openssl=/usr/include/openssl/
make
make install


#openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -extensions v3_ca -keyout proxyKey.pem -out proxyCert.pem

#gen CA, rootCA.pem should be installed in browser
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem

openssl genrsa -out proxy.key 2048
openssl req -new -key proxy.key -out proxy.csr
openssl x509 -req -in proxy.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out proxy.crt -days 1024 -sha256

sudo cp proxy.crt /etc/squid3/
sudo cp proxy.key /etc/squid3/

sudo htpasswd -c /etc/squid3/passwords sergey
sudo htpasswd /etc/squid3/passwords guest

sudo chmod -R 777 /var/cache/squid
sudo /usr/sbin/squid -z

sudo /usr/sbin/squid -k restart


sudo iptables -t filter -A INPUT -i lo -j ACCEPT
sudo iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 3129 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 3129 -j ACCEPT
sudo iptables -t filter -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
sudo iptables -t filter -P INPUT DROP

sudo iptables -t filter -P FORWARD DROP

