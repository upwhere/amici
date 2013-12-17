#!/bin/sh

#######################################################
#
#	amici.sh
#	
#	by: up here <iam@upwhere.me>
#	since: 2013-06-16
#	
#	what: Block all addresses associated with a certain
#		domain using their SPF records. 
#	
#	hey: please do distribute this script in any way you
#		want, including modified, but I will start
#		throwing frowny faces if you claim it as your
#		own.
#	
#	but: you could also just submit pull requests on
#		github or something. then we can make the
#		digital world a better place, together.
#
#	github: https://github.com/upwhere/amici
#
#	documentation: not much, but it is on github and 
#		as inline comments.
#
#######################################################

#produce a sane environment.
unalias -a
readonly PATH="/sbin:/bin:/usr/sbin:/usr/bin"
cd /
hash -r
ulimit -H -c 0
readonly IFS="
 "

set -e

# wikipedia-listed domains contributing to PRISM 2013-06-15
readonly prism="google.com
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

readonly database="dig"
readonly query="+short -t"
readonly spfquery="$query TXT"
readonly aquery="$query A"

#lets them know this host is prohibited
readonly ip4injob="--jump REJECT --reject-with icmp-host-prohibited"
#lets you know their network is prohibited.
readonly ip4outjob="--jump REJECT --reject-with icmp-net-prohibited"
readonly ip6job="--jump REJECT --reject-with icmp6-adm-prohibited"

echoerr() { echo "$@" >&2; }
echodebug() { $debug && echo "$@" ; true; }

# check if all the commands we need are available
command -v grep >/dev/null || { echoerr "Dependency not met: program: grep"; exit 1; }
command -v sed >/dev/null || { echoerr "Dependency not met: program: sed"; exit 1; }
command -v $database >/dev/null || { echoerr "Dependency not met: program: $database"; exit 1; }
command -v iptables >/dev/null || { echoerr "Dependency not met: program: iptables"; exit 1; }
command -v ip6tables >/dev/null || { alias ip6tables=':'; }

## block IPv4 addresses 
function block4
{
	for address in "$@"; do
		#make sure it does not exist yet
		iptables --check INPUT $ip4injob --source $address 2>/dev/null ||
		{
			#block if no dry-run
			$dryrun||iptables --append INPUT $ip4injob --source $address
		}
		#make sure it does not exist yet
		iptables --check OUTPUT $ip4outjob --destination $address 2>/dev/null ||
		{
			#block if no dry-run
			$dryrun||iptables --append OUTPUT $ip4outjob --destination $address
		}
		echodebug "		ip4:$address"
	done
}

## block IPv6 addresses
function block6
{
	for address in "$@"; do
		# make sure this rule does not exist yet
		ip6tables --check INPUT $ip6job --source $@ 2>/dev/null ||
		{
			#if not a dry-run, add it
			$dryrun||ip6tables $ip6job --append INPUT --source $@
		}
		# make sure this rule does not exist yet
	    ip6tables --check OUTPUT $ip6job --destination $@ 2>/dev/null ||
		{
			# and if it's not a dry-run, add it.
			$dryrun||ip6tables $ip6job --append OUTPUT --destination $@
		}
		echodebug "		ip6:$@"
	done
}

## block all the DNS addresses we can identify
function blockdomain
{
	for bdomain in "$@";do
		echodebug "	$bdomain"
		block4 $($database $aquery $bdomain)
		block6 $($database $query AAAA $bdomain)
	done
}

## search for and block everything in the SPF records of the passed domains
function blockspf
{
	## make sure domain is retained during recursion
	local domain
	for domain in "$@"; do
		echodebug $domain

		local txtrecords="$($database $spfquery $domain)
"		#while there are TXT records left
		while [ -n "$txtrecords" ];do
			#grab one record
			local record=${txtrecords%%
*}
			#remove the record
			txtrecords=${txtrecords##*
}
			#strip the quotes
			record=${record//\"/}
			case $record in
				v=spf*)
					# each space-separated word...
					for entry in $record; do
						# clean up SPF modifiers
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
								#discard exp entries, often pattern expanded and thus unparsable.
							;;
							v=spf*)
								version=${entry#v=}
								if [ $version != "spf1" ];then
									echoerr "careful: SPF version unknown: $version"
									# we don't care about integrity, we just want to find all associated domains, continue anyway
								fi
							;;
							*)
								echoerr "$domain has unknown entry type: $entry"
								$debug&&echoerr "	record:$spf"
							;;
						esac
					done
				;;
				## if there is no TXT record in this domain, just continue
				"")
				;;
				*)
					echodebug "TXT unidentified: $record"
				;;
			esac
		done
		## now that the SPF has been parsed and blocked, block everything else on this domain.
		blockdomain $domain
	done
}

## parse command-line arguments
for argument in "$@";do
	case $argument in
		--*)
			case $argument in
				--debug)
					debug="true"
				;;
				--dryrun)
					dryrun="true"
				;;
				--prism)
					blocks="$blocks
$prism"
				;;
				--help)
					blocks=""
					break
				;;
				*)
					echoerr "Unknown flag: $argument"
				;;
			esac
		;;
		-*)
			# foreach character in the short-flag string
			for (( i=0; i<${#argument}; i++ )); do
				case ${argument:$i:1} in
					v)
						debug="true"
					;;
					n)
						dryrun="true"
					;;
					p)
						blocks="$blocks
$prism"
					;;
					h|\?)
						blocks=""
						i=-1
						break
					;;
					-)
						#skip the -
					;;
					*)
						if (( ${#argument} > 2 )); then
							echoerr "Unknown flag: -${argument:$i:1} ( from $argument )"
						else
							echoerr "Unknown flag: -${argument:$i:1}"
						fi

						blocks=""
						i=-1
						break
					;;
				esac
			done
			(( i < 0 )) && break
		;;
		*)
			blocks="$blocks
$argument"
		;;
	esac
done

# nothing to block?
if [ -z "$blocks" ];then
	echoerr "Usage: $0 [--debug,--prism,--dryrun] [domain [domain [...]]]"
	exit 1
fi

#start the recursion
blockspf $blocks
