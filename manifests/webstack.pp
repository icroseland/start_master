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

  # ---- NGINX: completely standalone ----
  class { 'nginx':
    manage_repo => true,
  }

  # ---- PHP: completely standalone ----
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

  # ---- /run/php: standalone, only anchored inside php internals ----
  file { '/run/php':
    ensure  => directory,
    owner   => $puser,
    group   => $pgroup,
    mode    => '0755',
    require => Class['php::packages'],
    before  => Class['php::fpm::service'],
  }

  # ---- NGINX RESOURCES: require both classes but no -> chaining ----
  nginx::resource::server { $fqdn:
    ensure    => present,
    www_root  => '/etc/puppetlabs/www',
    autoindex => 'on',
    require   => [ Class['nginx'], Class['php'] ],
  }

  nginx::resource::location { "${fqdn}_php":
    ensure      => present,
    server      => $fqdn,
    location    => '~ \.php$',
    www_root    => '/etc/puppetlabs/www',
    index_files => ['index.php'],
    fastcgi     => "unix:${php_sock}",
    include     => ['fastcgi.conf'],
    require     => Nginx::Resource::Server[$fqdn],
  }
}
