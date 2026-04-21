class start_master::webstack(
  $php_sock,
  $puser,
  $pgroup,
  $fqdn,
) {
  # FIREWALL FIRST
  if $facts['os']['family'] == 'RedHat' {
    service { 'firewalld':
      ensure => stopped,
      enable => false,
    }
  }

  # NGINX CLASS (handles its own service)
  class { 'nginx':
    manage_repo => true,
  }

  # PHP CLASS (handles its own FPM service) 
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

  # NGINX RESOURCES AFTER BOTH CLASSES
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
