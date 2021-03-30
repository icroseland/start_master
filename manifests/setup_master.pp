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
$listen_to = undef
$pluginsync = true
$splay = false
$splaylimit = undef
$runinterval = undef
$runmode = undef
$report = true
$cron_cmd = undef
$systemd_cmd = undef
$agent_noop = false
$show_diff = true
$module_repository = undef
$hiera_config = '$confdir/hiera.yaml'
$usecacheonfailure = true
$ca_server = $::fqdn
$ca_port = 8140
$ca_crl_enable = true
$prerun_command = undef
$postrun_command = undef
$server_compile_mode = undef
$dns_alt_names = []
$use_srv_records = true
$pluginsource = 'puppet:///plugins'
$pluginfactsource = 'puppet:///pluginfacts'
$classfile = '$vardir/classes.txt'
$syslogfacility = undef
$environment = production
$server = true
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
  version                 => $version,
  user                    => $user,
  group                   => $group,
  port                    => $port,
  listen                  => $listen,
  listen_to               => $listen_to,
  pluginsync              => $pluginsync,
  splay                   => $splay,
  splaylimit              => $splaylimit,
  runinterval             => $runinterval,
  runmode                 => $runmode,
  cron_cmd                => $cron_cmd,
  systemd_cmd             => $systemd_cmd,
  agent_noop              => $agent_noop,
  show_diff               => $show_diff,
  module_repository       => $module_repository,
  hiera_config            => $hiera_config,
  usecacheonfailure       => $usecacheonfailure,
  ca_server               => $ca_server,
  ca_port                 => $ca_port,
  prerun_command          => $prerun_command,
  postrun_command         => $postrun_command,
  server_compile_mode     => $server_compile_mode,
  dns_alt_names           => $dns_alt_names,
  use_srv_records         => $use_srv_records,
  pluginsource            => $pluginsource,
  pluginfactsource        => $pluginfactsource,
  classfile               => $classfile,
  syslogfacility          => $syslogfacility,
  environment             => $environment,
  server                  => $server,
  server_ca               => $server_ca,
  server_ca_crl_sync      => $server_ca_crl_sync,
  server_reports          => $server_reports,
  server_external_nodes   => $server_external_nodes,
  server_enc_api          => $server_enc_api,
  server_report_api       => $server_report_api,
  server_request_timeout  => $server_request_timeout,
  server_certname         => $server_certname,
  server_strict_variables => $server_strict_variables,
  server_http             => $server_http,
  server_http_port        => $server_http_port,
  puppetmaster            => $mom_name,
  server_foreman          => $server_foreman,
  autosign_entries        => $autosign_entries
  }
}