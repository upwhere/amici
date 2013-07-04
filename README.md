Amici
=====

Block all addresses associated with a certain domain using their SPF records. 

Amici aims to foil the PRISM program that the American governement has been conducting in secret by simply allowing you to easily "boycot" the services it watches in an automated manner. Amici leverages the Sender Policy Framework records provided by the corporates themselves to determine which addresses need to be be blocked, the blocking itself is done via both `iptables` and `ip6tables`.

It can block any domain you choose to, but it works its magic best on the larger companies, who seem to like to build up large networks of [SPF records](https://en.wikipedia.org/wiki/Sender_Policy_Framework) spanning their entire on-line presence. 

[Wikipedia:Amici](https://en.wikipedia.org/wiki/Amici_prism)

##Usage
Append the `--prism` flag to the call of this script to block the identified PRISM contributers.
Append any number of domain names or IP addresses to the call of this script to block those and their asssociated domains.
Once ran, the networks will remain prohibited until you reboot or flush iptables, unless you use some fancy `iptables-save`r.

###Options

<dl>
  <dt>-p</dt>
  <dt>--prism</dt>
  <dd>block the known PRISM domains.</dd>
  <dt>-i</dt>
  <dt>--unblock</dt>
  <dd>unblocks domains instead of blocking, experimental.</dd>
  <dt>-v</dt>
  <dt>--debug</dt>
  <dd>debug mode; enables verbose logging.</dd>
  <dt>-n</dt>
  <dt>--dry-run</dt>
  <dd>does everything normally but call iptables.</dd>
</dl>

Short options can be stacked: `-vn` will enable both debug mode and dry-run, just as `-v -n` would.


##Limitations and Bugs
sadly, the SPF records need not include all the addresses to be blocked, but it generally produces very satisfactory results!

Amici isn't very proficient at DNS yet, but this can be fixed with some work. This effectively means amici needs to be manually guided to the SPF records before it can work.

Records spanning multiple strings are not handled according to spec yet, which means that it won't have complete coverage in those cases.

Amici depends on `grep`, `sed`, `dig`, `iptables` and `ip6tables`. Apart from `dig` and maybe `ip(6)tables`, it won't be easy to work without them.

###Disabling
The unblock feature is still experimental, might it prove to be problematic you are always able to flush all blocks form iptables with the `iptables -F && ip6tables -F` command, though this method is a bit destructive. A cleaner method is under development.

##Licence
embedded in the [script itself](https://github.com/upwhere/amici/blob/master/amici.sh)
