#!/bin/bash
# run as root on the intended puppet master
# no git ssh required for this to work against the public repos.

#make this work with different distros.

DIST_VER=`cat /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -E "^NAME=" | grep -o -P '(?<=").*?(?=")'`
if [ "$DIST_VER" == "CentOS Linux" ]
then
yum install wget -y
yum install git -y
rpm -Uvh http://yum.puppet.com/puppet7/puppet7-release-el-8.noarch.rpm
#disable selinux as its an annoyance for a demo right now.
/usr/sbin/setenforce 0
yum install puppet-agent -y
fi
if [ "$DIST_VER" == "Ubuntu" ]
then
apt-get install wget -y
apt-get install git  -y 
apt install -y curl wget gnupg2 ca-certificates lsb-release apt-transport-https
U_VER=`lsb_release -a | grep Codename | awk '{split($0,a,":"); print a[2]}' | sed -e 's/^[ \t]*//'`
wget "https://apt.puppet.com/puppet7-release-$U_VER.deb"
dpkg -i "puppet7-release-$U_VER.deb"
apt-add-repository -u  http://apt.puppetlabs.com
apt-get install puppet-agent -y
apt update
wget https://packages.sury.org/php/apt.gpg
apt-key add apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php7.list
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
mkdir /tmp/modules/stdlib
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-stdlib-5.1.0.tar.gz' | tar -xz -C /tmp/modules/stdlib --strip-components=1
mkdir /tmp/modules/puppet
curl -L 'https://forge.puppet.com/v3/files/theforeman-puppet-14.2.1.tar.gz' | tar -xz -C /tmp/modules/puppet --strip-components=1
mkdir /tmp/modules/apache
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-apache-3.4.0.tar.gz' | tar -xz -C /tmp/modules/apache --strip-components=1
mkdir /tmp/modules/concat
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-concat-5.1.0.tar.gz' | tar -xz -C /tmp/modules/concat --strip-components=1
mkdir /tmp/modules/extlib
curl -L 'https://forge.puppet.com/v3/files/puppet-extlib-3.0.0.tar.gz' | tar -xz -C /tmp/modules/extlib --strip-components=1
mkdir /tmp/modules/foreman
curl -L 'https://forge.puppet.com/v3/files/theforeman-foreman-10.0.0.tar.gz' | tar -xz -C /tmp/modules/foreman --strip-components=1
mkdir /tmp/modules/apt
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-apt-6.1.1.tar.gz' | tar -xz -C /tmp/modules/apt --strip-components=1
mkdir /tmp/modules/postgresql
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-postgresql-5.10.0.tar.gz' | tar -xz -C /tmp/modules/postgresql --strip-components=1
mkdir /tmp/modules/selinux
curl -L 'https://forge.puppet.com/v3/files/puppet-selinux-1.6.1.tar.gz' | tar -xz -C /tmp/modules/selinux --strip-components=1
mkdir /tmp/modules/systemd
curl -L 'https://forge.puppet.com/v3/files/camptocamp-systemd-2.6.0.tar.gz' | tar -xz -C /tmp/modules/systemd --strip-components=1
mkdir /tmp/modules/r10k
curl -L 'https://forge.puppet.com/v3/files/puppet-r10k-9.0.0.tar.gz' | tar -xz -C /tmp/modules/r10k --strip-components=1
mkdir /tmp/modules/git
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-git-0.5.0.tar.gz' | tar -xz -C /tmp/modules/git --strip-components=1
mkdir /tmp/modules/inifile
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-inifile-5.0.1.tar.gz' | tar -xz -C /tmp/modules/inifile --strip-components=1
mkdir /tmp/modules/translate
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-translate-2.2.0.tar.gz' | tar -xz -C /tmp/modules/translate --strip-components=1
mkdir /tmp/modules/ruby
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-ruby-1.0.1.tar.gz' | tar -xz -C /tmp/modules/ruby --strip-components=1
mkdir /tmp/modules/vcsrepo
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-vcsrepo-4.0.1.tar.gz' | tar -xz -C /tmp/modules/vcsrepo --strip-components=1
mkdir /tmp/modules/nginx
curl -L 'https://forge.puppet.com/v3/files/puppet-nginx-3.0.0.tar.gz' | tar -xz -C /tmp/modules/nginx --strip-components=1
mkdir /tmp/modules/php
curl -L 'https://forge.puppet.com/v3/files/puppet-php-7.1.0.tar.gz' | tar -xz -C /tmp/modules/php --strip-components=1



# install r10k gem
/opt/puppetlabs/puppet/bin/gem install r10k

# setup eyaml to work
/opt/puppetlabs/bin/puppetserver gem install eyaml
wget -O /tmp/eyaml.zip 'https://github.com/icroseland/demo_eyaml/archive/refs/heads/main.zip'
unzip /tmp/eyaml.zip -d /etc/puppetlabs
mv /etc/puppetlabs/demo_eyaml-main /etc/puppetlabs/eyaml
rm -f /tmp/eyaml.zip

#/opt/puppetlabs/bin/puppet apply --modulepath=/tmp/modules -e "class { selinux: mode => 'permissive',}"
/opt/puppetlabs/bin/puppet apply --modulepath=/tmp/modules -e "include start_master::setup_master"

