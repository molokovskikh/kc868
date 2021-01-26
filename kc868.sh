#!/bin/bash

ARG1=$1
ARG2=$2


#Определение ОС
detect_os(){
 cat /etc/os-release|grep -iE "ubuntu|debian">/dev/null && echo debian
 cat /etc/os-release|grep -iE "centos|fedora">/dev/null && echo fedora
 cat /etc/os-release|grep -iE "alpine">/dev/null && echo alpine
 cat /etc/os-release|grep -iE "arch">/dev/null && echo arch
}

#Вывести справку по установке
install_help(){
 pkg_name=$1
 os=$(detect_os)

 case $os in
 debian)
 echo "apt install ${pkg_name}"
 ;;
 fedora)
 echo "yum install ${pkg_name}"
 ;;
 alpine)
 echo "apk add ${pkg_name}"
 ;;
 arch)
 echo "pacman -S ${pkg_name}"
 ;;
 *)
 echo "unknow package manager"
 esac
}

#Поиск устройства в сети
find_board_ip(){
command -v nmap >/dev/null|| (echo "Not found nmap. Install it:" && install_help nmap; return 1)

ip_file=".kc868"
test -f $ip_file && ip=$(cat $ip_file) && test -n "${ip}" && echo $ip && return 1

target_list=$(ip -4 -br address|sed -E 's/(\w+\s+\w+\s+)([0-9,\/,\.]+)/\2/;s/([0-9,\/,\.]+).*/\1/;s/127\.0\.[0-9]+\.[0-9]+(\/[0-9])*//'|tr -t '\n' ' ')
for n in $target_list
do
result=$(nmap -T3 --open -pT:4196-4196 $n)
echo $result|grep "4196/tcp" >/dev/null &&
ip=$(echo $result|grep -Eo "Nmap scan report for [0-9,\.]+"|grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
[ $? = 0 ] && echo $ip>$ip_file && echo $ip &&
break
done
}


#Получить количество реле
get_relay_count(){
 echo "RELAY-SCAN_DEVICE-NOW"|nc -w $NETCAT_TIMEOUT $IP $PORT|sed -E 's/(RELAY-SCAN_DEVICE-CHANNEL_)([0-9]+)(,OK.*)/\2/'
}

#Получить состояние всех реле
get_state(){
 echo "RELAY-STATE-255"|nc -w $NETCAT_TIMEOUT $IP $PORT|grep -oaE "RELAY-STATE-[0-9]+,[0-9]+,OK"|sed -E 's/(RELAY-STATE-[0-9]+,)([0-9]+)(,OK)/\2/'
}

#Проверить реле включено?
is_relay(){
 relay_number=$1
 all_relay_state=$(get_state)
 relay_number=$(($relay_number-1))
 [  $(( (all_relay_state >> relay_number) & 1  )) = 1 ]
}

#Показать все включенные реле
show_active_relays(){
 relay_count=$(get_relay_count)
 all_relay_state=$(get_state)
 for (( relay_number = 0; relay_number < relay_count; relay_number++ ))
 do
   [  $(( (all_relay_state >> relay_number) & 1 )) = 1 ] && echo $(($relay_number+1))
 done
}

#Показать все выключенные реле
show_inactive_relays(){
 relay_count=$(get_relay_count)
 all_relay_state=$(get_state)
 for (( relay_number = 0; relay_number < relay_count; relay_number++ ))
 do
   [  $(( (all_relay_state >> relay_number) & 1 )) = 1 ] || echo $(($relay_number+1))
 done
}

#Переключить реле
relay_switch(){
 relay_number=$(echo $1|grep -oE '[0-9]+')
 state=$2
 #echo "RELAY-SET-255,$relay_number,$state"
 echo -n "RELAY-SET-255,${relay_number},${state}"|nc -w $NETCAT_TIMEOUT $IP $PORT|
 grep -a "RELAY-SET-255,${relay_number},${state},OK">/dev/null
 [ $? = "1" ] && echo "Can't change relay ${relay_number} to state ${state}"
}

relay_on(){
 relay_number=$(echo $1|grep -oE '[0-9]+')
 relay_switch "$relay_number" 1
}

relay_off(){
 relay_number=$(echo $1|grep -oE '[0-9]+')
 relay_switch "$relay_number" 0
}


help(){
echo 'Command list:'
echo 'get_relay_count - Return a number relay count at board'
echo 'is_relay [RelayNumberAtBoard] - Check relay N on, exitCode = 0 if check was success'
echo 'show_active_relays - Show relays in state On'
echo 'show_inactive_relays - Show relays in state Off'
echo 'relay_on [RelayNumberAtBoard] - To switch relay N to state On'
echo 'relay_off [RelayNumberAtBoard] - To switch relay N to state Off'
}

echo "${KC868_IP}"|grep -i "auto" >/dev/null && KC868_IP=$(find_board_ip)


IP=${KC868_IP}
PORT=${KC868_PORT}


test -z "${IP}" && echo ${ARG1}|grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]'>/dev/null && IP=${ARG1}
test -z "${PORT}" && echo ${ARG2}|grep -E '[0-9]+'>/dev/null && PORT=${ARG2}

test -z "${IP}" && IP="192.168.1.4"
test -z "${PORT}" && PORT=4196

NETCAT_TIMEOUT=1

test -n "${KC868_DEBUG}" && echo $IP $PORT


#Если в параметре 1 указан не IP адрес
test -n "${ARG1}" && [[ "${IP}" != "${ARG1}"  ]]&& 
[[ "${PORT}" != "${ARG2}" ]] &&
(test -n "${KC868_DEBUG}" && echo "Excecute command $ARG1"; true) &&

case "${ARG1}" in
[hH][eE][lL][pP]|'--?')
help
;;
[oO][nN]*)
relay_on "${ARG1}"
;;
[oO][fF][fF]*)
relay_off "${ARG1}"
;;
*)
eval "${ARG1}"
;;
esac
