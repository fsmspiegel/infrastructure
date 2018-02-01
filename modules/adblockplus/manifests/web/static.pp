# == Class: adblockplus::web::static
#
# Manage a simple Nginx-based webserver for static content
# that uses a customizable deployment script to e.g. fetch the content
# from a repository server (ref. http://hub.eyeo.com/issues/4523)
#
#
# === Parameters:
#
# [*domain*]
#   The domain name for the website.
#
# [*ssl_certificate*]
#   The name of the SSL certificate file within modules/private/files, if any.
#   Requires a private_key as well.
#
# [*ssl_private_key*]
#   The name of the private key file within modules/private/files, if any.
#   Requires a certificate as well.
#
# [*is_default*]
#   Passed on to nginx (whether or not the site config should be default).
#
# [*ensure*]
#   Whether to set up the website or not.
#
# === Examples:
#
#   class {'adblockplus::web::static':
#     domain => 'help.eyeo.com',
#   }
#
class adblockplus::web::static (
  $domain = undef,
  $ssl_certificate = undef,
  $ssl_private_key = undef,
  $is_default = true,
  $ensure = 'present',
  $geoip_enable = false,
  $geoip_country = undef,
  $deploy_user = 'web-deploy',
  $deploy_user_authorized_keys = undef,
) {

  include adblockplus::web

  class {'nginx':
    geoip_country => $geoip_country,
  }

 class {'geoip':
    cron => {hour => 0, minute => 8, monthday => 15},
    ensure => geoip_enable ? {false => 'absent', default => 'present'},
  }

  file {"/var/www/$domain":
    ensure => ensure_directory_state($ensure),
    mode => '0775',
    owner => www-data,
    group => www-data,
  }

  nginx::hostconfig {$title:
    content => template('adblockplus/web/static.conf.erb'),
    certificate => $ssl_certificate,
    domain => $domain,
    is_default => $is_default,
    private_key => $ssl_private_key,
    log => "access_log_$domain",
  }

  #deploy script
  $deploy_script_path = "/home/$deploy_user/deploy_script.sh"

  #deploy user with authorized_keys and deploy script as forced command

  adblockplus::user {$deploy_user:
    authorized_keys => $deploy_user_authorized_keys ? {
      undef => [],
      default => prefix($deploy_user_authorized_keys, "command=\"$deploy_script_path\" "),
    },
    ensure => $ensure,
    password_hash => '*',
    shell => '/bin/bash',
    groups => ['www-data']
  }

  file {$deploy_script_path:
    content => template('adblockplus/web/static_deploy_script.sh.erb'),
    ensure => $ensure,
    mode => '0755',
    owner => $deploy_user,
  }

}
