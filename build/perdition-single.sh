#!/bin/bash
echo "TARGETING $IMAPTARGET"
[[ -z "$IMAPTARGET" ]] && echo "NO TARGET"
[[ -z "$IMAPTARGET" ]] && exit 1
PREFIX=
mkdir  -p /usr/var/run/perdition.imap4s ;

touch /tmp/null;
test -e /etc/perdition || mkdir -p /etc/perdition 
cd /etc/perdition

test -e perdition.crt.pem || (
  test -e dhparams.pem      || openssl dhparam -out dhparams.pem -dsaparam 4096 &
  test -e perdition.key.pem || (
   ( echo;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo) | openssl req -new -x509 -nodes -out perdition.crt.pem -keyout perdition.key.pem -newkey rsa:4096 -days 3650 
         ) &
  wait 


cat dhparams.pem >> perdition.crt.pem
)



##non-ssl with pre-sent starttls  to port 4192
for  rport in 4192:4190;do 
  ( while (true) ;do  
    #socat TCP-LISTEN:${PREFIX}${rport/:*/},bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:$IMAPTARGET:${rport/:*/};
    #socat TCP-LISTEN:${PREFIX}${rport/:*/},fork,reuseaddr OPENSSL-CONNECT:$IMAPTARGET:${rport/*:/},verify=0
    socat TCP-LISTEN:${PREFIX}${rport/:*/},fork,reuseaddr EXEC:'openssl s_client -ign_eof -starttls sieve -quiet -connect '$IMAPTARGET'\:'${rport/*:/} 2>&1|grep -i -e OK -e rror | while read logline;do echo $(date +%c" managesieve.socat: ")"$logline";done
    sleep 1;
   done ) &
done

##non-ssl to port 4191
for  rport in 4191:4190;do 
  ( while (true) ;do  
    #socat TCP-LISTEN:${PREFIX}${rport/:*/},bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:$IMAPTARGET:${rport/:*/};
    socat TCP-LISTEN:${PREFIX}${rport/:*/},fork,reuseaddr OPENSSL-CONNECT:$IMAPTARGET:${rport/*:/},verify=0
    sleep 1;
   done ) &
done

for  rport in 4190:4190;do 
  ( while (true) ;do  
    #socat TCP-LISTEN:${PREFIX}${rport/:*/},bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:$IMAPTARGET:${rport/:*/};
    socat TCP-LISTEN:${PREFIX}${rport/:*/},fork,reuseaddr TCP-CONNECT:$IMAPTARGET:${rport/:*/}
    sleep 1;
   done ) &
   
done


## imaps perdition
for rport in 993:993 ;do
#( while (true) ;do   /bridge -b :${PREFIX}${rport/:*/} -p $IMAPTARGET:${rport/*:/} -p socks5://$TORHOST:9050;sleep 2;done ) &
( while (true) ;do  
echo  perdition.imap4s --ssl_mode ssl_all --connect_relog 600 --no_daemon --protocol IMAP4S -f /tmp/null --outgoing_server $IMAPTARGET --outgoing_port ${rport/*:/} --listen_port ${rport/:*/}  -F '+'  --pid_file /tmp/perdition.${rport/*:/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
      perdition.imap4s --ssl_mode ssl_all --connect_relog 600 --no_daemon --protocol IMAP4S -f /tmp/null --outgoing_server $IMAPTARGET --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/}  -F '+'  --pid_file /tmp/perdition.${rport/*:/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
sleep 1;
done ) &
done

## imap perdition
for rport in 143:143 ;do
( while (true) ;do  
echo  perdition.imap4s --ssl_mode tls_all_force --connect_relog 600 --no_daemon --protocol IMAP4 -f /tmp/null  --outgoing_server $IMAPTARGET --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/}  -F '+'  --pid_file /tmp/perdition.${rport/*:/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
      perdition.imap4s --ssl_mode tls_all_force --connect_relog 600 --no_daemon --protocol IMAP4 -f /tmp/null  --outgoing_server $IMAPTARGET --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/}  -F '+'  --pid_file /tmp/perdition.${rport/*:/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
sleep 1;
done ) &
done
wait
