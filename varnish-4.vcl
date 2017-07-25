vcl 4.0;

# Varnish 4 configuration for wordpress
# AdminGeekZ Ltd <sales@admingeekz.com>
# URL: www.admingeekz.com/varnish-wordpress
# Version: 1.6

#Configure the backend webserver
backend default {
    .host = "127.0.0.1";
    .port = "80";
    .probe = {
        .url = "/";
	.interval = 5s;
	.timeout = 30s;
        .window = 5;
        .threshold = 3;
    }
}

# Have separate backend for wp-admin for longer timesouts
backend wpadmin {
  .host = "127.0.0.1";
  .port = "80";
  .first_byte_timeout = 500000s;
  .between_bytes_timeout = 500000s;
    .probe = {
        .url = "/";
	.interval = 5s;
	.timeout = 15m;
        .window = 5;
        .threshold = 3;
    }
}

#Which hosts are allowed to PURGE the cache
acl purge {
  "127.0.0.1";
}

import directors;

sub vcl_init {
    new cluster1 = directors.round_robin();
    cluster1.add_backend(default);
    new cluster2 = directors.round_robin();
    cluster2.add_backend(wpadmin);
}

sub vcl_recv {
	set client.identity = req.http.cookie;
	set req.backend_hint = cluster1.backend();

	# Purge cache 
        if (req.method == "BAN") {
                if (!client.ip ~ purge) {
                        return(synth(403, "Not allowed."));
                }
		ban("req.url ~ "+req.url+" && req.http.host == "+req.http.host);
		return(synth(200, "Ban added"));
        }

	# Set X-Forwarded-For header.  You might want to check client.ip against ACL aswell.
	if (req.http.x-forwarded-for) {
                set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        }
	else {
		set req.http.X-Forwarded-For = client.ip;
        }

	# Set forwarded port if HTTPS,  override this if using another port
	if (req.http.X-Forwarded-Proto == "https" ) {
		set req.http.X-Forwarded-Port = "443";
	}


	# Remove the "has_js" cookie
	set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

	# Remove any Google Analytics based cookies
	set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");

	# Are there cookies left with only spaces or that are empty?
	if (req.http.cookie ~ "^ *$") {
		unset req.http.cookie;
	}

	if (req.method != "GET" && req.method != "HEAD") {
		/* We only deal with GET and HEAD by default */
		return (pass);
	}


	#Don't cache admin or login pages
	if (req.url ~ "wp-(login|admin)" || req.url ~ "preview=true") {
		return (pass);
	}

	#Don't cache logged in users
	if (req.http.Cookie && req.http.Cookie ~ "(wordpress_|wordpress_logged_in|comment_author_)") {
		return(pass);
	}

	#Don't cache ajax requests, urls with ?nocache or comments/login/regiser
	if(req.http.X-Requested-With == "XMLHttpRequest" || req.url ~ "nocache" || req.url ~ "(control.php|wp-comments-post.php|wp-login.php|register.php)") {
		return (pass);
	}

	if (req.http.Authorization) {
		# Not cacheable by default
	  return (pass);
	}

	#Set backend to wpadmin backend for longer timeouts
	if (req.url ~ "/wp-admin") {
		set req.backend_hint = cluster2.backend();
	}


	#Remove all cookies if none of the above match
	unset req.http.Max-Age;
	unset req.http.Pragma;
	unset req.http.Cookie;
	return (hash);
}

sub vcl_pipe {
	return (pipe);
}
 
sub vcl_pass {
	return (fetch);
}

# The data on which the hashing will take place
sub vcl_hash {
	hash_data(req.url);
	if (req.http.host) {
		hash_data(req.http.host);
	}
	else {
		hash_data(server.ip);
	}

	# If the client supports compression, keep that in a different cache
	if (req.http.Accept-Encoding) {
		hash_data(req.http.Accept-Encoding);
	}

	#HTTPS Support
	if  (req.http.X-Forwarded-Port) {
		hash_data(req.http.X-Forwarded-Port);
	}
	#Set the hash to include the cookie if it exists, to maintain per user cache
	if (req.http.Cookie ~"(wp-postpass|wordpress_logged_in|comment_author_)") {
		hash_data(req.http.Cookie);
	}
        return (lookup);
}


# This function is used when a request is sent by our backend
sub vcl_backend_response {
	set beresp.ttl = 0s;
	set beresp.grace = 1m;

	if ( beresp.status >= 400 ) {
		set beresp.ttl = 0s;
		set beresp.grace = 0s;
		return (deliver);
	}

	if (bereq.url ~ "wp-(login|admin)" || bereq.url ~ "preview=true") {
		set beresp.uncacheable = true;
		set beresp.ttl = 120s;
	}

	if (bereq.http.Cookie ~"(wp-postpass|wordpress_logged_in|comment_author_)") {
		set beresp.uncacheable = true;
	        set beresp.ttl = 120s;
	}

	#Set the default cache time of 1 hour
	set beresp.ttl = 1h;
	return (deliver);
}



# The routine when we deliver the HTTP request to the user
# Last chance to modify headers that are sent to the client
sub vcl_deliver {

	if (obj.hits > 0) { 
		set resp.http.X-Cache = "cached";
	} else {
		set resp.http.x-Cache = "uncached";
	}

	# Remove some headers: PHP version
	unset resp.http.X-Powered-By;

	# Remove some headers: Apache version & OS
	unset resp.http.Server;

	# Remove some heanders: Varnish
	unset resp.http.Via;
	unset resp.http.X-Varnish;

	return (deliver);
}

sub vcl_init {
	return (ok);
}
 
sub vcl_fini {
	return (ok);
}
