#!/bin/sh
#produce a sane environment.
unalias -a
PATH="/sbin:/bin:/usr/sbin:/usr/bin"
cd /
hash -r
ulimit -H -c 0
IFS="
 "

set -e

# wikipedia-listed domains contributing to PRISM 2013-06-15
prism="google.com
microsoft.com
apple.com
skype.com
Yahoo.com
facebook.com
paltalk.com
Youtube.com
corp.aol.com
aol.com"

debug="false"
dryrun="false"

database="dig"
query="+short -t"
spfquery="$query TXT"

#lets them know this host is prohibited
ip4injob="--append INPUT --jump REJECT --reject-with icmp-host-prohibited"
#lets you know their network is prohibited.
ip4outjob="--append OUTPUT --jump REJECT --reject-with icmp-host-prohibited"
ip6job="--jump REJECT --reject-with icmp6-adm-prohibited"

echoerr() { echo "$@" >&2; }

command -v grep >/dev/null || { echoerr "Dependency not met: program: grep"; exit 1; }
command -v sed >/dev/null || { echoerr "Dependency not met: program: sed"; exit 1; }
command -v $database >/dev/null || { echoerr "Dependency not met: program: $database"; exit 1; }
command -v iptables >/dev/null || { echoerr "Dependency not met: program: iptables"; exit 1; }
command -v ip6tables >/dev/null || { echoerr "Dependency not met: program: ip6tables"; exit 1; }

function block4
{
	$dryrun||iptables $ip4injob --source $@
	$dryrun||iptables $ip4outjob --destination $@
	$debug&&echo "		ip4:$@"
}

function block6
{
	$dryrun||ip6tables $ip6job --append INPUT --source $@
	$dryrun||ip6tables $ip6job --append OUTPUT --destination $@
	$debug&&echo "		ip6:$@"
}

function blockdomain
{
	$debug&&echo "	$@"
	block4 $@
	block6 $@
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
		spf=$($database $spfquery $domain|grep --only-matching --perl-regexp "(\").*\1"|sed '{s/\"//g}'|grep v=spf)
		# clean up modifiers
		for entry in $spf; do
			entry=${entry#[-~\?+]}
			case $entry in
				##new domains to search##
				include:*|ptr:*|a:*)
					blockspf ${entry#*:}
				;;
				exists:*)
					#unparsable
				;;
				redirect=*)
					blockspf ${entry#redirect=}
				;;
				##ranges to block##
				ip4:*)
					block4 ${entry#ip4:}
				;;
				ip6:*)
					block6 ${entry#ip6:}
				;;
				##spf record specifics##
				a|mx|ptr|all)
					#covered by blockdomain $domain, below
				;;
				exp=*)
					#discard explanations, often pattern expanded and thus unparsable.
				;;
				v=spf*)
					version=${entry#v=}
					if [ $version != "spf1" ];then
						echoerr "careful: spf version unknown: $version"
						# we don't care about integrity, we just want to find all associated domains, continue anyway
					fi
				;;
				*)
					echoerr "$domain has unknown entry type: $entry"
					$debug&&echoerr "	record:$spf"
				;;
			esac
		done
		blockdomain $domain
	done
}

for argument in "$@";do
	case $argument in
		-v|--debug)
			debug="true"
		;;
		-n|--dryrun)
			dryrun="true"
		;;
		-p|--prism)
			blocks=$prism
		;;
		-*)
			echoerr "unknown parameter: $argument"
			blocks=""
			break
		;;
		*)
			blocks="$blocks
$argument"
		;;
	esac
done

if [ -z "$blocks" ];then
	echoerr "Usage: $0 [--debug,--prism,--dryrun] [domain [domain [...]]]"
	exit 1
fi

blockspf $blocks