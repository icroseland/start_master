class start_master::setup_master(
  $user                    = 'puppet',
  $group                   = 'puppet',
  $ip                      = $facts['networking']['ip'],
  $environment             = 'production',
  $r10k_name               = 'puppet',
  $r10k_remote             = '[github.com](https://github.com/icroseland/demo-control.git)',
  $r10k_invalid_branches   = 'correct',
  $r10k_basedir            = '/etc/puppetlabs/code/environments/',
  $distro                  = $facts['os']['family'],
  $fqdn                    = $facts['networking']['fqdn'],
){

  $php_version = inline_template("<%= `php -r 'echo PHP_MAJOR_VERSION.\".\".PHP_MINOR_VERSION;' 2>/dev/null`.strip %>")
  $php_sock    = "/run/php/php${php_version}-fpm.sock"
  
  $puser = $distro ? {
    'RedHat' => 'nginx',
    'Debian' => 'www-data',
    default  => fail("Unsupported OS family: ${distro}"),
  }
  $pgroup = $puser

  File { owner => $user, group => $group }

  # ---- PRE-WEBSTACK ----
  package { 'git': ensure => present } ->
  class { 'php::globals': php_version => $php_version } ->
  package { 'hiera-eyaml': ensure => installed, provider => 'puppetserver_gem' } ->
  class { '::puppet':
    server                => true, agent                 => true,
    server_foreman        => false, server_reports        => 'store',
    server_external_nodes => '', environment           => $environment,
    autosign              => true,
  } ->
  file { ['/etc/facter', '/etc/facter/facts.d']: ensure => directory } ->
  file { '/etc/facter/facts.d/puppetmaster.txt':
    ensure  => file,
    content => "profile=puppetmaster\npuppet_type=puppetmaster\npuppetenv=production\n",
  } ->
  exec { 'install_r10k_gem':
    command => '/opt/puppetlabs/puppet/bin/gem install r10k',
    creates => '/opt/puppetlabs/puppet/bin/r10k',
    path    => ['/bin','/usr/bin','/usr/local/bin'],
  } ->
  file { '/etc/puppetlabs/r10k': ensure => directory, owner => 'root', group => 'root', mode => '0755' } ->
  file { '/etc/puppetlabs/r10k/r10k.yaml':
    ensure  => file,
    content => template('start_master/etc/puppetlabs/r10k/r10k.yaml.erb'),
    owner   => 'root', group => 'root',
  } ~>
  exec { 'deploy environments': command => '/opt/puppetlabs/puppet/bin/r10k deploy environment -p', refreshonly => true } ->
  exec { 'chown environments': command => 'chown -R puppet:puppet /etc/puppetlabs/code/environments', path => ['/bin','/usr/bin'] } ->
  file { '/etc/puppetlabs/eyaml': ensure => directory, mode => '0700' } ->
  file { '/etc/puppetlabs/eyaml/keys': ensure => directory, mode => '0700' } ->
  file { '/etc/puppetlabs/eyaml/keys/private_key.pkcs7.pem': ensure => file, mode => '0400' } ->
  file { '/etc/puppetlabs/eyaml/keys/public_key.pkcs7.pem': ensure => file, mode => '0444' } ->

  # ---- WEB CONTENT ----
  file { '/etc/puppetlabs/www': ensure => directory, mode => '0755' } ->
  file { '/etc/puppetlabs/www/client.php': ensure => file, mode => '0644', content => epp('start_master/etc/puppetlabs/www/client.php.epp') } ->
  file { '/etc/puppetlabs/www/inventory.sh': ensure => file, mode => '0755', source => 'puppet:///modules/start_master/puppetlabs/www/inventory.sh' } ->
  exec { 'fix_inventory_sh':
    command => "/usr/bin/sed -i 's/XXXZZZXXX/${fqdn}/g' /etc/puppetlabs/www/inventory.sh",
    unless  => "/usr/bin/grep ${fqdn} /etc/puppetlabs/www/inventory.sh",
    path    => ['/bin','/usr/bin'],
  } ->
  file { '/etc/puppetlabs/www/inventory.php': ensure => file, mode => '0644', source => 'puppet:///modules/start_master/puppetlabs/www/inventory.php' } ->

  # ---- WEBSTACK (separate class) ----
  class { 'start_master::webstack':
    php_sock => $php_sock,
    user     => $puser,
        => $pgroup,
    fqdn     => $fqdn,
  }

  # ---- FINAL ----
  Class['start_master::webstack'] ->
  file { '/home/inventory_data':
    ensure => directory,
    owner  => $puser,
    group  => $pgroup,
    mode   => '0755',
  }
}
