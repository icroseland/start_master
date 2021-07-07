#!/usr/bin/bash
SERVER="XXXZZZXXX"

TYPE=`cat /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -E "^NAME=" | grep -o -P '(?<=").*?(?=")'`
FILENAME="`hostname -f | sed 's/\./_/g'`.json"
HOSTNAME=`hostname -f`
echo "{" > /tmp/$FILENAME
echo ""
echo "\"hostname\": \"$HOSTNAME\","  >> /tmp/$FILENAME
echo "\"type\": \"$TYPE\"", >> /tmp/$FILENAME
echo "\"date\": \"`date`\"," >> /tmp/$FILENAME

declare -i PROCS=`grep processor /proc/cpuinfo  | grep -v Common | awk '{split($0,a," "); print a[3]}' | tail -1`
((TOTALPROCS=$PROCS+1))
echo "\"Processors\": $TOTALPROCS," >> /tmp/$FILENAME

TOTALMEM=`grep MemTotal /proc/meminfo | awk '{split($0,a," "); print a[2]}'`
echo "\"MemTotal\": $TOTALMEM," >> /tmp/$FILENAME

echo "\"Disk Space\": [" >> /tmp/$FILENAME
fdisk -l | grep dev | awk '{split($0,a,","); print a[1]}' | sed 2d | \
    while read i
    do
	echo "\"$i\"," >> /tmp/$FILENAME
    done
echo "\"Undef\"" >> /tmp/$FILENAME
echo "]," >> /tmp/$FILENAME
echo "" >> /tmp/$FILENAME
if [ "$TYPE" == "Ubuntu" ] || [ "$TYPE" == "Debian" ]
then
   echo "\"Installed Packages\": [" >> /tmp/$FILENAME 
   apt list --installed | sed 2d | \
    while read i
    do
        echo "\"`echo $i | awk '{split($0,a,","); print a[1]}'`\"," >> /tmp/$FILENAME 
    done
    echo "\"Undef\"" >> /tmp/$FILENAME 
    echo "]," >> /tmp/$FILENAME 

echo "\"Changed installed configurations\": [" >> /tmp/$FILENAME
   dpkg-query -W -f='${Conffiles}\n' '*' | awk 'OFS="  "{print $2,$1}' | LANG=C md5sum -c 2>/dev/null | awk -F': ' '$2 !~ /OK$/{print $1}' | sed 2d | \
       while read i
       do
	   echo "\"$i\"," >> /tmp/$FILENAME 
       done
       echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME 
    
   echo "\"Package Sources\": [" >> /tmp/$FILENAME
   grep -rhE ^deb /etc/apt/sources.list* | sed 2d | \
       while read i
       do
	   echo "\"$i\"," >> /tmp/$FILENAME
       done
       echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME
  
else
   echo "\"Installed Packages\": [" >> /tmp/$FILENAME
   rpm -qa | sed 2d | \
       while read i
       do
	   echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\""  >> /tmp/$FILENAME
   echo "]," >> /tmp/$FILENAME
   echo "\"Changed installed configurations\": [" >> /tmp/$FILENAME
   rpm --verify --all | sed 2d | \
       while read i
       do
	   echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME
   echo "]," >> /tmp/$FILENAME
   echo "\"Package Sources\": [" >> /tmp/$FILENAME
   yum repolist all | sed 2d | \
       while read i
       do
	   echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME
   echo "]," >> /tmp/$FILENAME
fi

#cross os collections
echo "\"Service Status\": ["  >> /tmp/$FILENAME
systemctl status | sed 2d | \
    while read i
    do
        if [[ $i == *"service"* ]]; then
            echo "\"${i//\"/" "}\"," >> /tmp/$FILENAME
        fi
    done
    echo "\"Undef\"" >> /tmp/$FILENAME 
    echo "]," >> /tmp/$FILENAME
echo "\"Users\": ["  >> /tmp/$FILENAME
awk -F: '($3<1000){print $1}' /etc/passwd  | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME

echo "\"Groups\": [" >> /tmp/$FILENAME
cat /etc/group  | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME

echo "\"Hosts\": [" >> /tmp/$FILENAME
cat /etc/hosts  | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME
   echo "]," >> /tmp/$FILENAME

echo "\"Sysctl Settings\": [" >> /tmp/$FILENAME
sysctl -a | sed 2d | \
    while read i
    do
        echo "\"`echo $i | sed 's/\,/_/g'`\"," >> /tmp/$FILENAME
    done
    echo "\"Undef\"" >> /tmp/$FILENAME
    echo "]," >> /tmp/$FILENAME

echo "\"Ip Addresses\": [" >> /tmp/$FILENAME
ip address | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
    echo "\"Undef\"" >> /tmp/$FILENAME
    echo "]," >> /tmp/$FILENAME

echo "\"Listening Services\": [" >> /tmp/$FILENAME
lsof -i | grep -v ESTABLISHED | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
    echo "\"Undef\"" >> /tmp/$FILENAME
   echo "]," >> /tmp/$FILENAME    

echo "\"nameservers\": [" >> /tmp/$FILENAME
grep nameserver /etc/resolv.conf  | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME

echo "\"Dns options\": [" >> /tmp/$FILENAME
grep options /etc/resolv.conf  | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME

echo "\"Mounts\": [" >> /tmp/$FILENAME
   mount -l | sed 2d | \
    while read i
    do
        echo "\"`echo $i | awk '{split($0,a,","); print a[1]}'`\"," >> /tmp/$FILENAME
    done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME

echo "\"home dirs\": [" >> /tmp/$FILENAME
ls -la /home | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME

echo "\"root dirs\": [" >> /tmp/$FILENAME
ls -la / | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME

echo "\"suid files\": [" >> /tmp/$FILENAME
find / -perm /4000  | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME

echo "\"sgid files\": [" >> /tmp/$FILENAME
find / -perm /2000  | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]," >> /tmp/$FILENAME

echo "\"suid sgid files\": [" >> /tmp/$FILENAME
find / -perm /6000 | sed 2d | \
       while read i
       do
           echo "\"$i\"," >> /tmp/$FILENAME
       done
   echo "\"Undef\"" >> /tmp/$FILENAME 
   echo "]" >> /tmp/$FILENAME


echo "}"  >> /tmp/$FILENAME

echo "Uploading $FILENAME to $SERVER"
curl -F "userfile=@/tmp/$FILENAME" http://$SERVER/inventory.php
