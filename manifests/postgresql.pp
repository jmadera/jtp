class jtp::postgresql {
  class { 'postgresql': }

  class { 'postgresql::server':
    listen => ['*', ],
    port   => 5432,
    acl    => ['host all all 0.0.0.0/0 md5', ],  
  }

  pg_database { ['sigenu_db']:
    ensure   => present,
    encoding => 'UTF8',
    require  => Class['postgresql::server']
  }

  pg_user { 'jmadera':
    ensure    => present,
    require   => Class['postgresql::server'],
    superuser => true,
    password  => 'qwerty12'
  }

  pg_user { 'postgre':
    ensure     => present,
    superuser  => true,
    require    => Class['postgresql::server']
  }

  package { 'libpq-dev':
    ensure => installed
  }

  package { 'postgresql-contrib':
    ensure  => installed,
    require => Class['postgresql::server'],
  }
}
