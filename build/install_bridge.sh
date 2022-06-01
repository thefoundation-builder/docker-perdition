#!/bin/bash
url=https://github.com/wzshiming/bridge/releases
search=linux_amd64
uname -a |grep aarch64 && search=linux_arm64
echo "searching bin release for bridge from $url"
 
link=$(wget -O- https://github.com/wzshiming/bridge/releases|grep bridge_$search |grep href|head -n1|cut -d'"' -f2)

[[ -z "$link" ]] || (echo "wget -c https://github.com/$link -O /bridge" ;wget -c https://github.com/$link -O /bridge)
exit 0
