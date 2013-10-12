To install the WordPress plugin.

- Get the latest version from https://www.admingeekz.com/files/varnish-wordpress.tar.gz
- Copy the varnish-wordpress folder to wp-content/plugins/
- Login to wp-admin
- Go to "Plugins"->"Add New" on the left menu
- Under "Varnish WordPress" click "Activate"
- You should now see the varnish menu under "Settings"

To install the varnish VCL.

- Copy the file "default.vcl" provided with this plugin  to your varnish installation path (/etc/varnish/default.vcl on most systems)
- Configure the backend in the default.vcl to point to the port your webserver(s) are running on
- Restart varnish


To configure the WordPress plugin

- In the varnish backends box input the backends we need to access to purge the cache.
-- Format:  ip:port

- Check the enabled box

- Click Save

The setup should be complete.   You can enable Debug Logging temporarily to monitor what the plugin is doing.   Test by enabling debug logging and adding a new post.


