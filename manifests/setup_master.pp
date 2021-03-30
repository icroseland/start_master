# @install puppetmaster and configure
# we have no useful hiera yet!
class start_master::setup_master(
$packages = undef
$master_of_master = $::fqdn
$host_type = puppet_master
$version  = 'present'
$manage_user = true
$user = 'puppet'
$group = 'puppet'
$ip = $::ipaddress
$port = 8140
$listen = true
$pluginsync = true
$splay = false
$report = true
$agent_noop = false
$show_diff = true
$hiera_config = '$confdir/hiera.yaml'
$usecacheonfailure = true
$ca_server = $::fqdn
$ca_port = 8140
$ca_crl_enable = true
$dns_alt_names = []
$use_srv_records = true
$pluginsource = 'puppet:///plugins'
$pluginfactsource = 'puppet:///pluginfacts'
$classfile = '$vardir/classes.txt'
$environment = production
){
# setup facts to keep things sane.
file { ['/etc/facter', '/etc/facter/facts.d']:
  ensure => directory
  }->
file {'/etc/facter/facts.d/puppetmaster.txt':
  ensure  => file,
  content => "role=puppetmaster\npuppetenv=production\n"
  }
class { '::puppet':
  server                => true,
  server_foreman        => false,
  server_reports        => 'store',
  server_external_nodes => '',
  version                 => $version,
  user                    => $user,
  group                   => $group,
  port                    => $port,
  listen                  => $listen,
  pluginsync              => $pluginsync,
  splay                   => $splay,
  agent_noop              => $agent_noop,
  show_diff               => $show_diff,
  hiera_config            => $hiera_config,
  usecacheonfailure       => $usecacheonfailure,
  ca_server               => $ca_server,
  ca_port                 => $ca_port,
  dns_alt_names           => $dns_alt_names,
  use_srv_records         => $use_srv_records,
  pluginsource            => $pluginsource,
  pluginfactsource        => $pluginfactsource,
  classfile               => $classfile,
  environment             => $environment,
  autosign_entries        => $autosign_entries
  }
}
