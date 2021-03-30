#!/bin/bash
# run as root on the intended puppet master
# no git ssh required for this to work against the public repos.


yum update -y
yum install wget -y
yum install git -y
rpm -Uvh http://yum.puppet.com/puppet7/puppet7-release-el-8.noarch.rpm


mkdir -p /tmp/modules
cd /tmp/modules
yum install puppet-agent -y
echo 'setting up base directory structure'
/opt/puppetlabs/bin/puppet apply -e  "file { '/tmp/modules': ensure => directory }"

mkdir /tmp/modules/start_master
echo 'loading modules from puppetlabs'
mkdir /tmp/modules/stdlib
curl -L 'https://forge.puppet.com/v3/files/puppetlabs-stdlib-5.1.0.tar.gz' | tar -xz -C /tmp/modules/stdlib --strip-components=1
mkdir /tmp/modules/puppet
curl -L 'https://forge.puppet.com/v3/files/theforeman-puppet-12.0.1.tar.gz' | tar -xz -C /tmp/modules/puppet --strip-components=1
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

#disable selinux as its an annoyance for a demo right now.

#/opt/puppetlabs/bin/puppet apply --modulepath=/tmp/modules -e "class { selinux: mode => 'permissive',}"
/opt/puppetlabs/bin/puppet apply --modulepath=/tmp/modules -e "start_master::setup_master"


/opt/puppetlabs/puppet/bin/gem install r10k

#/opt/puppetlabs/bin/puppet apply --modulepath=/tmp/modules -e "class { puppet_master::installer::setup_r10k:}"
