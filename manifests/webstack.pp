class start_master::webstack(
  $php_sock,
  $puser,
  $pgroup,
  $fqdn,
) {

  # ---- FIREWALL (RedHat only) ----
  if $facts['os']['family'] == 'RedHat' {
    service { 'firewalld':
      ensure => stopped,
      enable => false,
    }
  }

  # ---- CREATE /run/php BEFORE php-fpm starts ----
  file { '/run/php':
    ensure => directory,
    owner  => $puser,
    group  => $pgroup,
    mode   => '0755',
  }

  # ---- NGINX CLASS ----
  class { 'nginx':
    manage_repo => true,
  }

  # ---- PHP CLASS (after nginx and /run/php exist) ----
  Class['nginx'] ->
  File['/run/php'] ->
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

  # ---- NGINX RESOURCES (after php class completes) ----
  Class['php'] ->
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
