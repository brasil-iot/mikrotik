# RouterOS dont show SLACC address.
# Workaround: create a firewall roule to capture and generate an address-list with this SLACC address.
# After create this rule, force traffic (ping any external IPv6 address, in this case a DNS root server) - this traffic populate the address-list above.
# With SLACC Address, calculate the POOL PREFIX and generate a new ipv6 address using it.

#ipv6 config for SLACC (without DHCPv6)
#/ipv6 nd set [ find default=yes ] disabled=yes interface=ether1 ra-lifetime=none
#/ipv6 nd prefix default set preferred-lifetime=4h valid-lifetime=4h
#/ipv6 settings set accept-redirects=no accept-router-advertisements=yes forward=no

#remove any previus SLACC address from list
/ipv6 firewall address-list remove [ /ipv6 firewall address-list find list="ipv6slacc" ];
#/ipv6 firewall address-list print;

#remove any previus SLACC pool
/ipv6 pool remove [ /ipv6 pool find name="ipv6-virtua" ]
#/ipv6 pool print;

#remove any previus SLACC calculated address
/ipv6 address remove [ /ipv6 address find from-pool="ipv6-virtua" ];
#/ipv6 address print;

#if firewall raw rule to get SLACC not exists, create
:if ([/ipv6 firewall raw find address-list="ipv6slacc" ] = "") do={
  /ipv6 firewall raw add action=add-src-to-address-list address-list=ipv6slacc address-list-timeout=0s chain=output out-interface-list=WAN src-address=!fe80::/10
}

#make a generic (in this case, DNS root) ping to force ipv6 traffic and populate address-list ipv6slacc (firewall raw)
:execute script="{ ping address=2001:503:ba3e::2:30	count=1 ttl=1 }";
:local QT
:do {
  #wait .5s to populate address-list ipv6slacc
  :delay .5;
  #:put "...ping wait";
  :set ($QT+1);
  #after 120 interactions (60s) without data in address-list ipv6slacc, abort
  :if ($QT > 120) do={
    :error "SLACC Address not found";
  }
#if address-list ipv6slacc has data, end loop, else wait more .5s
} while=( [ /ipv6 firewall address-list find list="ipv6slacc" ] = "" );

#get ipv6 SLACC address from address-list ipv6slacc
:local CIDR ([ /ipv6 firewall address-list get [ /ipv6 firewall address-list find list="ipv6slacc" ] address ]);

#calculate PREFIX from SLACC address
:local PREFIX ([ :toip6 [ :pick $CIDR 0 [ :find $CIDR "/" ] ] ] & ffff:ffff:ffff:ffff::);

#if no PREFIX found, abort
:if ( ([:len $PREFIX] = 0) || ($PREFIX = "::") ) do={
   :error "No PREFIX found";
}

#create defaukt route
:local GATEWAY ([ /ipv6 neighbor get [ /ipv6 neighbor find interface="ether1" ] address ]);
/ipv6 route add gateway="$GATEWAY%ether1" distance=1 

#create new pool with SLACC calculated PREFIX
/ipv6 pool add name="ipv6-virtua" prefix="$PREFIX/64" prefix-length=64;

#create new address using SLACC pool
/ipv6 address add advertise=no eui-64=yes from-pool="ipv6-virtua" interface=ether1
