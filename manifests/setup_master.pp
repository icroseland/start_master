class start_master::setup_master(
  $user                    = 'puppet',
  $group                   = 'puppet',
  $ip                      = $facts['networking']['ip'],
  $environment             = 'production',
  $r10k_name               = 'puppet',
  $r10k_remote             = 'https://github.com/icroseland/demo-control.git',
  $r10k_invalid_branches   = 'correct',
  $r10k_basedir            = '/etc/puppetlabs/code/environments/',
  $distro                  = $facts['os']['family'],
  $fqdn                    = $facts['networking']['fqdn'],
){


#exec { 'detect_php_version':
#  command => "php -r 'echo PHP_MAJOR_VERSION.\".\".PHP_MINOR_VERSION;' > /etc/php_version",
#  creates => '/etc/php_version',
#  path    => ['/bin','/usr/bin'],
#}
#$php_version = file('/etc/php_version')
$php_version = inline_template("<%= `php -r 'echo PHP_MAJOR_VERSION.\".\".PHP_MINOR_VERSION;' 2>/dev/null`.strip %>")

class { 'php::globals':
    php_version => $php_version,
    #require     => Exec['detect_php_version'],
  }

  # ---- r10k config structure ----
  $r10k_configured = {
    'sources' => {
      $r10k_name => {
        'remote'           => $r10k_remote,
        'basedir'          => $r10k_basedir,
        'invalid_branches' => $r10k_invalid_branches,
      }
    }
  }

  # ---- defaults ----
  File {
    owner => $user,
    group => $group,
  }

  # ---- OS handling ----
  case $distro {
    'RedHat': {
      service { 'firewalld':
        ensure => stopped,
        enable => false,
      }

      $puser = 'nginx'
      $pgroup = 'nginx'
    }

    'Debian': {
      $puser = 'www-data'
      $pgroup = 'www-data'
    }

    default: {
      fail("Unsupported OS family: ${distro}")
    }
  }

  # ---- Puppet Server ----
  package { 'hiera-eyaml':
    ensure   => installed,
    provider => 'puppetserver_gem',
  }

  class { '::puppet':
    server                => true,
    agent                 => true,
    server_foreman        => false,
    server_reports        => 'store',
    server_external_nodes => '',
    environment           => $environment,
    autosign              => true,
  }

  file { ['/etc/facter', '/etc/facter/facts.d']:
    ensure => directory,
  }

  file { '/etc/facter/facts.d/puppetmaster.txt':
    ensure  => file,
    content => "profile=puppetmaster\npuppet_type=puppetmaster\npuppetenv=production\n",
  }

  # ---- r10k ----
  exec { 'install_r10k_gem':
    command => '/opt/puppetlabs/puppet/bin/gem install r10k',
    creates => '/opt/puppetlabs/puppet/bin/r10k',
    path    => ['/bin','/usr/bin','/usr/local/bin'],
  }

  file { '/etc/puppetlabs/r10k':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/puppetlabs/r10k/r10k.yaml':
    ensure  => file,
    content => template('start_master/etc/puppetlabs/r10k/r10k.yaml.erb'),
    owner   => 'root',
    group   => 'root',
  }

  exec { 'deploy environments':
    command     => '/opt/puppetlabs/puppet/bin/r10k deploy environment -p',
    refreshonly => true,
    subscribe   => File['/etc/puppetlabs/r10k/r10k.yaml'],
  }

  exec { 'chown environments':
    command => 'chown -R puppet:puppet /etc/puppetlabs/code/environments',
    path    => ['/bin','/usr/bin'],
  }

  package { 'git':
    ensure => present,
  }

  # ---- eyaml ----
  file { '/etc/puppetlabs/eyaml':
    ensure => directory,
    mode   => '0700',
  }

  file { '/etc/puppetlabs/eyaml/keys':
    ensure => directory,
    mode   => '0700',
  }

  file { '/etc/puppetlabs/eyaml/keys/private_key.pkcs7.pem':
    ensure => file,
    mode   => '0400',
  }

  file { '/etc/puppetlabs/eyaml/keys/public_key.pkcs7.pem':
    ensure => file,
    mode   => '0444',
  }

  # ---- web content ----
  file { '/etc/puppetlabs/www':
    ensure => directory,
    mode   => '0755',
  }

  file { '/etc/puppetlabs/www/client.php':
    ensure  => file,
    mode    => '0644',
    content => epp('start_master/etc/puppetlabs/www/client.php.epp'),
  }

  file { '/etc/puppetlabs/www/inventory.sh':
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/start_master/puppetlabs/www/inventory.sh',
  }

  file { '/etc/puppetlabs/www/inventory.php':
    ensure => file,
    mode   => '0644',
    source => 'puppet:///modules/start_master/puppetlabs/www/inventory.php',
  }

  exec { 'fix_inventory_sh':
    command => "/usr/bin/sed -i 's/XXXZZZXXX/${fqdn}/g' /etc/puppetlabs/www/inventory.sh",
    unless  => "/usr/bin/grep ${fqdn} /etc/puppetlabs/www/inventory.sh",
    path    => ['/bin','/usr/bin'],
    require => File['/etc/puppetlabs/www/inventory.sh'],
  }

  # ---- PHP / NGINX ----

  $php_sock    = "/run/php/php${php_version}-fpm.sock"

  class { 'nginx':
    manage_repo => true,
  }

  class { 'php':
    ensure       => present,
    manage_repos => false,
    fpm          => true,
    dev          => false,
    composer     => false,
    pear         => true,
    phpunit      => false,
    fpm_user     => $puser,
    fpm_group    => $pgroup,
  }

  php::fpm::pool { $fqdn:
    ensure       => present,
    user         => $puser,
    group        => $pgroup,
    listen_owner => $puser,
    listen_group => $pgroup,
    listen_mode  => '0660',
    listen       => $php_sock,
    require      => Class['php'],
  }

  nginx::resource::server { $fqdn:
    ensure    => present,
    www_root  => '/etc/puppetlabs/www',
    autoindex => 'on',
    require   => Class['nginx'],
  }

  nginx::resource::location { "${fqdn}_php":
    ensure      => present,
    server      => $fqdn,
    location    => '~ \.php$',
    www_root    => '/etc/puppetlabs/www',
    index_files => ['index.php'],
    fastcgi     => "unix:${php_sock}",
    include     => ['fastcgi.conf'],
    require     => Php::Fpm::Pool[$fqdn],
  }

  # ---- misc ----
  file { '/home/inventory_data':
    ensure => directory,
    owner  => $puser,
    group  => $pgroup,
    mode   => '0755',
  }

}
