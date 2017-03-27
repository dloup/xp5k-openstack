# Module:: scenario
# Manifest:: openstack/param.pp
#

class scenario::openstack::params {

  $admin_password = 'admin'
  $primary_interface = 'eth0'
  $controller_public_address = hiera("scenario::openstack::controller_public_address")

  case $::osfamily {
    'Debian': {
      include ::apt
      class { '::openstack_extras::repo::debian::ubuntu':
        release         => 'liberty',
        repo            => 'proposed',
        package_require => true,
      }
      $package_provider = 'apt'
    }
    default: {
      fail("Unsupported osfamily (${::osfamily})")
    }
  }


}
