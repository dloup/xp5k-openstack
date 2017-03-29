# Module:: scenario
# Manifest:: openstack/nova.pp
#

class scenario::openstack::nova (
  String $admin_password = $scenario::openstack::params::admin_password,
  String $controller_public_address = $scenario::openstack::params::controller_public_address
) inherits scenario::openstack::params {

  class {
    '::nova::db::mysql':
      password => 'nova',
      allowed_hosts => ['localhost', '127.0.0.1', '%']
  }

  class {
    '::nova::keystone::auth':
      password => $admin_password,
      public_url   => "http://${controller_public_address}:8774/v2/%(tenant_id)s",
      internal_url   => "http://${controller_public_address}:8774/v2/%(tenant_id)s",
      admin_url   => "http://${controller_public_address}:8774/v2/%(tenant_id)s"
  }

  file {
    '/tmp/nova':
      ensure => directory;
    ['/tmp/nova/images', '/tmp/nova/instances']:
      ensure  => directory,
      owner   => nova,
      group   => nova,
      require => File['/tmp/nova'];
  }

  mount {
    '/var/lib/nova/instances':
      ensure  => mounted,
      device  => '/tmp/nova/instances',
      fstype  => 'none',
      options => 'rw,bind';
    '/var/lib/nova/images':
      ensure  => mounted,
      device  => '/tmp/nova/images',
      fstype  => 'none',
      options => 'rw,bind',
  }

  Package['nova-common'] -> File['/tmp/nova/images'] -> Mount['/var/lib/nova/images']
  Package['nova-common'] -> File['/tmp/nova/instances'] -> Mount['/var/lib/nova/instances']

  class {
    '::nova':
      database_connection => "mysql://nova:nova@${controller_public_address}/nova?charset=utf8",
      rabbit_host         => "${controller_public_address}",
      rabbit_userid       => 'nova',
      rabbit_password     => 'an_even_bigger_secret',
      glance_api_servers  => "${controller_public_address}:9292",
      verbose             => true,
      debug               => true;
  }

  class {
    '::nova::api':
      admin_password                       => $admin_password,
      identity_uri                         => "http://${controller_public_address}:35357/",
      osapi_v3                             => true,
      neutron_metadata_proxy_shared_secret => $admin_password,
  }

  class { '::nova::cert': }
  class { '::nova::client': }
  class { '::nova::conductor': }
  class { '::nova::consoleauth': }
  class { '::nova::cron::archive_deleted_rows': }

  class {
    '::nova::compute':
      #vnc_keymap  => 'fr',
      vnc_enabled => true;
  }

  class { '::nova::compute::libvirt':
    libvirt_virt_type => 'kvm',
    migration_support => true,
    vncserver_listen  => '0.0.0.0',
  }
  class { '::nova::scheduler': }
  class { '::nova::vncproxy': }
  class { '::nova::network::neutron':
    neutron_admin_password => $admin_password,
    neutron_admin_auth_url => 'http://127.0.0.1:35357/v2.0',
  }

}
