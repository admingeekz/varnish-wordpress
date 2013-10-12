varnish-wordpress
=================

##Overview
This is a plugin for wordpress to intergrate the varnish cache for high performance websites.

This plugin will purge the cache on,

- Post changes (new, edit, trash, delete).
- Page changes (add, edit, remove)
- Comment changes (add, edit, approve,  unapprove,  spam,  trash,  delete)
- Theme changes

##Features

At present some of the features are,

- Multiple varnish backends
- Manually purge the cache
- Enable/Disable Feed Purging
- Ability to purge entire cache on changes
- Debug logging
- Minimize number of purges and remove duplicate purges for speed on larger installations
- Actively maintained

##Speed

Our tests show that by utilizing varnish you gain a ~70x capacity increase making you resistant to traffic floods (slashdot,  digg, reddit,  stumbleupon)

## Installation

See the INSTALL document for instructions
