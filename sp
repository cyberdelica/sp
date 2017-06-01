#!/usr/bin/env sh
# sp - fetch precious metal spot prices from bullionbypost

# globals
self="$(basename "${0}")"
version="0.1a"
author="cyberdelica"
website="http://www.cyberdelica.org/"

url="https://www.bullionbypost.co.uk/"
path="ajax/update-prices/ssl/"

agent="sp"

# boilerplate functionality
die() {
	[ "${#}" -ne 0 ] && printf "%s\n" "${*}" >&2
	exit 1
}

error() {
	die "error:" "${*}"
}

usage() {
	printf "usage: %s [-hj] [-a agent] [-c currency] [-m metal] [-u unit]\n" "${self}" >&"${1:-2}"
}

help() {
	printf "%s v%s -- (c) Copyright 2017 %s (%s)\n\n" "${self}" "${version}" "${author}" "${website}"
	usage 1
	printf "\nOptions:\n"
	printf "    %s\t%s\n" "-a agent" "alternative user agent. default is: \"${agent}/${version}\"."
	printf "    %s\t%s\n" "-c currency" "currency to display spot price in. options are: GBP, USD, and EUR."
	printf "    %s\t\t%s\n" "-h" "displays the help."
	printf "    %s\t\t%s\n" "-j" "dump the raw json response to stdout."
	printf "    %s\t%s\n" "-m metal" "metal to display the price for. options are: gold, au, silver, ag, platinum, pt, palladium, pd."
	printf "    %s\t%s\n" "-u unit" "unit of display for the metal. options are: troy, toz, t, gram, g."
	exit 0
}

init() {
	# check for dependencies
	for d in curl sed jq
	do
		command -v "${d}" >/dev/null 2>&1 || error "${d} not installed"
	done
}

# sanitise user input
sanitise() {
	# convert input to lowercase
	[ -n "${currency}" ] && currency="$(printf "%s" "${currency}" | tr '[:upper:]' '[:lower:]')"
	[ -n "${metal}" ] && metal="$(printf "%s" "${metal}" | tr '[:upper:]' '[:lower:]')"
	[ -n "${unit}" ] && unit="$(printf "%s" "${unit}" | tr '[:upper:]' '[:lower:]')"

	# check for correct currency input - or use default (GBP)
	[ "${currency:=gbp}" = "gbp" -o "${currency}" = "usd" -o "${currency}" = "eur" ] || error "${currency} is not a valid option for currency"

	# check for correct metal input
	if [ "${metal}" = "gold" -o "${metal}" = "au" ]
	then
		metal="gold"
	elif [ "${metal}" = "silver" -o "${metal}" = "ag" ]
	then
		metal="silver"
	elif [ "${metal}" = "platinum" -o "${metal}" = "pt" ]
	then
		metal="platinum"
	elif [ "${metal}" = "palladium" -o "${metal}" = "pd" ]
	then
		metal="palladium"
	else
		[ -n "${metal}" ] && error "${metal} is not a valid option for metal"
	fi

	# check for correct unit input - or use default (troy ounce)
	if [ "${unit:=toz}" = "toz" -o "${unit}" = "t" -o "${unit}" = "troy" ]
	then
		unit="toz"
	elif [ "${unit}" = "gram" -o "${unit}" = "g" ]
	then
		unit="gram"
	else
		error "${unit} is not a valid option for unit"
	fi
}

# scrape ajax token - used to make multiple requests
token() {
	token="$(curl --capath /etc/ssl/certs/ -sSA "${agent}" "${url}" 2>/dev/null | sed -n '/ajaxToken/{s![^"]*"\([^"]*\)".*!\1!p}')"
	[ -z "${token}" ] && error "couldn't scrape ajax token from ${url}"
}

# fetch json data
fetch() {
	data="$(curl --capath /etc/ssl/certs/ -sSA "${agent}" "${url}${path}${token}" 2>/dev/null | sed 's!\&[^;]*;!!g; s!<[^>]*>[^0-9]*!!g')"
}

# start of the main routine
init
while getopts ":a:c:hjm:u:" o
do
	case "${o}" in
		a) agent="${OPTARG}";;
		c) currency="${OPTARG}";;
		h) help=1;;
		j) json=1;;
		m) metal="${OPTARG}";;
		u) unit="${OPTARG}";;
		\?) usage; error "-${OPTARG} is not a valid option";;
		:) usage; error "-${OPTARG} requires an argument";;
	esac
done
shift "$(expr "${OPTIND}" - 1)"

[ "${#}" -ne 0 ] && error "too many arguments"
[ "${help:-0}" -ne 0 ] && help

sanitise
token

if [ "${json:-0}" -ne 0 ]
then
	fetch
	[ -z "${data}" ] && error "couldn't scrape data"

	printf "%s\n" "${data}"
else
	fetch
	[ -z "${data}" ] && error "couldn't scrape data"

	# separate timestamp for convenient formatting
	ts="$(printf "%s" "${data}" | jq -r '.[].last_updated')"

	if [ -n "${metal}" ]
	then
		printf "%s" "${data}" | jq -r ".[].${metal}.${unit}.${currency}"
	else
		for metal in gold silver platinum palladium
		do
			price="$(printf "%s" "${data}" | jq -r ".[].${metal}.${unit}.${currency}")"
			printf "%s %s %s %s %s %s\n" "${ts#*[ ]}" "${ts%[ ]*}" "${metal}" "${price}" "${currency}" "${unit}"
		done
	fi
fi

exit 0
