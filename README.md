# Plesk-Certbot-Api-Hooks
Scripts handling DNS update records on Plesk server, using Plesk XML API

This script:
- Parses parameters from certbot ($CERTBOT_DOMAIN and $CERTBOT_VALIDATION) into DNS hostname, like '\_acme-challenge.foo' (for certificate request to \*.foo.boost.space) or '\_acme-challenge' (for certificate request to \*.example.com)
- Sends request to PLESK server, detecting if this host is already in domains
- Deletes that DNS record if it already exists on Plesk
- Create new DNS TXT record for parsed host name with value taken from $CERTBOT_VALIDATION
- Sleeps for 10 secs to give plesk time for propagation

Script is useful if you have DNS nameserver handled by Plesk webservice and domains are on different server. Or if you, for any reason, doesnt want to use native Plesk Lets encrypt renewal process

Script example:
certbot-auto certonly --force-renewal --manual --preferred-challenges=dns --manual-auth-hook /path/to/plesk-dns-api.sh --email me@example.com --agree-tos -d \*.example.com
