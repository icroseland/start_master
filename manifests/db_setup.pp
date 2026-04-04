# install puppdb and postgres
#
class start_master::db_setup(
$puppetdb_server = $::fqdn,
$postgresql_server = $::fqdn
){
if ($puppetdb_server == $::fqdn) and ($postgresql_server == $:fqdn ){
  class { 'puppetdb': }
}
if ($puppetdb_server != $::fqdn) and ($postgresql_server == $:fqdn ){
  class { 'puppetdb::database::postgresql':
    listen_addresses => $postgres_server,
    postgresql_ssl_on => true,
    puppetdb_server => $puppetdb_server
    }
}
if ($puppetdb_server == $::fqdn) and ($postgresql_server =! $:fqdn ){
  class { 'puppetdb::server':
    database_host => $postgres_server,
    postgresql_ssl_on => true
    }
}
}
