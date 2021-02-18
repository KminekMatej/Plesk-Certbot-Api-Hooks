#!/bin/sh

function Main
{
    #common constants

    KEY=''#Fill in your Plesk API secret key (https://docs.plesk.com/en-US/obsidian/api-rpc/about-xml-api/reference/managing-secret-keys/creating-secret-keys.37131/)
    PLESKAPIURL=https://p.example.com:8443/enterprise/control/agent.php #Change according to your server
    SITEID=1 #Change according to your server
    DOMAIN=example.com #Change according to your server

    RUN_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
    DATE=`date '+%Y-%m-%dT%H:%M:%S'`
    BLUEFONT='\033[1;34m'
    GREENFONT='\033[1;32m'
    BLACKFONT='\033[0m'
    REDFONT='\033[0;31m'
    YELLOWFONT='\033[1;33m'

    __checkParams

    logg "Managing DNS record over PLESK DNS API started."
    logg "Input domain: $CERTBOT_DOMAIN"
    logg "Input validation string: $CERTBOT_VALIDATION"


    if [[ "$CERTBOT_DOMAIN" =~ ^((.*)\.)?(.*)\.(.*)$ ]]; then
        if [ -z ${BASH_REMATCH[2]} ]; then
                RECHOST=_acme-challenge
        else
                RECHOST=_acme-challenge.${BASH_REMATCH[2]}
        fi
        DOMAIN=${BASH_REMATCH[3]}.${BASH_REMATCH[4]}
        logg "Will work with $RECHOST [TXT:$CERTBOT_VALIDATION]"
    else
        errlogg "Invalid format of CERTBOT_DOMAIN input!";
        exit 1
    fi

    DATA="<packet><dns><get_rec><filter><site-id>$SITEID</site-id></filter></get_rec></dns></packet>"
    EXISTINGREC=$(curl -L --max-time 45 -s -X POST -H 'Content-Type: text/xml' -H "KEY: $KEY" -d $DATA $PLESKAPIURL)
    EXISTINGVAL=$(echo "$EXISTINGREC" | xmllint --xpath "string(/packet/dns/get_rec/result[data/type='TXT' and data/host='$RECHOST.$DOMAIN.']/data/value)" -)

    if [ -z "$EXISTINGVAL" ]; then 
        createDNS
    else 
        local EXISTINGID=$(echo "$EXISTINGREC" | xmllint --xpath "string(/packet/dns/get_rec/result[data/type='TXT' and data/host='$RECHOST.$DOMAIN.']/id)" -)
        logg "DNS record found: $EXISTINGVAL (ID $EXISTINGID)"

        deleteDNS $EXISTINGID
        createDNS
    fi

    logg DNS record processed, waiting 10 seconds to propagate on PLESK

    sleep 10
}

function deleteDNS
{
    local EXISTINGID=$1
    logg "Deleting DNS record: $EXISTINGID"
    
    DATA="<packet><dns><del_rec><filter><id>$EXISTINGID</id></filter></del_rec></dns></packet>"
    RESP=$(curl -L --max-time 45 -s -X POST -H 'Content-Type: text/xml' -H "KEY: $KEY" -d $DATA $PLESKAPIURL)
    processResponse del_rec
}

function createDNS
{
    logg "Creating DNS record on $DOMAIN [TXT:$RECHOST = '$CERTBOT_VALIDATION']"
    DATA="<packet><dns><add_rec><site-id>$SITEID</site-id><type>TXT</type><host>$RECHOST</host><value>$CERTBOT_VALIDATION</value></add_rec></dns></packet>"
    RESP=$(curl -L --max-time 45 -s -X POST -H 'Content-Type: text/xml' -H "KEY: $KEY" -d $DATA $PLESKAPIURL)

    processResponse add_rec
}

function processResponse
{
    local RESOURCE=$1
    STATUS=$(echo "$RESP" | xmllint --xpath "string(/packet/dns/$RESOURCE/result/status)" -)
    if [ "$STATUS" = "ok" ]; then
        logg "Request succesful"
    else
        ERRCODE=$(echo "$RESP" | xmllint --xpath "string(/packet/dns/$RESOURCE/result/errcode)" -)
        ERRMSG=$(echo "$RESP" | xmllint --xpath "string(/packet/dns/$RESOURCE/result/errtext)" -)
        errlogg "Error response $ERRCODE: $ERRMSG"
        exit 1
    fi
}

function __checkParams
{
	if [ -z "$CERTBOT_DOMAIN" ]; then 
		errlogg "Missing certbot domain"; 
		exit 1
	fi
	if [ -z "$CERTBOT_VALIDATION" ]; then 
		errlogg "Missing certbot validation string"; 
		exit 1
	fi
}


function logg()
{
	CURTIME=`date +%H:%M:%S`
	#printf "${BLUEFONT}$CURTIME: $1${BLACKFONT}\n" #commented out as certbot treats any output as error output. Only errLogg remains as output
}

function warnlogg()
{
	CURTIME=`date +%H:%M:%S`
	#printf "${YELLOWFONT}$CURTIME: $1${BLACKFONT}\n"
}

function errlogg()
{
	CURTIME=`date +%H:%M:%S`
	#printf "${REDFONT}$CURTIME: $1${BLACKFONT}\n"
}

function resultLogg()
{
        OUT=$1
	if [ $OUT -ne 0 ]; then
        	errlogg "$2"
        else
		logg "$3"
	fi
}

function Usage
{
  cat <<EOF
  Plesk DNS update script, utilized to work with certbot
  
  Usage: 
  certbot certonly --force-renewal --manual --preferred-challenges=dns --manual-auth-hook /path/to/plesk-dns-api.sh --email your@email.com --agree-tos -d *.example.com
  
EOF
}

Main "$@"
exit 0
