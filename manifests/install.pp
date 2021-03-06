# Author::    Liam Bennett (mailto:lbennett@opentable.com)
# Copyright:: Copyright (c) 2013 OpenTable Inc
# License::   MIT

# == Class rundeck::install
#
# This private class installs the rundeck package and it's dependencies
#
class rundeck::install(
  $jre_name           = $rundeck::jre_name,
  $jre_ensure         = $rundeck::jre_ensure,
  $package_source     = $rundeck::package_source,
  $package_ensure     = $rundeck::package_ensure,
) {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  ensure_resource('package', $jre_name, {'ensure' => $jre_ensure} )

  case $::osfamily {
    'RedHat': {

      yumrepo { 'bintray-rundeck':
        baseurl  => 'http://dl.bintray.com/rundeck/rundeck-rpm/',
        descr    => 'bintray rundeck repo',
        enabled  => '1',
        gpgcheck => '0',
        priority => '1',
        before   => Package["rundeck"],
      }

      ensure_resource('package', "rundeck", {'ensure' => $package_ensure} )
    }
    'Debian': {
      
      $version = inline_template("<% package_version = '${package_ensure}' %><%= package_version.split('-')[0] %>")

      exec { 'download rundeck package':
        command => "/usr/bin/wget ${package_source}/rundeck-${package_ensure}.deb -O /tmp/rundeck-${package_ensure}.deb",
        unless  => "/usr/bin/test -f /tmp/rundeck-${package_ensure}.deb"
      }

      exec { 'install rundeck package':
        command => "/usr/bin/dpkg --force-confold -i /tmp/rundeck-${package_ensure}.deb",
        unless  => "/usr/bin/dpkg -l | grep rundeck | grep ${version}",
        require => [ Exec['download rundeck package'], Package[$jre_name] ]
      }

    }
    default: {
      err("The osfamily: ${::osfamily} is not supported")
    }
  }
}
