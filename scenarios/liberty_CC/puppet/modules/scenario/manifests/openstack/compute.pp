# Module:: scenario
# Manifest:: openstack/nova.pp
#


class scenario::openstack::compute (
  String $admin_password = $scenario::openstack::params::admin_password,
  String $controller_public_address = $scenario::openstack::params::controller_public_address,
  String $storage_public_address = $scenario::openstack::params::storage_public_address,
  String $data_network = $scenario::openstack::params::data_network
) inherits scenario::openstack::params {

  
  # common config between controller and computes
  #class { '::scenario::common::nova': 
  #  controller_public_address => $controller_public_address,
  #  storage_public_address    => $storage_public_address
  #}
  # Copy common/nova.pp here :
  class {
    '::nova':
      database_connection => "mysql://nova:nova@${controller_public_address}/nova?charset=utf8",
      rabbit_host         => $controller_public_address,
      rabbit_userid       => 'nova',
      rabbit_password     => 'an_even_bigger_secret',
      glance_api_servers  => "${storage_public_address}:9292",
      verbose             => true,
      debug               => true,
  }
  class { '::nova::network::neutron':
    neutron_admin_password => $admin_password,
    neutron_admin_auth_url => "http://${controller_public_address}:35357/v2.0",
    neutron_url => "http://${controller_public_address}:9696",
  }
  # End Copy

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

  #class {'::scenario::common::neutron':
  #  controller_public_address => $controller_public_address
  #}
  # Copy common/neutron.pp here :
  class { '::neutron':
    rabbit_user           => 'neutron',
    rabbit_password       => 'an_even_bigger_secret',
    rabbit_host           =>  $controller_public_address,
    allow_overlapping_ips => true,
    core_plugin           => 'ml2',
    service_plugins       => ['router', 'metering'],
    debug                 => true,
    verbose               => true,
  }

  class { '::neutron::plugins::ml2':
    type_drivers         => ['vxlan', 'flat', 'vlan'],
    tenant_network_types => ['vxlan', 'flat', 'vlan'],
    mechanism_drivers    => ['openvswitch'],
  }
  # End Copy

  class { '::neutron::agents::ml2::ovs':
    enable_tunneling => true,
    local_ip         => $ipaddress_eth0,
    enabled          => true,
    tunnel_types     => ['vxlan'],
  }

  # Bind to /tmp to get some space
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

}
