class start_master::webstack(
  $php_sock,
  $puser,
  $pgroup,
  $fqdn,
  $full_web_path        = '/var/www',
  $backend_port         = 9000,
  $php                  = true,
  $proxy                = undef,
  $location_cfg_append  = undef,
  $hostname             = "${facts['networking']['hostname']}",
  $www_root             = "${full_web_path}/${hostname}/",
) {

  # ---- FIREWALL (RedHat only) ----
  if $facts['os']['family'] == 'RedHat' {
    service { 'firewalld':
      ensure => stopped,
      enable => false,
    }
  }

  nginx::resource::server { $fqdn:
    ensure                => present,
    www_root              => "${full_web_path}/${fqdn}/",
    location_cfg_append   => { rewrite => "^ [${fqdn}](https://${fqdn}\$request_uri) permanent" },
    spdy                  => 'off',
    http2                 => 'off',
    proxy_read_timeout    => '3m',
    proxy_connect_timeout => '3m',
    proxy_send_timeout    => '3m',
}

  if !$www_root {
    $tmp_www_root = undef
  } else {
    $tmp_www_root = $www_root
  }

  nginx::resource::server { "${fqdn} ${hostname}":
    ensure                => present,
    listen_port           => 443,
    www_root              => $tmp_www_root,
    proxy                 => $proxy,
    location_cfg_append   => $location_cfg_append,
    index_files           => [ 'index.php' ],
    ssl                   => true,
    ssl_cert              => '/path/to/wildcard_mydomain.crt',
    ssl_key               => '/path/to/wildcard_mydomain.key',
    }


  if $php {
    nginx::resource::location { "${hostname}_root":
      ensure          => present,
      ssl             => true,
      ssl_only        => true,
      server          => "${fqdn} ${hostname}",
      www_root        => "${full_web_path}/${hostname}",
      location        => '~ \.php$',
      index_files     => ['index.php', 'index.html', 'index.htm'],
      proxy           => undef,
      fastcgi         => "127.0.0.1:${backend_port}",
      fastcgi_script  => undef,
      location_cfg_append => {
        fastcgi_connect_timeout => '3m',
        fastcgi_read_timeout    => '3m',
        fastcgi_send_timeout    => '3m'
      }
    }
  }
}
