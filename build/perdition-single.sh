#!/bin/bash
echo "TARGETING $IMAPTARGET"
logfilter() { cat ; } ;
[[ "$DEBUG" = "true" ]] || logfilter() { grep -v -e "Connect:"  -e 'server-secure=starttls status="ok"'  -e 'server-secure=plaintext status="ok"' ; } ;

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
   #( echo;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo) | openssl req -new -x509 -nodes -out perdition.crt.pem -keyout perdition.key.pem -newkey rsa:4096 -days 3650 
   myhost=$(hostname -f)
   [[ -z "$myhost" ]] && myhost=$(hostname)
   [[ -z "$myhost" ]] && myhost=perdition.lan

   [[ -z "$SELFSIGNED_CN" ]] || mycn=$SELFSIGNED_CN
   [[ -z "$SELFSIGNED_CN" ]] && mycn=$myhost
   
   mysites=""

   [[ "$myhost" = "$mycn" ]] || mysites="imap.${myhost},www.${myhost},${myhost}"
   [[ "$myhost" = "$mycn" ]] && mysites="imap.${myhost},www.${myhost}"

   echo "$myhost"|grep -q ^mail || mysites="mail.${myhost},$mysites"
   echo "$myhost"|grep -q ^mail || mysites="imap.${myhost},$mysites"
   mysites=$(echo "$mysites"|sed 's/,/DNS:/g')
   echo "SSL:GEN:CN=${myhost} FOR $mysites" >&2
    sslres=$(openssl req -x509 -nodes -days 365 -subj '/C=XX/ST=STA/O=SelfSigned, Inc./CN='${mycn} -addext 'subjectAltName=DNS:'"$mysites" -newkey rsa:4096 -keyout perdition.key.pem -out perdition.certificate.pem 2>&1)
    echo "$sslres"|grep Error -q &&   echo "$sslres"
    echo "$sslres"|grep Error -q || ( echo "$sslres"|grep -v -e '\.' -e -- '-' )
         ) &
  wait 


cat perdition.certificate.pem dhparams.pem > perdition.crt.pem
)

test -e /etc/myimapproxy.conf || {  
echo "GENERATING /etc/myimapproxy.conf"
( echo '
###protocol_log_filename /dev/stdout
###protocol_log_filename /dev/log
##protocol_log_filename /etc/imaplog
protocol_log_filename /dev/stdout

##
###syslog_facility LOG_MAIL
syslog_prioritymask LOG_WARNING

connect_retries 10
connect_delay 5
cache_size 3072
listen_port 1143
#listen_address 127.0.0.1
# 

#server_port 143

cache_expiration_time 300
proc_username nobody
proc_groupname nogroup
stat_filename /var/run/pimpstats

send_tcp_keepalives yes
enable_select_cache yes
foreground_mode yes

##
#send tls if login disabled
force_tls yes
#force_tls no
##

chroot_directory /var/lib/imapproxy/chroot
#preauth_command
enable_admin_commands no
## Various path options for SSL CA certificates/directories
#tls_ca_file /etc/ssl/certs/ca-bundle.crt
tls_ca_file /etc/ssl/certs/ca-certificates.crt
tls_ca_path /etc/ssl/certs/
tls_cert_file /etc/perdition/perdition.crt.pem
tls_key_file  /etc/perdition/perdition.key.pem
tls_verify_server no
#tls_ciphers ALL:!aNULL:!eNULL
#tls_no_tlsv1 no
#tls_no_tlsv1.1 no
#tls_no_tlsv1.2 no
#auth_sasl_plain_username
#auth_sasl_plain_password
#auth_shared_secret
#dns_rr yes
#ipversion_only 6
'

echo

echo "server_hostname $IMAPTARGET" ; echo "server_port 143";echo

#echo "server_hostname 127.0.0.1" ;echo "server_port 2143";echo
#echo "server_hostname 127.0.0.1" ;echo "server_port 143";echo
) > /etc/myimapproxy.conf
echo -n ; } ;

#socat unix-listen:/dev/log,fork,reuseaddr,unlink-early stdout | sed 's/\r/\n/g' &
socat unix-listen:/dev/log,fork,reuseaddr,unlink-early stdout &>/dev/null  &
socat unix-listen:/dev/log,fork,reuseaddr,unlink-early stdout  &

