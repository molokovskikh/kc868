# kc868
```bash
$. kc868.sh help
Command list:
get_relay_count - Return a number relay count at board
is_relay [RelayNumberAtBoard] - Check relay N on, exitCode = 0 if check was success
show_active_relays - Show relays in state On
show_inactive_relays - Show relays in state Off
relay_on [RelayNumberAtBoard] - To switch relay N to state On
relay_off [RelayNumberAtBoard] - To switch relay N to state Off

$ . kc868.sh get_relay_count
8

$ . kc868.sh show_active_relays
2
3
4
5

$ . kc868.sh 'relay_off 5'
$ [ $?  = 0 ] && echo Complete off relay 5

$ . kc868.sh show_active_relays
2
3
4

$ . kc868.sh show_inactive_relays
1
5
6
7
8
```

ENVIRONMENT VARIABLES:
* KC868_DEBUG - values 1 or empty - Show debug info
* KC868_IP - values IP4 address or auto - When auto then will search device at available network interfaces (need to install nmap utility)
* KC868_PORT - commonly 4196, but is support to change

