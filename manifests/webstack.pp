class start_master::webstack(
  $php_sock,
  $puser,
  $pgroup,
  $fqdn,
) {
  # 1. FIREWALL (RedHat)
  if $facts['os']['family'] == 'RedHat' {
    service { 'firewalld':
      ensure => stopped,
      enable => false,
    }
  }

  # 2. NGINX FIRST
  class { 'nginx':
    manage_repo => true,
  }

  # 3. PHP SECOND
  Class['nginx'] ->
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

  # 4. SERVICES BEFORE CONFIGS
  Class['php'] ->
  Service['nginx'] ->
  Service['php-fpm']

  # 5. NGINX CONFIGS LAST
  Service['php-fpm'] ->
  nginx::resource::server { $fqdn:
    ensure    => present,
    www_root  => '/etc/puppetlabs/www',
    autoindex => 'on',
  } ->
  nginx::resource::location { "${fqdn}_php":
    ensure      => present,
    server      => $fqdn,
    location    => '~ \.php$',
    www_root    => '/etc/puppetlabs/www',
    index_files => ['index.php'],
    fastcgi     => "unix:${php_sock}",
    include     => ['fastcgi.conf'],
  }
}
