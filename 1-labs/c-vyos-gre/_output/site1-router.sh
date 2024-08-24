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
      set interfaces loopback lo address 1.1.1.1/32

      set protocols static route 10.10.0.0/16 next-hop 10.10.1.1

      set protocols static route 10.1.11.10/32 next-hop 10.10.1.1

      #!



      #!

      #!


      set interfaces tunnel tun0 address 172.16.1.1/24
      set interfaces tunnel tun0 encapsulation gre
      set interfaces tunnel tun0 source-address 10.10.1.2
      set interfaces tunnel tun0 remote 10.1.11.10


      #!


      set protocols bgp 65010 parameters router-id '1.1.1.1'


      set protocols bgp 65010 neighbor 172.16.1.2 remote-as '65001'
      set protocols bgp 65010 neighbor 172.16.1.2 address-family ipv4-unicast soft-reconfiguration inbound
      set protocols bgp 65010 neighbor 172.16.1.2 timers holdtime '60'
      set protocols bgp 65010 neighbor 172.16.1.2 timers keepalive '20'

      set protocols bgp 65010 neighbor 172.16.1.2 address-family ipv4-unicast route-map export 'MAP-OUT-HUB'


      set protocols bgp 65010 neighbor 172.16.1.2 address-family ipv4-unicast route-map import 'MAP-IN-HUB'


      set protocols bgp 65010 neighbor 172.16.1.2 ebgp-multihop 4


      #!
      set protocols bgp 65010 parameters graceful-restart

      set protocols bgp 65010 address-family ipv4-unicast redistribute static metric 90

      #!


      #!


      set policy as-path-list AL-OUT-HUB rule 10 action 'permit'
      set policy as-path-list AL-OUT-HUB rule 10 regex '_'



      set policy as-path-list AL-IN-HUB rule 10 action 'permit'
      set policy as-path-list AL-IN-HUB rule 10 regex '_'


      #!


      set policy prefix-list PL-OUT-HUB rule 10 action 'permit'
      set policy prefix-list PL-OUT-HUB rule 10 prefix '10.10.0.0/16'



      set policy prefix-list PL-IN-HUB rule 10 action 'permit'
      set policy prefix-list PL-IN-HUB rule 10 prefix '10.0.0.0/8'


      #!


      set policy route-map MAP-OUT-HUB rule 10 action 'permit'
      set policy route-map MAP-OUT-HUB rule 10 match as-path 'AL-OUT-HUB'
      set policy route-map MAP-OUT-HUB rule 10 set metric '100'





      set policy route-map MAP-OUT-HUB rule 20 action permit
      set policy route-map MAP-OUT-HUB rule 20 match ip address prefix-list 'PL-OUT-HUB'
      set policy route-map MAP-OUT-HUB rule 20 set metric '105'



      set policy route-map MAP-IN-HUB rule 10 action 'permit'
      set policy route-map MAP-IN-HUB rule 10 match as-path 'AL-IN-HUB'
      set policy route-map MAP-IN-HUB rule 10 set metric '100'





      set policy route-map MAP-IN-HUB rule 20 action permit
      set policy route-map MAP-IN-HUB rule 20 match ip address prefix-list 'PL-IN-HUB'
      set policy route-map MAP-IN-HUB rule 20 set metric '105'


      #!
      commit
      #!


      run reset ip bgp 172.16.1.2


      save
      exit
      # Avoid manual config lock out (see e.g. https://forum.vyos.io/t/error-message-set-failed/296/5)
      chown -R root:vyattacfg /opt/vyatta/config/active/
      chown -R root:vyattacfg /opt/vyatta/etc/
