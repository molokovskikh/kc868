#!/bin/bash

IP=${KS868_IP}
PORT=${KS868_PORT}

test -z ${IP} && echo $1|grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]' &&
IP=${1:-192.168.132.18}
test -z ${PORT} && echo $2|grep -E '[0-9]+' &&
PORT=${2:-4196}

NETCAT_TIMEOUT=1


#Получить количество реле
get_relay_count(){
 echo "RELAY-SCAN_DEVICE-NOW"|nc -w $NETCAT_TIMEOUT $IP $PORT|sed -E 's/(RELAY-SCAN_DEVICE-CHANNEL_)([0-9]+)(,OK.*)/\2/'
}

#Получить состояние всех реле
get_state(){
 echo "RELAY-STATE-255"|nc -w $NETCAT_TIMEOUT $IP $PORT|grep -oaE "RELAY-STATE-[0-9]+,[0-9]+,OK"|sed -E 's/(RELAY-STATE-[0-9]+,)([0-9]+)(,OK)/\2/'
}

#Проверить реле вкллючено?
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



test -n "${KC868_DEBUG}" && echo $IP $PORT

#Если в параметре 1 указан не IP адрес
test -n "${1}" && [[ "${IP}" != "${1}"  ]]&& 
[[ "${PORT}" != "${2}" ]] &&
(test -n "${KC868_DEBUG}" && echo "Excecute command $1"; true) &&

case "${1}" in
[hH][eE][lL][pP]|'--?')
help
;;
[oO][nN]*)
relay_on "${1}"
;;
[oO][fF][fF]*)
relay_off "${1}"
;;
*)
eval "${1}"
;;
esac
