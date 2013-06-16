#!/bin/sh
#produce a sane environment.
unalias -a
PATH="/sbin:/bin:/usr/sbin:/usr/bin"
cd /
hash -r
ulimit -H -c0
IFS="
 "

set -e

# wikipedia-listed domains contributing to PRISM 2013-06-15
prism="google.com
microsoft.com
apple.com
www.skype.com
Yahoo.com
facebook.com
www.paltalk.com
Youtube.com
corp.aol.com
www.aol.com
blog.aol.com"

debug="false"

database="dig"
query="+short -t"
spfquery="$query TXT"


echoerr() { echo "$@" >&2; }

command -v grep >/dev/null || { echoerr "Dependency not met: program: grep"; exit 1; }
command -v sed >/dev/null || { echoerr "Dependency not met: program: sed"; exit 1; }
command -v $database >/dev/null || { echoerr "Dependency not met: program: $database"; exit 1; }

function blocka
{
	$debug&&echo "	$@"
	true "I wandered lonely as a cloud."
}

function blockspf
{
	for domain in "$@"; do
		$debug&&echo $domain
		### FIXME: ###
		#
		# a single text DNS
		# record (either TXT or SPF RR types) can be composed of more than one
		# string.  If a published record contains multiple strings, then the
		# record MUST be treated as if those strings are concatenated together
		# without adding spaces.
		#
		spf=$($database $spfquery $domain|grep -oP "(\").*\1"|sed '{s/\"//g}'|grep v=spf)
		for entry in $spf; do
			case $entry in
				##cleanup##
				[-~\?+]*)
					entry=${entry#[-~\?+]}
				;&
				##new domains to search##
				include:*)
					blockspf ${entry#*include:}
				;;
				ptr:*)
					blockspf ${entry#*ptr:}
				;;
				a:*)
					blockspf ${entry#*a:}
				;;
				exists:*)
					#unparsable
				;;
				redirect=*)
					blockspf ${entry#redirect=}
				;;
				##ranges to block##
				ip4:*)
					blocka $entry
				;;
				ip6:*)
					blocka $entry
				;;
				##spf record specifics##
				a|mx)
					#covered by blocka $domain, below
				;;
				v=spf*)
					version=$(echo $entry|sed "{s/v=//}")
					if [ $version != "spf1" ];then
						echoerr "careful: spf version unknown: $version"
						# we don't care about integrity, we just want to find all associated domains, continue anyway
					fi
				;;
				all)
				;;
				*)
					echoerr "$domain has unknown entry type: $entry"
					$debug&&echoerr "	record:$spf"
				;;
			esac
		done
		blocka $domain
	done
}

for argument in "$@";do
	case $argument in
		-debug)
			debug="true"
		;;
		-prism)
			blocks=$prism
		;;
		*)
			blocks="$blockspfs
$argument"
		;;
	esac
done

if [ -z "$blocks" ];then
	echoerr "Usage: $0 [-debug,-prism] [domain [domain [...]]]"
	exit 1
fi

blockspf $blocks