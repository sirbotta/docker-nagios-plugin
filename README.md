Docker nagios plugin
====================
Simple plugin for nagios that wrap the docker info command.   
It supports a fews critical and warning alerts like service status and ram issues.   
It follows the guidelines from this site https://www.monitoring-plugins.org/doc/guidelines.html

Install
-------
Clone the repository   
```git clone https://github.com/sirbotta/docker-nagios-plugin.git```

Install the dependecies   
```
cd docker-nagios-plugin
bundle install
```
Link or copy the script to your nagios plugins folder   
```ln -s docker_info.rb /usr/lib/nagios/plugins/check_docker.rb```

Wire up your script as usual in the nrpe server and nagios server. The plugin must be used with the check_nrpe command.  
NRPE server   
in `/etc/nagios/nrpe.cfg` add this line   
`command[check_docker]=/usr/lib/nagios/plugins/check_docker.rb`   
restart the nrpe server   
`sudo service nagios-nrpe-server restart`


NAGIOS server   
In your `/etc/nagios3/command.cfg` add something like
```
define command {
  command_name  check_docker
  command_line $user1$/check_nrpe -H $HOSTADDRESS$ -c check_docker
  }
```

In `/etc/nagios3/conf.d/your-host.cfg` add 
```
define service{
  use           generic-service
  host_name     your-host
  check_command check_docker
  }
```
restart nagios   
`sudo service nagios3 restart`

Usage
-----
`./docker_info.rb`   

or   
`ruby docker_info.rb`

if everything is correct the result should be like this
`DOCKERINFO OK: StorageDriver is aufs ,RootDir is /var/lib/docker/aufs ,ExecutionDriver is native-0.1 ,KernelVersion is 3.11.0-15-generic|Containers=1 ,Images=4 ,Dirs=6`

also you can set up custom thresholds for containers with -w (warning) and -c (critical)   

rise warning if more of 10 containers are running in the docker server   
`./docker_info.rb -w10`

rise warning if more of 10 containers and rise a critical if 20 or more are running in the docker server   
`./docker_info.rb -w10 -c20`

Default response
----------------
OK if everything is under the thresholds (default unlimited)   
WARNING if [No swap limit] warning from docker or surpassed a warning threshold   
CRITICAL if permission denied on the nagios user, the docker daemon is not running or surpassed a critical threshold
