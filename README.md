# Plesk-Certbot-Api-Hooks
Scripts creates DNS record on Plesk server, using Plesk XML API

It's meant to be used in addition with certbot package for Let's encrypt generated certificates, passed to certbot through parameter `--manual-auth-hook`

This script:
- Parses parameters from certbot (`$CERTBOT_DOMAIN` and `$CERTBOT_VALIDATION`) into DNS hostname, like `\_acme-challenge.foo` (for certificate request to `\*.foo.boost.space`) or `\_acme-challenge` (for certificate request to `\*.example.com`)
- Sends request to PLESK server, detecting if this host is already in domains
- Deletes that DNS record if it already exists on Plesk
- Create new DNS TXT record for parsed host name with value taken from `$CERTBOT_VALIDATION`
- Sleeps for 10 secs to give plesk time for propagation

Script is useful if you have DNS nameserver handled by Plesk webservice and domains are on different server. Or if you, for any reason, don't want to use native Plesk Let's encrypt renewal process.

Script example:

`certbot-auto certonly --force-renewal --manual --preferred-challenges=dns --manual-auth-hook /path/to/plesk-api-prehook.sh --email me@example.com --agree-tos -d \*.example.com`

Creates DNS record:

`_acme-challenge.example.com.   IN   TXT   "DKvGAeI8mqJojvbSxN0KCWFFyBgwPPNqrR8wXxtqS9A"`
