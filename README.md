Amici
=====

Block all addresses associated with a certain domain using their SPF and DNS records. 

Amici aims to foil the PRISM program that the American governement has been conducting in secret by simply allowing you to easily "boycot" the services it watches in an automated manner. Amici leverages the Sender Policy Framework records provided by the corporates themselves to determine which addresses need to be be blocked, the blocking itself is done via both `iptables` and `ip6tables`.

It can block any domain you choose to, but it works its magic best on the larger companies, who seem to like to build up large networks of [SPF records](https://en.wikipedia.org/wiki/Sender_Policy_Framework) spanning their entire on-line presence. 

[Wikipedia:Amici](https://en.wikipedia.org/wiki/Amici_prism)

##Usage
Append the `--prism` flag to the call of this script to block the identified PRISM contributers.
Append any number of domain names or IP addresses to the call of this script to block those and their asssociated domains.
Once ran, the networks will remain prohibited until you reboot or flush iptables, unless you use some fancy `iptables-save`r.

###Options

<dl>
  <dt>-v</dt>
  <dt>--debug</dt>
  <dd>debug mode; enables verbose logging.</dd>
  <dt>-n</dt>
  <dt>--dry-run</dt>
  <dd>does everything normally but call iptables.</dd>
  <dt>-p</dt>
  <dt>--prism</dt>
  <dd>block the known PRISM domains.</dd>
  <dt>--no-dns</dt>
  <dd>prevents recursing over DNS trees to , these can be useful if some DNS administrator installed circular records.</dd>
  <dt>--no-`RR`-dns</dt>
  <dd>prevents recursing over a certain recource record. Replace `RR` with any lowercase record mnemomic.</dd>
  <dt>--no-spf</dt>
  <dd>Does not use spf records to find more domains and addresses to block.</dd>
</dl>

Short options can be stacked: `-vn` will enable both debug mode and dry-run, just as `-v -n` would.


##Limitations and Bugs
sadly, the SPF and DNS records need not include all the addresses to be blocked, but it generally produces very satisfactory results!

The script isn't smart enough to detect circular DNS trees, so it might end up in an infinite loop. In that case you should just disable DNS discovery and issue separate requests for relevant subdomains.

Amici seems to hold a very strict philosophy of "friends of my enemy are my enemy too" and as a result, it might block much more than you originally intended to. This is a very prominent problem with smaller domains that live under shared hosting providers. Turn off DNS discovery and if needed even spf discovery.

Because Amici recurses over the entire SPF and DNS tree associated with a domain, issuing multiple DNS queries on each iteration, execution time can grow quite long for large domains, which is certainly the case when using the `--prism` flag. This is related to the insane recursion model used and might improve over time, but this sort of crawling will always remain rather slow.

Records spanning multiple strings are not handled according to spec yet, which means that it won't have complete coverage in those cases.

Amici depends on `grep`, `sed`, `dig`, `iptables` and `ip6tables`. Apart from `dig` and maybe `ip(6)tables`, it won't be easy to work without them.

###Disabling
Amici has no option for disabling yet, but you can clear out the iptables rules it set up by issuing the command `iptables -F && ip6tables -F` though this method is a bit destructive. I'll come up with a cleaner way, soon!

##Licence
embedded in the [script itself](https://github.com/upwhere/amici/blob/master/amici.sh)
