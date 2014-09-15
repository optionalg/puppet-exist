class exist::install inherits exist {

	##
	# Make sure that NTP is installed and running
	##	
	package { 'ntp': 
		ensure => installed
	}

	service { "ntpd":
		ensure => running,
		enable => true,
		pattern => 'ntpd',
		subscribe => Package["ntp"]
	}

	##
	# Create 'exist' user and group
	# and prevent SSH access by that user
	##
	group { "exist":
		ensure => present,
		system => true
	}

	user { "exist":
		ensure => present,
		system => true,
		gid => "exist",
		membership => minimum,
		managehome => true,
		shell => "/bin/bash",
		comment => "eXist Server",
		require => Group["exist"]
	}

	file { "/etc/ssh/sshd_config":
		ensure => present
	}->
	file_line { "deny exist ssh":
		line => "DenyUsers exist",
		path => "/etc/ssh/sshd_config",
	}

	##
	# Ensure eXist pre-requisite packages are installed
	##
	package { 'java-1.7.0-openjdk':
		ensure => installed,
	}

	package { 'java-1.7.0-openjdk-devel':
		ensure => installed,
	}

	package { 'git':
		ensure => installed,
	}

	##
	# Clone eXist from GitHub
	##
	vcsrepo { $exist_home:
		ensure => present,
		provider => git,
		source => "https://github.com/eXist-db/exist.git",
		revision => $exist_revision,
		require => Package["git"],
		before => File[$exist_home],
	}

	file { $exist_home:
		ensure => present,
		owner => "exist",
		group => "exist",
		mode => 700,
		recurse => true,
	}

	##
	# Build eXist from src
	##
	file { "${exist_home}/extensions/local.build.properties":
		ensure => present,
		source => "puppet:///modules/exist/local.build.properties",
		require => File[$exist_home],
	}

	exec { "build eXist":
		cwd => $exist_home,
		command => "${exist_home}/build.sh",
		timeout => 0,
		user => "exist",
		group => "exist",
		refreshonly => true,
		subscribe => Vcsrepo[$exist_home],
		require => File["${exist_home}/extensions/local.build.properties"],
	}

}
