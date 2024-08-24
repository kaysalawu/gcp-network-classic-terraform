#cloud-config

write_files:
  - path: /opt/vyatta/etc/config/scripts/vyos-postconfig-bootup.script
    owner: root:vyattacfg
    permissions: '0775'
    content: |
      #!/bin/vbash
      source /opt/vyatta/etc/functions/script-template
      configure
      #!
      set system login user vyos authentication plaintext-password Password123
      #!

      #!
      set interfaces loopback lo address 22.22.22.22/32

      set protocols static route 10.20.1.2/32 next-hop 10.1.21.1

      #!


      set nat source rule 10 destination address '10.1.0.1'
      set nat source rule 10 outbound-interface 'eth0'
      set nat source rule 10 translation address '10.1.21.10'


      #!

      #!


      set interfaces tunnel tun0 address 172.16.2.2/24
      set interfaces tunnel tun0 encapsulation gre
      set interfaces tunnel tun0 source-address 10.1.21.10
      set interfaces tunnel tun0 remote 10.20.1.2


      #!


      set protocols bgp 65002 parameters router-id '22.22.22.22'


      set protocols bgp 65002 neighbor 172.16.2.1 remote-as '65020'
      set protocols bgp 65002 neighbor 172.16.2.1 address-family ipv4-unicast soft-reconfiguration inbound
      set protocols bgp 65002 neighbor 172.16.2.1 timers holdtime '60'
      set protocols bgp 65002 neighbor 172.16.2.1 timers keepalive '20'

      set protocols bgp 65002 neighbor 172.16.2.1 address-family ipv4-unicast route-map export 'MAP-OUT-SITE'


      set protocols bgp 65002 neighbor 172.16.2.1 address-family ipv4-unicast route-map import 'MAP-IN-SITE'


      set protocols bgp 65002 neighbor 172.16.2.1 ebgp-multihop 4


      set protocols bgp 65002 neighbor 10.1.21.20 remote-as '65022'
      set protocols bgp 65002 neighbor 10.1.21.20 address-family ipv4-unicast soft-reconfiguration inbound
      set protocols bgp 65002 neighbor 10.1.21.20 timers holdtime '60'
      set protocols bgp 65002 neighbor 10.1.21.20 timers keepalive '20'

      set protocols bgp 65002 neighbor 10.1.21.20 address-family ipv4-unicast route-map export 'MAP-OUT-CR'


      set protocols bgp 65002 neighbor 10.1.21.20 address-family ipv4-unicast route-map import 'MAP-IN-CR'


      set protocols bgp 65002 neighbor 10.1.21.20 ebgp-multihop 4


      set protocols bgp 65002 neighbor 10.1.21.30 remote-as '65022'
      set protocols bgp 65002 neighbor 10.1.21.30 address-family ipv4-unicast soft-reconfiguration inbound
      set protocols bgp 65002 neighbor 10.1.21.30 timers holdtime '60'
      set protocols bgp 65002 neighbor 10.1.21.30 timers keepalive '20'

      set protocols bgp 65002 neighbor 10.1.21.30 address-family ipv4-unicast route-map export 'MAP-OUT-CR'


      set protocols bgp 65002 neighbor 10.1.21.30 address-family ipv4-unicast route-map import 'MAP-IN-CR'


      set protocols bgp 65002 neighbor 10.1.21.30 ebgp-multihop 4


      #!
      set protocols bgp 65002 parameters graceful-restart

      #!


      #!


      set policy as-path-list AL-OUT-SITE rule 10 action 'deny'
      set policy as-path-list AL-OUT-SITE rule 10 regex '_16550_'



      set policy as-path-list AL-OUT-SITE rule 20 action 'permit'
      set policy as-path-list AL-OUT-SITE rule 20 regex '_'



      set policy as-path-list AL-IN-SITE rule 10 action 'deny'
      set policy as-path-list AL-IN-SITE rule 10 regex '_16550_'



      set policy as-path-list AL-IN-SITE rule 20 action 'permit'
      set policy as-path-list AL-IN-SITE rule 20 regex '_'



      set policy as-path-list AL-OUT-CR rule 10 action 'permit'
      set policy as-path-list AL-OUT-CR rule 10 regex '_'



      set policy as-path-list AL-IN-CR rule 10 action 'permit'
      set policy as-path-list AL-IN-CR rule 10 regex '_'


      #!


      set policy prefix-list PL-OUT-SITE rule 10 action 'permit'
      set policy prefix-list PL-OUT-SITE rule 10 prefix '10.0.0.0/8'



      set policy prefix-list PL-IN-SITE rule 10 action 'permit'
      set policy prefix-list PL-IN-SITE rule 10 prefix '10.20.0.0/16'



      set policy prefix-list PL-OUT-CR rule 10 action 'permit'
      set policy prefix-list PL-OUT-CR rule 10 prefix '10.20.0.0/16'



      set policy prefix-list PL-IN-CR rule 10 action 'permit'
      set policy prefix-list PL-IN-CR rule 10 prefix '10.0.0.0/8'


      #!



      set policy route-map MAP-OUT-SITE rule 20 action permit
      set policy route-map MAP-OUT-SITE rule 20 match ip address prefix-list 'PL-OUT-SITE'
      set policy route-map MAP-OUT-SITE rule 20 set metric '105'




      set policy route-map MAP-IN-SITE rule 20 action permit
      set policy route-map MAP-IN-SITE rule 20 match ip address prefix-list 'PL-IN-SITE'
      set policy route-map MAP-IN-SITE rule 20 set metric '105'




      set policy route-map MAP-OUT-CR rule 20 action permit
      set policy route-map MAP-OUT-CR rule 20 match ip address prefix-list 'PL-OUT-CR'
      set policy route-map MAP-OUT-CR rule 20 set metric '105'




      set policy route-map MAP-IN-CR rule 20 action permit
      set policy route-map MAP-IN-CR rule 20 match ip address prefix-list 'PL-IN-CR'
      set policy route-map MAP-IN-CR rule 20 set metric '105'


      #!
      commit
      #!


      run reset ip bgp 172.16.2.1

      run reset ip bgp 10.1.21.20

      run reset ip bgp 10.1.21.30


      save
      exit
      # Avoid manual config lock out (see e.g. https://forum.vyos.io/t/error-message-set-failed/296/5)
      chown -R root:vyattacfg /opt/vyatta/config/active/
      chown -R root:vyattacfg /opt/vyatta/etc/
