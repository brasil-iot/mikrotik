/interface bridge add admin-mac=aa:bb:cc:dd:ee:ff auto-mac=no comment=defconf name=bridge
/interface pppoe-client add add-default-route=yes disabled=no interface=ether1 keepalive-timeout=disabled name=pppoe-vivo password=cliente user=cliente@cliente
/interface list add name=WAN-VIRTUA
/interface list add name=LAN
/interface list add name=WAN-VIVO
/ip pool add name=dhcp-rede-local ranges=192.168.88.10-192.168.88.254
/ip dhcp-server add address-pool=dhcp-rede-local disabled=no interface=bridge name=dhcp-server-local
/port set 0 name=serial0
/interface bridge port add bridge=bridge comment=defconf ingress-filtering=yes interface=ether3
/interface bridge port add bridge=bridge comment=defconf ingress-filtering=yes interface=ether4
/interface bridge port add bridge=bridge comment=defconf ingress-filtering=yes interface=ether5
/ip neighbor discovery-settings set discover-interface-list=LAN
/ip settings set tcp-syncookies=yes
/interface list member add interface=bridge list=LAN
/interface list member add interface=ether2 list=WAN-VIRTUA
/interface list member add interface=pppoe-vivo list=WAN-VIVO
/ip address add address=192.168.88.1/24 interface=bridge network=192.168.88.0
/ip dhcp-client add disabled=no interface=ether2 use-peer-dns=no use-peer-ntp=no
/ip dhcp-server network add address=192.168.88.0/24 comment=defconf dns-server=192.168.88.1 gateway=192.168.88.1
/ip dns set allow-remote-requests=yes servers=8.8.8.8,208.67.220.220
/ip dns static add address=192.168.88.1 name=router.lan
/ip firewall filter add action=accept chain=input comment="== fw aceita conexoes LAN ==" in-interface-list=LAN
/ip firewall filter add action=accept chain=input comment="== fw aceita PING ==" protocol=icmp
/ip firewall filter add action=accept chain=input comment="== fw aceita conexoes previas ==" connection-state=established,related,untracked
/ip firewall filter add action=drop chain=input comment="== fw rejeita ssh externo ==" port=21,22,23,80,443,8728,8729,8291 protocol=tcp
/ip firewall filter add action=accept chain=input comment="== fw aceita tudo ==" disabled=yes
/ip firewall filter add action=drop chain=input comment="== fw rejeita tudo =="
/ip firewall filter add action=accept chain=forward comment="== rede local vs internet liberada =="
/ip firewall filter add action=accept chain=output comment="== trafego saida fw liberado =="
/ip firewall mangle add action=mark-connection chain=input comment="== Entrou pela VIVO, marca ==" connection-mark=no-mark in-interface-list=WAN-VIVO new-connection-mark=wan-vivo-mark passthrough=yes
/ip firewall mangle add action=mark-connection chain=input comment="== Entrou pela VIRTUA, marca ==" connection-mark=no-mark in-interface-list=WAN-VIRTUA new-connection-mark=wan-virtua-mark passthrough=yes
/ip firewall mangle add action=mark-routing chain=prerouting comment="== da LAN, tem mark VIVO, entao vai pela VIVO ==" connection-mark=WAN-VIVO in-interface-list=LAN new-routing-mark=wan-vivo-mark passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting comment="== da LAN, tem mark VIRTUA, entao vai pela VIRTUA ==" connection-mark=WAN-VIRTUA in-interface-list=LAN new-routing-mark=wan-virtua-mark passthrough=no
/ip firewall mangle add action=mark-connection chain=prerouting comment="== separacao trafego (disable) ==" connection-mark=no-mark disabled=yes dst-address-type=!local in-interface-list=LAN new-connection-mark=WAN-VIRTUA passthrough=no
/ip firewall mangle add action=mark-connection chain=prerouting comment="== separacao trafego (disable) ==" connection-mark=no-mark disabled=yes dst-address-type=!local in-interface-list=LAN new-connection-mark=WAN-VIVO passthrough=no
/ip firewall mangle add action=mark-routing chain=output comment="== trafego fw, tem mark VIRTUA, entao vai pela VIRTUA ==" connection-mark=WAN-VIRTUA new-routing-mark=wan-virtua-mark passthrough=no
/ip firewall mangle add action=mark-routing chain=output comment="== trafego fw, tem mark VIVO, entao vai pela VIVO ==" connection-mark=WAN-VIVO new-routing-mark=wan-vivo-mark passthrough=no
/ip firewall nat add action=masquerade chain=srcnat comment="== MASQ saindo pela wan-vivo ==" out-interface-list=WAN-VIVO
/ip firewall nat add action=masquerade chain=srcnat comment="== MASQ saindo pela wan-virtua ==" out-interface-list=WAN-VIRTUA
/ip route add distance=1 gateway=pppoe-vivo routing-mark=wan-vivo-mark
/ip route add distance=2 gateway=ether2 routing-mark=wan-virtua-mark
/ip route add distance=1 gateway=pppoe-vivo
/ip route add distance=2 gateway=ether2
/ip route add distance=1 dst-address=1.1.1.1/32 gateway=pppoe-vivo
/ip route add distance=20 dst-address=1.1.1.1/32 type=blackhole
/ip route rule add dst-address=192.168.88.0/24 table=main
/ip route rule add routing-mark=wan-virtua-mark table=wan-virtua-mark
/ip route rule add routing-mark=wan-vivo-mark table=wan-vivo-mark
/ipv6 address add address=::1 from-pool=ipv6-vivo interface=bridge
/ipv6 address add address=::1 from-pool=ipv6-virtua interface=ether2
/ipv6 dhcp-client add add-default-route=yes default-route-distance=2 disabled=yes interface=ether2 pool-name=ipv6-virtua request=prefix
/ipv6 dhcp-client add add-default-route=yes interface=pppoe-vivo pool-name=ipv6-vivo request=prefix
/ipv6 firewall address-list add address=::/128 comment="unspecified address" list=bad_ipv6
/ipv6 firewall address-list add address=::1/128 comment="RFC6890 lo" list=bad_ipv6
/ipv6 firewall address-list add address=fec0::/10 comment=site-local list=bad_ipv6
/ipv6 firewall address-list add address=::ffff:0.0.0.0/96 comment="RFC6890 IPv4 mapped" list=bad_ipv6
/ipv6 firewall address-list add address=::/96 comment="ipv4 compat" list=bad_ipv6
/ipv6 firewall address-list add address=100::/64 comment="RFC6890 discard only " list=not_global_ipv6
/ipv6 firewall address-list add address=2001:db8::/32 comment="RFC6890 documentation" list=bad_ipv6
/ipv6 firewall address-list add address=2001:10::/28 comment="RFC6890 orchid" list=bad_ipv6
/ipv6 firewall address-list add address=3ffe::/16 comment=6bone list=bad_ipv6
/ipv6 firewall address-list add address=fe80::/16 list=allowed
/ipv6 firewall address-list add address=ff02::/16 comment=multicast list=allowed
/ipv6 firewall address-list add address=2001::/32 comment="RFC6890 TEREDO" list=not_global_ipv6
/ipv6 firewall address-list add address=2001::/23 comment=RFC6890 list=bad_ipv6
/ipv6 firewall address-list add address=2001:2::/48 comment="RFC6890 Benchmark" list=not_global_ipv6
/ipv6 firewall address-list add address=fc00::/7 comment="RFC6890 Unique-Local" list=not_global_ipv6
/ipv6 firewall address-list add address=::/128 comment="IP unspecified" list=bad_dst_ipv6
/ipv6 firewall address-list add address=ff00::/8 comment=multicast list=bad_src_ipv6
/ipv6 firewall filter add action=accept chain=input comment="== fw aceita conexoes LAN ==" in-interface-list=LAN
/ipv6 firewall filter add action=accept chain=input comment="== fw aceita PING ==" protocol=icmpv6
/ipv6 firewall filter add action=accept chain=input comment="== fw aceita DHCPv6-Client prefix delegation ==" dst-port=546 protocol=udp src-address=fe80::/16
/ipv6 firewall filter add action=accept chain=input comment="== fw aceita UDP traceroute ==" port=33434-33534 protocol=udp
/ipv6 firewall filter add action=accept chain=input comment="== fw aceita conexoes previas ==" connection-state=established,related,untracked
/ipv6 firewall filter add action=accept chain=input comment="== servicos internet vs fw permitidos ==" disabled=yes dst-port=22 protocol=tcp
/ipv6 firewall filter add action=drop chain=input comment="== servicos internet vs fw proibidos ==" disabled=yes dst-port=21,22,23,80,443,8728,8729,8291 protocol=tcp
/ipv6 firewall filter add action=accept chain=input comment="== servicos fw aceita tudo ==" disabled=yes
/ipv6 firewall filter add action=drop chain=input comment="== servicos fw rejeita tudo =="
/ipv6 firewall filter add action=accept chain=forward comment="== rede local aceita ping ==" protocol=icmpv6
/ipv6 firewall filter add action=accept chain=forward comment="== rede local aceita conexoes previas ==" connection-state=established,related,untracked
/ipv6 firewall filter add action=drop chain=forward comment="== rede local descarta invalid ==" connection-state=invalid
/ipv6 firewall filter add action=accept chain=forward comment="== rede local vs internet permitidos ==" disabled=yes dst-port=80 in-interface-list=LAN protocol=tcp
/ipv6 firewall filter add action=accept chain=forward comment="== rede local vs internet liberada ==" in-interface-list=LAN
/ipv6 firewall filter add action=accept chain=forward comment="== internet vs rede local permitido ===" disabled=yes dst-port=22 out-interface-list=LAN protocol=tcp
/ipv6 firewall filter add action=drop chain=forward comment="== internet vs rede local rejeita tudo =="
/ipv6 nd add interface=bridge ra-interval=30s-1m
/system clock set time-zone-name=America/Sao_Paulo
/system ntp client set enabled=yes primary-ntp=200.192.232.8
/tool mac-server set allowed-interface-list=LAN
/tool mac-server mac-winbox set allowed-interface-list=LAN
/tool netwatch add comment=WAN-VIVO down-script=":log info \"Link VIVO fora\"\
    \n/ipv6 dhcp-client disable [find interface=pppoe-vivo]\
    \n/ipv6 dhcp-client enable [find interface=ether2]" host=1.1.1.1 up-script=":log info \"Link VIVO normalizado\"\
    \n/ipv6 dhcp-client enable [find interface=pppoe-vivo]\
    \n/ipv6 dhcp-client disable [find interface=ether2]"