##non-ssl imap with pre-sent starttls  to port 2143
for  rport in 2143:143;do 
  ( while (true) ;do  
    #socat TCP-LISTEN:${PREFIX}${rport/:*/},bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:$IMAPTARGET:${rport/:*/};
    #socat TCP-LISTEN:${PREFIX}${rport/:*/},fork,reuseaddr OPENSSL-CONNECT:$IMAPTARGET:${rport/*:/},verify=0
    socat TCP-LISTEN:${PREFIX}${rport/:*/},fork,reuseaddr EXEC:'openssl s_client -ign_eof -starttls imap -quiet -connect '$IMAPTARGET'\:'${rport/*:/} 2>&1|grep -i -e OK -e rror |grep -v -e "Pre-login capabilities listed, post-login capabilitie" | while read logline;do echo $(date -u +%c" imap.socat: ")"$logline";done
    sleep 1;
   done ) &
done

##non-ssl SIEVE with pre-sent starttls  to port 4192 
for  rport in 4192:4190;do 
  ( while (true) ;do  
    #socat TCP-LISTEN:${PREFIX}${rport/:*/},bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:$IMAPTARGET:${rport/:*/};
    #socat TCP-LISTEN:${PREFIX}${rport/:*/},fork,reuseaddr OPENSSL-CONNECT:$IMAPTARGET:${rport/*:/},verify=0
    socat TCP-LISTEN:${PREFIX}${rport/:*/},fork,reuseaddr EXEC:'openssl s_client -ign_eof -starttls sieve -quiet -connect '$IMAPTARGET'\:'${rport/*:/} 2>&1|grep -i -e OK -e rror|grep -v -e "Begin TLS negotiation now" | while read logline;do echo $(date -u +%c" managesieve.socat: ")"$logline";done
    sleep 1;
   done ) &
done

##non-ssl to SIEVE 4191
for  rport in 4191:4190;do 
  ( while (true) ;do  
    #socat TCP-LISTEN:${PREFIX}${rport/:*/},bind=$(ip a |grep global|grep -v inet6|cut -d"/" -f1|cut -dt -f2 |sed "s/ //g" ),fork,reuseaddr TCP-CONNECT:$IMAPTARGET:${rport/:*/};
    socat TCP-LISTEN:${PREFIX}${rport/:*/},fork,reuseaddr OPENSSL-CONNECT:$IMAPTARGET:${rport/*:/},verify=0
    sleep 1;
   done ) &
done


## passthrough SIEVE
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
echo  perdition.imap4s --ssl_mode ssl_all --connect_relog 600 --no_daemon --protocol IMAP4S -f /tmp/null --outgoing_server $IMAPTARGET --outgoing_port ${rport/*:/} --listen_port ${rport/:*/}  -F '+'  --pid_file /tmp/perdition.${rport/:*/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
      perdition.imap4s --ssl_mode ssl_all --connect_relog 600 --no_daemon --protocol IMAP4S -f /tmp/null --outgoing_server $IMAPTARGET --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/}  -F '+'  --pid_file /tmp/perdition.${rport/:*/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive --no_bind_banner --server_resp_line  2>&1|logfilter
sleep 1;
done ) &
done

## imapproxy  perdition
for rport in 1143:143 ;do
( while (true) ;do  
#echo  perdition.imap4s --ssl_mode tls_all_force --connect_relog 600 --no_daemon --protocol IMAP4 -f /tmp/null  --outgoing_server $IMAPTARGET --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/}  -F '+'  --pid_file /tmp/perdition.${rport/:*/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive
#      perdition.imap4s --ssl_mode tls_all_force --connect_relog 600 --no_daemon --protocol IMAP4 -f /tmp/null  --outgoing_server $IMAPTARGET --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/}  -F '+'  --pid_file /tmp/perdition.${rport/:*/}.pid --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive --no_bind_banner --server_resp_line  2>&1|logfilter
/usr/sbin/imapproxyd -f /etc/myimapproxy.conf -p /tmp/imapproxy.pid;
sleep 2;
done ) &

for rport in 143:1143 ;do

( while (true) ;do  
echo  perdition.imap4 --ssl_mode tls_listen \
                      --connect_relog 600 \
                      --no_daemon --protocol IMAP4 \
                      -f /tmp/null  \
                      --outgoing_server 127.0.0.1 \
                      --outgoing_port ${PREFIX}${rport/*:/} --listen_port ${rport/:*/}  \
                      -F '+'  --pid_file /tmp/perdition.${rport/:*/}.pid \
                      --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify         --tcp_keepalive --no_bind_banner 
      perdition.imap4 --ssl_mode tls_listen \
                      --connect_relog 600 --no_daemon \
                      --protocol IMAP4 -f /tmp/null  \
                      --outgoing_server 127.0.0.1 \
                      --outgoing_port ${PREFIX}${rport/*:/} \
                      --listen_port ${rport/:*/}  -F '+'  \
                      --pid_file /tmp/perdition.${rport/:*/}.pid \
                      --ssl_no_cert_verify --ssl_no_client_cert_verify --ssl_no_cn_verify        --tcp_keepalive --no_bind_banner --server_resp_line  2>&1|logfilter

sleep 1;
done ) &
done

done
wait
