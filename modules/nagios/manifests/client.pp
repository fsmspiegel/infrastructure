class nagios::client($server_address) {
  package {['nagios-nrpe-server', 'vnstat']: ensure => present}

  file {'/etc/nagios/nrpe.cfg':
    mode => 644,
    owner => root,
    group => root,
    content => template('nagios/nrpe.cfg.erb'),
    require => Package['nagios-nrpe-server']
  }
  
  service {'nagios-nrpe-server':
    ensure => running,
    enable => true,
    subscribe => File['/etc/nagios/nrpe.cfg']
  }

  file {'/usr/lib/nagios/plugins/check_bandwidth':
    ensure => present,
    mode => 755,
    owner => root,
    group => root,
    source => 'puppet:///modules/nagios/check_bandwidth'
  }
}
