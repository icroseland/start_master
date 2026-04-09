#!/bin/bash
# run as root on the intended puppet CA puppetserver
# no git ssh required for this to work against the public repos.

#make this work with different distros.

#pre cleanup
rm -rf /tmp/modules/

CURRENT_DIR=`pwd`
set -euo pipefail
YAML_FILE="$CURRENT_DIR/list.yaml"
REPO_NAME='https://forge.puppet.com/v3/files/'
DEST_DIR='/tmp/modules'




while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--puppet_release) target="$2"; shift ;;
        -p|--puppet_version) uglify=1 ;;
	-h|--help) echo "help passed"; exit 1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

######################red hats

if [ -f /etc/redhat-release ]; then

    DIST_VER=`cat /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -E "^NAME=" | grep -o -P '(?<=").*?(?=")'`
    case "$DIST_VER" in
        "CentOS Linux"|"AlmaLinux"|"Oracle Linux"|"Rocky Linux")
            SN='el'
            ;;  
        "Fedora Linux")
            SN='fedora'
            ;;
    esac

    dnf install wget -y
    dnf install git -y
    dnf install unzip -y
    dnf install curl -y

    LSB=$(
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "${VERSION_ID%%.*}"
        elif command -v lsb_release >/dev/null 2>&1; then
            lsb_release -rs | cut -d. -f1
        elif [ -f /etc/redhat-release ]; then
            grep -oE '[0-9]+' /etc/redhat-release | head -1
        fi
    )

    echo "LSB eq $DIST_VER  $LSB"
    GET_FILE=`curl -k -s https://yum.voxpupuli.org/ | grep -oP '(?<=href=")[^"]+' | grep -v '^/' | grep "$SN-$LSB" | sort -r | head -n 1`
    echo "rpm -Uvh https://yum.voxpupuli.org/$GET_FILE"
    ###rpm -i https://yum.voxpupuli.org/$GET_FILE
    #disable selinux as its an annoyance for a demo right now.
    ##/usr/sbin/setenforce 0
    #dnf -yq install openvox-server  

    echo 'quick test'

elif [ -f /etc/debian_version ]; then
    DIST_VER=`cat /etc/os-release | grep -E "^NAME=" | grep -o -P '(?<=").*?(?=")'`

##################### Debians

apt-get install wget -y
apt-get install git  -y 
apt install -y curl wget gnupg2 ca-certificates lsb-release apt-transport-https
U_VER=`lsb_release -a | grep Codename | awk '{split($0,a,":"); print a[2]}' | sed -e 's/^[ \t]*//'`
wget "https://apt.puppet.com/puppet7-release-$U_VER.deb"
dpkg -i "puppet7-release-$U_VER.deb"
apt-add-repository -u  http://apt.puppetlabs.com
apt-get install puppet-agent -y
apt update
# this is an ugly hack
/usr/bin/apt-key adv --no-tty --keyserver hkp://keyserver.ubuntu.com:80 --recv 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
fi


mkdir -p /tmp/modules
cd /tmp/modules
echo 'setting up base directory structure'
/opt/puppetlabs/bin/puppet apply -e  "file { '/tmp/modules': ensure => directory }"

echo 'grabbing the bootstrap module'
wget -O /tmp/start_master.zip 'https://github.com/icroseland/start_master/archive/refs/heads/main.zip'
unzip /tmp/start_master.zip -d /tmp/modules
mv /tmp/modules/start_master-main /tmp/modules/start_master
rm -f /tmp/start_master.zip 
echo 'loading modules from puppetlabs'

grep -E '^\s*-\s*.*\.tar\.gz$' $YAML_FILE | sed -E 's/^[[:space:]]*-[[:space:]]*//'| while read -r url; do
    echo "XX"

    CURRENT_NAME="$REPO_NAME$url"
    DEST_FILE="$DEST_DIR/$url"

    SN1=${url#*-}
    SN2=${SN1%%-*}
    SHORT_NAME=$SN2
    DEST_NAME="$DEST_DIR/$SHORT_NAME"
    echo $SHORT_NAME
    mkdir -p $DEST_NAME
    curl -L --fail  "$CURRENT_NAME" | tar -xz -C $DEST_NAME --strip-components=1
    done


# install r10k gem
##/opt/puppetlabs/puppet/bin/gem install r10k

# setup eyaml to work
##/opt/puppetlabs/bin/puppetserver gem install eyaml
##wget -O /tmp/eyaml.zip 'https://github.com/icroseland/demo_eyaml/archive/refs/heads/main.zip'
##unzip /tmp/eyaml.zip -d /etc/puppetlabs
##mv /etc/puppetlabs/demo_eyaml-main /etc/puppetlabs/eyaml
##rm -f /tmp/eyaml.zip

#/opt/puppetlabs/bin/puppet apply --modulepath=/tmp/modules -e "class { selinux: mode => 'permissive',}"
/opt/puppetlabs/bin/puppet apply --modulepath=/tmp/modules -e "include start_master::setup_master"

