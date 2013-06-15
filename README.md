amici
=====

Attempts to disable all traffic to and from any companies associated with PRISM or domains of your choosing.

amici aims to foil the PRISM program that the American governement has been conducting in secret by simply allowing you to easily "boycot" the services it watches in an automated manner. Amici leverages the spf records provided by the corporates themselves to determine which addresses need to be be blocked, the blocking itself is done via `iptables` and `ip6tables`.


[Wikipedia:Amici](https://en.wikipedia.org/wiki/Amici_prism)

##Usage
append the -prism flag to the call of this script to block the identified PRISM contributers
append any number of domain names or IP addresses to the call of this script to block those and their asssociated domains.
Once ran, the networks will remain prohibited until you reboot, unless you use some fancy `iptables-save`r.

###Disabling
amici has no option for disabling yet, but you can clear out the iptables rules it set up by issuing the command `iptables -F && ip6tables -F` though this method is a bit destructive. I'll come up with a cleaner way, soon!

##Limitations and Bugs
sadly, the SPF records need not include all the addresses to be blocked, but it generally produces very satisfactory results!
