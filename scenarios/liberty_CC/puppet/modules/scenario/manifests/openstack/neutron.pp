# Module:: scenario
# Manifest:: openstack/neutron.pp
#

class scenario::openstack::neutron (
  String $admin_password = $scenario::openstack::params::admin_password,
  String $primary_interface = $scenario::openstack::params::primary_interface
  String $controller_public_address = $scenario::openstack::params::controller_public_address
) inherits scenario::openstack::params {

  class { '::neutron::db::mysql':
    password => 'neutron',
    allowed_hosts => ['localhost', '127.0.0.1', '%']
  }
  class { '::neutron::keystone::auth':
    password => $admin_password,
    public_url   => "http://${controller_public_address}:9696",
    internal_url => "http://${controller_public_address}:9696",
    admin_url    => "http://${controller_public_address}:9696"
  }
  class { '::neutron':
    rabbit_user           => 'neutron',
    rabbit_password       => 'an_even_bigger_secret',
    rabbit_host           => '127.0.0.1',
    allow_overlapping_ips => true,
    core_plugin           => 'ml2',
    service_plugins       => ['router', 'metering'],
    debug                 => true,
    verbose               => true,
  }
  class { '::neutron::client': }
  class { '::neutron::server':
    database_connection => "mysql://neutron:neutron@${controller_public_address}/neutron?charset=utf8",
    auth_password       => $admin_password,
    identity_uri        => "http://${controller_public_address}:35357/",
    auth_uri            => "http://${controller_public_address}:5000",
    sync_db             => true,
  }
  class { '::neutron::plugins::ml2':
    type_drivers         => ['vxlan', 'flat', 'vlan'],
    tenant_network_types => ['vxlan', 'flat', 'vlan'],
    mechanism_drivers    => ['openvswitch'],
  }
  class { '::neutron::agents::ml2::ovs':
    enable_tunneling => true,
    local_ip         => $ipaddress_eth0,
    tunnel_types     => ['vxlan'],
    bridge_mappings  => ["public:br-ex"],
  }
  class { '::neutron::agents::metadata':
    debug         => true,
    auth_password => $admin_password,
    shared_secret => $admin_password,
  }
  class { '::neutron::agents::lbaas':
    debug => true,
  }
  class { '::neutron::agents::l3':
    debug => true,
  }
  class { '::neutron::agents::dhcp':
    debug => true,
  }
  class { '::neutron::agents::metering':
    debug => true,
  }
  class { '::neutron::server::notifications':
    nova_admin_password => $admin_password,
  }

}
