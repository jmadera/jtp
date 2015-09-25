class jtp::tomcat {
  $tomcat_url = "http://apache.mirrors.pair.com/tomcat/tomcat-8/v8.0.26/src/apache-tomcat-8.0.26-src.tar.gz"

  package { "supervisor":
    ensure => installed,
  }
 
  package { "wget":
    ensure => installed,
  }

  exec { "check_tomcat_url":
    cwd       => "/tmp",
    command   => "wget -S --spider ${tomcat_url}",
    timeout   => 900,
    require   => Package["wget"],
    notify    => Exec["get_tomcat"],
    logoutput => "on_failure"
  }

  exec { "get_tomcat":
    cwd       => "/tmp",
    command   => "wget ${tomcat_url} -O tomcat.tar.gz > /opt/.tomcat_get_tomcat",
    creates   => "/opt/.tomcat_get_tomcat",
    timeout   => 900,
    require   => Package["wget"],
    notify    => Exec["extract_tomcat"],
    logoutput => "on_failure"
  }

  exec { "extract_tomcat":
    cwd         => "/root",
    command     => "tar zxf /tmp/tomcat.tar.gz ; mv apache* tomcat",
    creates     => "/root/tomcat",
    require     => Exec["get_tomcat"],
    refreshonly => true,
  }

  file { "/root/tomcat/conf/tomcat-users.xml":
    ensure  => present,
    content => "<?xml version='1.0' encoding='utf-8'?>
    <tomcat-users>
      <role rolename=\"manager-gui\" />
      <role rolename=\"manager-script\" />
      <role rolename=\"manager-jmx\" />
      <role rolename=\"manager-status\" />
      <user username=\"admin\" password=\"tomcat\" roles=\"manager-gui, manager-script, manager-jmx, manager-status\"/>
    </tomcat-users>",
    require => Exec["extract_tomcat"],
  }

  file { "/root/tomcat":
    ensure  => directory,
    owner   => "root",
    mode    => 0755,
    recurse => true,
    require => Exec["extract_tomcat"],
  }

  file { "/root/tomcat/bin/setenv.sh":
    ensure => present,
    owner  => "vagrant",
    mode   => 0755,
    content => '#!/bin/sh export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=192.168.33.10" export CATALINA_OPTS="$CATALINA_OPTS -agentlib:jdwp=transport=dt_socket,address=8000,server=y,suspend=n"
                  echo "Using CATALINA_OPTS:"
                  for arg in $CATALINA_OPTS
                  do
                      echo ">> " $arg
                      done
                      echo ""',
    require => Exec["extract_tomcat"],
  }

  file { "/etc/supervisor/conf.d/tomcat.conf":
    ensure  => present,
    content => "[program:tomcat]
      command=/root/tomcat/bin/catalina.sh run
      directory=/root/tomcat/bin
      autostart=no
      user=root
      stopsignal=QUIT",
    require => [ Package["supervisor"], File["/vagrant/tomcat/conf/tomcat-users.xml"] ],
    notify  => Exec["update_supervisor"],
  }

  exec { "update_supervisor":
    command     => "supervisorctl update",
    refreshonly => true,
  }
}
