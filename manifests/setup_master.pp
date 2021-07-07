# @install puppetmaster and configure
# we have no useful hiera yet!
class start_master::setup_master(
$user = 'puppet',
$group = 'puppet',
$ip = $::ipaddress,
$environment = 'production',
$r10k_name = 'puppet',
$r10k_remote = 'https://github.com/icroseland/demo-control.git',
$r10k_invalid_branches = 'correct',
$r10k_basedir = '/etc/puppetlabs/code/environments/',
$distro = $::os.name
){
# setup facts to keep things sane.
$r10k_configured = { sources => {
                      $r10k_name  => {
                        remote => $r10k_remote,
                        basedir => $r10k_basedir,
                        invalid_branches => $r10k_invalid_branches
                        }
                    }
} 

File {
  owner => $user,
  group => $group,
}
if $distro == 'Centos' {
  service { 'firewalld':
    ensure => stopped,
  }
}
class { '::puppet':
  server                  => true,
  agent                   => true,
  server_foreman          => false,
  server_reports          => 'store',
  server_external_nodes   => '',
  environment             => $environment,
  autosign                => true,
  }->
file { ['/etc/facter', '/etc/facter/facts.d']:
  ensure => directory
  }->
file {'/etc/facter/facts.d/puppetmaster.txt':
  ensure  => file,
  content => "profile=puppetmaster\npuppet_type=puppetmaster\npuppetenv=production\n",
  require => File['/etc/facter', '/etc/facter/facts.d'],
  }->
notify { 'Setting up r10k and puppet environments':}->
exec { 'chown environments':
  command => 'chown -R puppet: /etc/puppetlabs/code/environments',
  path    => '/bin:/usr/bin:/usr/local/bin'
  }
exec { 'install_r10k_gem':
  command => '/opt/puppetlabs/puppet/bin/gem install r10k',
  creates => '/opt/puppetlabs/puppet/bin/r10k',
  }
file { '/etc/puppetlabs/r10k': 
  ensure => directory,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
  }
file {'/etc/puppetlabs/r10k/r10k.yaml':
  ensure  => file,
  content => template('start_master/etc/puppetlabs/r10k/r10k.yaml.erb'),
  owner   => 'root',
  group   => 'root',
  }
package {'git':
  ensure => present,
  }
#ensure eyaml is working.
file {'/etc/puppetlabs/eyaml':
  mode => '0400',
}->
file {'/etc/puppetlabs/eyaml/keys':
  mode => '0400',
}->
file {'/etc/puppetlabs/eyaml/keys/private_key.pkcs7.pem':
  mode => '0400',
}->
file {'/etc/puppetlabs/eyaml/keys/public_key.pkcs7.pem':
  mode => '0400',
}->
exec { 'deploy environments':
  command => '/opt/puppetlabs/puppet/bin/r10k deploy environment -p',
  require => Exec['install_r10k_gem'],
  }
file {'/etc/puppetlabs/www':
  ensure => directory,
  mode   => '0555',
  }
file {'/etc/puppetlabs/www/client.php':
  ensure  => file,
  mode    => '0555',
  content => epp('start_master/etc/puppetlabs/www/client.php.epp'),
  require => File['/etc/puppetlabs/www'],
}
file {'/etc/puppetlabs/www/inventory.sh':
  ensure  => file,
  mode    => '0555',
  source  => 'puppet:///modules/start_master/puppetlabs/www/inventory.sh',
  require => File['/etc/puppetlabs/www'],
}
file {'/etc/puppetlabs/www/inventory.php':
  ensure  => file,
  mode    => '0555',
  source  => 'puppet:///modules/start_master/puppetlabs/www/inventory.php',
  require => File['/etc/puppetlabs/www'],
}
exec {'fix_inventory_sh':
  commmand => "/usr/bin/sed -i 's/XXXZZZXXX/${::fqdn}/g' /etc/puppetlabs/www/inventory.sh",
  cwd      => '/etc/puppetlabs/www',
  unless   => '/usr/bin/grep ${::fqdn} /etc/puppetlabs/www/inventory.sh',
  require  => File['/etc/puppetlabs/www/inventory.sh'],
  }
class { 'php':
   ensure       => 'present',
   manage_repos => false,
   fpm          => true,
   dev          => false,
   composer     => false,
   pear         => true,
   phpunit      => false,
   fpm_user     => 'nginx',
   fpm_group    => 'nginx',
   fpm_pools    => {},
}
group { 'http':
  ensure => present
}
user { 'http':
  ensure  => present,
  comment => 'make php work',
  shell   => '/sbin/nologin',
  gid     => 'http',
}

file { '/home/nginx':
  ensure => 'directory',
  owner  => 'nginx',
  group  => 'nginx',
  mode   => '0755'
  }

include nginx

nginx::resource::server{ $::fqdn:
  ensure    => present,
  www_root  => '/etc/puppetlabs/www',
  autoindex => 'on',
  }  
php::fpm::pool{$::fqdn:
  user         => 'nginx',
  group        => 'nginx',
  listen_owner => 'nginx',
  listen_group => 'nginx',
  listen_mode  => '0666',
  listen       => "/var/run/php-fpm/nginx-fpm.sock",
  }
nginx::resource::location { "${::fqdn}_root":
  ensure         => 'present',
  server         => $::fqdn,
  www_root       => '/etc/puppetlabs/www',
  location       => '~ \.php$',
  index_files    => ['index.php'],
  fastcgi        => "unix:/var/run/php-fpm/nginx-fpm.sock",
  fastcgi_script => undef,
  include        => ['fastcgi.conf'],
  }

}
