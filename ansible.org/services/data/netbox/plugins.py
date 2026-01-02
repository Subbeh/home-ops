"""
NetBox Plugins Configuration

To install plugins:
1. Build a custom Docker image with the plugin installed
   See: https://github.com/netbox-community/netbox-docker/wiki/Using-Netbox-Plugins
2. Enable the plugin by uncommenting the PLUGINS list below
3. Configure plugin settings in PLUGINS_CONFIG

Example plugins:
- netbox-topology-views: Network topology visualization
- netbox-dns: DNS management
- netbox-secretstore: Enhanced secrets management
- netbox-bgp: BGP peering management
"""

# List of installed plugins
# PLUGINS = [
#     'netbox_topology_views',
#     'netbox_dns',
# ]

# Plugin configuration settings
# PLUGINS_CONFIG = {
#     'netbox_topology_views': {
#         'static_image_directory': 'netbox_topology_views/img',
#         'allow_coordinates_saving': True,
#     },
#     'netbox_dns': {
#         'zone_default_ttl': 86400,
#         'enable_rfc2317': True,
#     },
# }
