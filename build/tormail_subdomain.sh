#!/bin/bash

## RUN ME LIKE : (docker-compose example)
##  yandex.mail.via.tor.onion:
##    hostname: yandex.mail.via.tor.onion
##    container_name: yandex.mail.via.tor.onion
##    build: .
##    command: /bin/bash -c "bash /tormail_subdomains.sh 25 yandex.ru tor.gateway.docker"
##    volumes:
##      - /dev/shm/torified.perdition:/etc/perdition
##    networks:
##      - mail
##    ports:
##      - ${BINDIP:-127.0.0.1}:25025:25587
##      - ${BINDIP:-127.0.0.1}:25465:25465
##      - ${BINDIP:-127.0.0.1}:25587:25587
##      - ${BINDIP:-127.0.0.1}:25143:25143
##      - ${BINDIP:-127.0.0.1}:25993:25993
##

PREFIX=$1;
IMAPTARGET=imap.$2;
SMTPTARGET=smtp.$2;
TORHOST=$3
mkdir  -p /usr/var/run/perdition.imap4s ;


for  rport in 025:587 587:587 465:465;do 
  ( while (true) ;do   /bridge -b :${rport/:*/} -p $SMTPTARGET:${rport/*:/} -p socks5://$TORHOST:9050;sleep 2;done ) &
  ( while (true) ;do  
    socat TCP-LISTEN:${PREFIX}${rport/:*/},bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:127.0.0.1:${rport/:*/};
    sleep 1;
   done ) &
done

##perdition
test -e /etc/perdition || mkdir -p /etc/perdition 

touch /tmp/null;
cd /etc/perdition

test -e perdition.crt.pem || (
  test -e dhparams.pem      || openssl dhparam -out dhparams.pem -dsaparam 4096 &
  test -e perdition.key.pem || (
   ( echo;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo) | openssl req -new -x509 -nodes -out perdition.crt.pem -keyout perdition.key.pem -newkey rsa:4096 -days 3650 
         ) &
  wait 
cat dhparams.pem >> perdition.crt.pem
)

## imaps perdition
for rport in 993:993 ;do
#( while (true) ;do   /bridge -b :${PREFIX}${rport/:*/} -p $IMAPTARGET:${rport/*:/} -p socks5://$TORHOST:9050;sleep 2;done ) &

( while (true) ;do   
     /bridge -b :${PREFIX}${rport/*:/} -p $IMAPTARGET:${rport/*:/} -p socks5://$TORHOST:9050;sleep 2;done ) &


( while (true) ;do  
echo  perdition.imap4s --ssl_mode ssl_all --connect_relog 600 --no_daemon --protocol IMAP4S -f /tmp/null  --outgoing_server $IMAPTARGET --outgoing_port ${rport/*:/} --listen_port ${rport/:*/} --bind_address=127.0.0.1 -F '+'  --pid_file /tmp/perdition.${rport/*:/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
      perdition.imap4s --ssl_mode ssl_all --connect_relog 600 --no_daemon --protocol IMAP4S -f /tmp/null  --outgoing_server 127.0.0.1 --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/} --bind_address=127.0.0.1 -F '+'  --pid_file /tmp/perdition.${rport/*:/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
sleep 1;
done ) &


( while (true) ;do  
 socat TCP-LISTEN:${rport/:*/},bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:127.0.0.1:${rport/:*/};
sleep 1;
done ) &
( while (true) ;do  
 socat TCP-LISTEN:999,bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr OPENSSL-CONNECT:127.0.0.1:${rport/:*/},verify=0;
sleep 1;
done ) &

done

## imap perdition
for rport in 143:143 ;do
#( while (true) ;do   /bridge -b :${PREFIX}${rport/:*/} -p $IMAPTARGET:${rport/*:/} -p socks5://$TORHOST:9050;sleep 2;done ) &

( while (true) ;do   
     /bridge -b :${PREFIX}${rport/*:/} -p $IMAPTARGET:${rport/*:/} -p socks5://$TORHOST:9050;sleep 2;done ) &
( while (true) ;do  
echo  perdition.imap4s --ssl_mode tls_all_force --connect_relog 600 --no_daemon --protocol IMAP4 -f /tmp/null  --outgoing_server $IMAPTARGET --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/} --bind_address=127.0.0.1 -F '+'  --pid_file /tmp/perdition.${rport/*:/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
      perdition.imap4s --ssl_mode tls_all_force --connect_relog 600 --no_daemon --protocol IMAP4 -f /tmp/null  --outgoing_server 127.0.0.1 --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/} --bind_address=127.0.0.1 -F '+'  --pid_file /tmp/perdition.${rport/*:/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
sleep 1;
done ) &

( while (true) ;do  
 socat TCP-LISTEN:${rport/:*/},bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:127.0.0.1:${rport/:*/};
sleep 1;
done ) &

done



##the main() ping
myip=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" )

sleep 60 ;
while (true);do 
echo "pinging"$(
echo  "|smtp:25 :"  ;curl -kLv smtp://${myip}:${PREFIX}025 2>&1 |grep -e OK -e SMTP -e STARTTLS
echo  "|smtp:587:"  ;curl -kLv smtp://${myip}:${PREFIX}587 2>&1 |grep -e OK -e SMTP -e STARTTLS
echo  "|smtp:465:" ;curl -kLv smtps://${myip}:${PREFIX}465 2>&1 |grep -e OK -e SMTP -e STARTTLS
echo  "|imap:143:" ;curl -kLv  imap://${myip}:${PREFIX}143 2>&1 |grep -e OK -e SMTP -e STARTTLS
echo  "|imap:993:" ;curl -kLv imaps://${myip}:${PREFIX}993 2>&1 |grep -e OK -e SMTP -e STARTTLS

)
sleep 1800
echo 
done

#fg;fg;fg;
#fg;fg;
wait


# mkdir  -p /usr/var/run/perdition.imap4s ;
# screen -dmS perditionsocat socat TCP-LISTEN:$PORT,bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:127.0.0.1:$PORT;
#screen -dmS torsocat socat TCP-LISTEN:9050,fork,reuseaddr TCP-CONNECT:$TORGW:9050;
# perdition.imap4s --no_daemon --protocol IMAP4S -f /tmp/null  --outgoing_server 192.168.26.242 --outgoing_port 143 --explicit_domain eb.be.eu.org  --listen_port $PORT --bind_address=127.0.0.1:$PORT -F '+'  --pid_file /tmp/perdition.${rport/*:/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive


