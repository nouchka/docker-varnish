vcl 4.0;

import std;
import directors;

backend symfony {
  .host = "hello";
}

acl purge_ip {
    "localhost";
    "127.0.0.1";
    // ""
}

sub vcl_recv {
    set req.backend_hint = symfony;

    if (req.restarts == 0) {
      if (req.http.x-forwarded-for) {
          set req.http.X-Forwarded-For =
          req.http.X-Forwarded-For + ", " + client.ip;
      } else {
          set req.http.X-Forwarded-For = client.ip;
      }
    }
    if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "PURGE" &&
      req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }
    if (req.method == "PURGE") {
         if (!client.ip ~ purge_ip) {
             return(synth(403, "Not allowed"));
         }
         return (purge);
    }
    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pipe);
    }
    if (req.url ~ "\.(jpe?g|png|gif|pdf|gz|tgz|bz2|tbz|tar|zip|tiff|tif)$" || req.url ~ "/(image|(image_(?:[^/]|(?!view.*).+)))$") {
        return (hash);
    }
    if (req.url ~ "\.(svg|swf|ico|mp3|mp4|m4a|ogg|mov|avi|wmv|flv)$") {
        return (hash);
    }
    if (req.url ~ "\.(xls|vsd|doc|ppt|pps|vsd|doc|ppt|pps|xls|pdf|sxw|rar|odc|odb|odf|odg|odi|odp|ods|odt|sxc|sxd|sxi|sxw|dmg|torrent|deb|msi|iso|rpm)$") {
        return (hash);
    }
    if (req.url ~ "\.(css|js)$") {
        return (hash);
    }
    if (req.http.Authorization || req.http.Cookie ~ "(^|; )(__ac=|_ZopeId=)") {
        /* Not cacheable by default */
        return (pipe);
    }

  if (req.http.Cache-Control ~ "(?i)no-cache") {
  #if (req.http.Cache-Control ~ "(?i)no-cache" && client.ip ~ editors) { # create the acl editors if you want to restrict the Ctrl-F5
  # http://varnish.projects.linpro.no/wiki/VCLExampleEnableForceRefresh
  # Ignore requests via proxy caches and badly behaved crawlers
  # like msnbot that send no-cache with every request.
    if (! (req.http.Via || req.http.User-Agent ~ "(?i)bot" || req.http.X-Purge)) {
      ##set req.hash_always_miss = true; # Doesn't seems to refresh the object in the cache
      return(purge); # Couple this with restart in vcl_purge and X-Purge header to avoid loops
    }
  }

    return (hash);
}


sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
    return (lookup);
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.
    if (beresp.ttl <= 0s ||
        beresp.http.Set-Cookie ||
        beresp.http.Vary == "*") {
        /*
         * Mark as "Hit-For-Pass" for the next 60 minutes - 24 hours
         */
        if (bereq.url ~ "\.(jpe?g|png|gif|pdf|gz|tgz|bz2|tbz|tar|zip|tiff|tif)$" || bereq.url ~ "/(image|(image_(?:[^/]|(?!view.*).+)))$") {
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 6h;
        } elseif (bereq.url ~ "\.(svg|swf|ico|mp3|mp4|m4a|ogg|mov|avi|wmv|flv)$") {
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 6h;
        } elseif (bereq.url ~ "\.(xls|vsd|doc|ppt|pps|vsd|doc|ppt|pps|xls|pdf|sxw|rar|odc|odb|odf|odg|odi|odp|ods|odt|sxc|sxd|sxi|sxw|dmg|torrent|deb|msi|iso|rpm)$") {
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 6h;
        } elseif (bereq.url ~ "\.(css|js)$") {
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 24h;
        } else {
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 1h;
        }
    }
    return (deliver);
}

sub vcl_deliver {
    if (obj.hits > 0) {
            set resp.http.X-Cache = "HIT";
    } else {
            set resp.http.X-Cache = "MISS";
    }
    set resp.http.X-Cache-Hits = obj.hits;
}

sub vcl_synth {
    set resp.http.Content-Type = "text/html; charset=utf-8";
    set resp.http.Retry-After = "5";
    synthetic ("Error");
    return (deliver);
}

sub vcl_purge {
    set req.method = "GET";
    set req.http.X-Purger = "Purged";
    return (restart);
}
