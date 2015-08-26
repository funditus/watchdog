#!/bin/sh /etc/rc.common
# Copyright (C) 2006-2011 OpenWrt.org

START=90

## IP addresses are strongly encouraged because nslookup may delay for a long time
HOST1_TO_PING=212.19.149.53
HOST2_TO_PING=8.8.8.8
HOST3_TO_PING=81.19.70.3 # rambler.ru
PING_INTERVAL=10
MAX_FAIL_COUNT_SOFT=30
MAX_FAIL_COUNT_HARD=60

DEVICE_TO_SOFT_RESET=ZTE830FT

FAIL_COUNT=0


trigger_soft_ZTE830FT () {

    LOGIN=root
    PASSWORD=zte9x15

    echo "Restarting modem"
    (sleep 1; echo $LOGIN; sleep 1; echo $PASSWORD; echo shutdown -r now; sleep 1; echo "quit" ) | telnet 192.168.0.1
}


trigger_hard () {

    echo "Restarting router"
    echo b > /proc/sysrq-trigger
#    reboot -f

}


pinger () {             
                        
    while true              
        do              
            (ping -c 1 -q $HOST1_TO_PING >/dev/null || ping -c 1 -q $HOST2_TO_PING >/dev/null || ping -c 1 -q $HOST3_TO_PING >/dev/null)
            RETURN_CODE=$?                                                            

            if [ $RETURN_CODE -ne 0 ]                                             
                then 
                    FAIL_COUNT=`expr $FAIL_COUNT + 1`                            
                    echo -e "Fail count: $FAIL_COUNT\nMax fail count soft: $MAX_FAIL_COUNT_SOFT\nMax fail count hard: $MAX_FAIL_COUNT_HARD" | tee /tmp/vnet_watchdog

                    if [ $FAIL_COUNT -eq $MAX_FAIL_COUNT_HARD ]                                                                                                     
                        then return 200                                                                                                                         
                                                                                                                 
                    elif [ $FAIL_COUNT -eq $MAX_FAIL_COUNT_SOFT ]                                                                                                   
                        then return 100                                                                                                                         

                    fi                                                                                                                                              
                                                                                                                                                                          
            elif [ $RETURN_CODE -eq 0 ]                                                                                                                               
                then                                                                                                                                            
                    FAIL_COUNT=0                                                                                                                                
                    echo -e "Fail count: $FAIL_COUNT\nMax fail count soft: $MAX_FAIL_COUNT_SOFT\nMax fail count hard: $MAX_FAIL_COUNT_HARD" | tee /tmp/vnet_watchdog
            fi                                                                                                                                                          
                                                                                                                                                                                    
            sleep $PING_INTERVAL                                                                                                                                        
        done                                                                                                                                                                
}  

watchdog () {                                                                                                                                                   
                                                                                                                                                                    
    while true                                                                                                                                                          
        do                                                                                                                                                          
            pinger                                                                                                                                                  
            PINGER_RESULT=$?                                                                                                                                        
            [ $PINGER_RESULT -eq 100 ] && echo "Watchdog: soft trigger is initiated" && trigger_soft_$DEVICE_TO_SOFT_RESET
            [ $PINGER_RESULT -eq 200 ] && echo "Watchdog: hard trigger is initiated" && FAIL_COUNT=0 && trigger_hard                                                
        done                                                                                                                                                        
}   





start() {

    watchdog &

}

stop() {

    kill `ps | grep "vnet_watchdog start\|boot" | grep -v grep | awk '{print $1}'`
    echo -e "Fail count: -1\nMax fail count soft: $MAX_FAIL_COUNT_SOFT\nMax fail count hard: $MAX_FAIL_COUNT_HARD" | tee /tmp/vnet_watchdog
}
