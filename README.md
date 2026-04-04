

# START_MASTER install configure and startup a master from nothing.


This is only kind of a module, as it is meant to be run on a host that currently is unmanaged and build a fully functional puppetmaster then setup a tool to install clients to other hosts  From there puppet itself will take over to self manage the master and of course all of the clients.

## Requirements

*  https://forge.puppet.com must be reachable from this host ( all puppetmodules come from forge )
*  https://github.com/ must be reachable as setup will load start_master from the forge
*  ruby gems will be loaded from the usual places. 
*  DNS! name service for the host needs to be working or at bare minimum, add the hosts to /etc/hosts
*  There is good news on DNS, the hosts have any name and this will still work.
*  Right now, this is also expecting the hosts to be Centos 8.  (see the to do)

## Running
*  on a newly installed host 
*  sudo - root
*  [root@hostname_master]#  git clone https://github.com/icroseland/start_master.git
*  [root@hostname_master]#  bash ./start_master/bin/deploy.sh
*  sit back and watch it run.  
*  login to a client host
*  [root@client_host]#   curl 'http://hostname_master/client.php?profile=webserver&collection=none&application=mktg&environment=production'  | bash
*  where profile is a valid profile defined by a hiera file in data/profiles/profile_name.yaml
*  where collection is a valid collection defined by a hiera file in data/collections/collection_name.yaml
*  where a application is a valid application defined in data/applications/application_name.yaml
*  with a puppet environment name
*  from here curl will grab and execute the client install from the puppetmaster and do the initial puppet run against the host.

