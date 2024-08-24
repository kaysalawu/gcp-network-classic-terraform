#! /bin/bash

apt update
apt install -y tcpdump fping dnsutils python3-pip python-dev conntrack
pip3 install Flask requests

sysctl -w net.ipv4.conf.all.forwarding=1
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

export INT="http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/"

export ENS4=$(curl -H "Metadata-Flavor: Google" $INT/0/ip)
export ENS4_MASK=$(curl -H "Metadata-Flavor: Google" $INT/0/subnetmask)
export ENS4_DGW=$(curl -H "Metadata-Flavor: Google" $INT/0/gateway)

export ENS5=$(curl -H "Metadata-Flavor: Google" $INT/1/ip)
export ENS5_MASK=$(curl -H "Metadata-Flavor: Google" $INT/1/subnetmask)
export ENS5_DGW=$(curl -H "Metadata-Flavor: Google" $INT/1/gateway)

export ENS6=$(curl -H "Metadata-Flavor: Google" $INT/2/ip)
export ENS6_MASK=$(curl -H "Metadata-Flavor: Google" $INT/2/subnetmask)
export ENS6_DGW=$(curl -H "Metadata-Flavor: Google" $INT/2/gateway)

# ip tables
#-----------------------------------

# iptable rules specific to lb
iptables -A PREROUTING -t nat -p tcp --dport 8001 -j DNAT --to-destination 10.11.11.30:8080
iptables -A PREROUTING -t nat -p tcp --dport 8002 -j DNAT --to-destination 10.11.11.30:8080
iptables -A POSTROUTING -t nat -p tcp --dport 8001 -j SNAT --to-source 10.3.11.10
iptables -A POSTROUTING -t nat -p tcp --dport 8002 -j SNAT --to-source 10.3.11.10
iptables -A POSTROUTING -t nat -d 10.1.11.40 -j SNAT --to-source 10.1.11.50
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F

# ens5 (int vpc) routing
#-----------------------------------
echo "1 rt5" | sudo tee -a /etc/iproute2/rt_tables

# all traffic from/to ens5 should use rt5 for lookup
# subnet mask is used to expand entire range to include ilb vip
ip rule add from $ENS5_DGW/$ENS5_MASK table rt5
ip rule add to $ENS5_DGW/$ENS5_MASK table rt5
ip rule add to 10.11.0.0/16 table rt5

# send return gfe-traffic via ens5
ip route add 35.191.0.0/16 via $ENS5_DGW dev ens5 table rt5
ip route add 130.211.0.0/22 via $ENS5_DGW dev ens5 table rt5
ip route add 35.199.192.0/19 via $ENS5_DGW dev ens5 table rt5

# send traffic to peered vpc via ens5
ip route add 10.11.0.0/16 via $ENS5_DGW dev ens5 table rt5

# ens6 (mgt vpc) routing
#-----------------------------------
echo "2 rt6" | sudo tee -a /etc/iproute2/rt_tables

# all traffic from/to ens6 should use rt6 for lookup
# subnet mask is used to expand entire range to include ilb vip
ip rule add from $ENS6_DGW/$ENS6_MASK table rt6
ip rule add to $ENS6_DGW/$ENS6_MASK table rt6
ip rule add to 10.2.21.0/24 table rt6

# send return gfe-traffic via ens6
ip route add 35.191.0.0/16 via $ENS6_DGW dev ens6 table rt6
ip route add 130.211.0.0/22 via $ENS6_DGW dev ens6 table rt6
ip route add 35.199.192.0/19 via $ENS6_DGW dev ens6 table rt6

# send traffic to remote mgt subnet
ip route add 10.2.21.0/24 via $ENS6_DGW dev ens6 table rt6

# all other traffic go via default to ens4 (untrust vpc)

# health check web server
#-----------------------------------
mkdir /var/flaskapp
mkdir /var/flaskapp/flaskapp
mkdir /var/flaskapp/flaskapp/static
mkdir /var/flaskapp/flaskapp/templates

cat <<EOF > /var/flaskapp/flaskapp/__init__.py
from flask import Flask, request
app = Flask(__name__)
@app.route('/healthz')
def healthz():
    return 'pass'
if __name__ == "__main__":
    app.run(host= '0.0.0.0', port=8080, debug = True)
EOF
nohup python3 /var/flaskapp/flaskapp/__init__.py &
cat <<EOF > /var/tmp/startup.sh
nohup python3 /var/flaskapp/flaskapp/__init__.py &
EOF
echo "@reboot source /var/tmp/startup.sh" > /var/tmp/crontab.txt
crontab /var/tmp/crontab.txt

# playz script
#-----------------------------------
cat <<EOF > /usr/local/bin/playz
echo -e "\n curl ...\n"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null app1.site1.onprem:8080/) - app1.site1.onprem:8080/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null app1.site2.onprem:8080/) - app1.site2.onprem:8080/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null ilb4.eu.hub.gcp:8080/) - ilb4.eu.hub.gcp:8080/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null ilb4.us.hub.gcp:8080/) - ilb4.us.hub.gcp:8080/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null ilb7.eu.hub.gcp/) - ilb7.eu.hub.gcp/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null ilb7.us.hub.gcp/) - ilb7.us.hub.gcp/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null ilb4.eu.spoke1.gcp:8080/) - ilb4.eu.spoke1.gcp:8080/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null ilb4.us.spoke2.gcp:8080/) - ilb4.us.spoke2.gcp:8080/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null ilb7.eu.spoke1.gcp/) - ilb7.eu.spoke1.gcp/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null ilb7.us.spoke2.gcp/) - ilb7.us.spoke2.gcp/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null nva.eu.hub.gcp:8001/) - nva.eu.hub.gcp:8001/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null nva.eu.hub.gcp:8002/) - nva.eu.hub.gcp:8002/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null nva.us.hub.gcp:8001/) - nva.us.hub.gcp:8001/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null nva.us.hub.gcp:8002/) - nva.us.hub.gcp:8002/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null app1.eu.mgt.hub.gcp:8080/) - app1.eu.mgt.hub.gcp:8080/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null app1.us.mgt.hub.gcp:8080/) - app1.us.mgt.hub.gcp:8080/"
echo ""
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null psc4.consumer.spoke2-us-svc.psc.hub.gcp:8080) - psc4.consumer.spoke2-us-svc.psc.hub.gcp:8080"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null psc4.consumer.spoke2-us-svc.psc.spoke1.gcp:8080) - psc4.consumer.spoke2-us-svc.psc.spoke1.gcp:8080"
echo ""
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null www.googleapis.com/generate_204) - www.googleapis.com/generate_204"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null storage.googleapis.com/generate_204) - storage.googleapis.com/generate_204"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null europe-west2-run.googleapis.com/generate_204) - europe-west2-run.googleapis.com/generate_204"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null us-west2-run.googleapis.com/generate_204) - us-west2-run.googleapis.com/generate_204"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null europe-west2-run.googleapis.com/generate_204) - europe-west2-run.googleapis.com/generate_204"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null us-west2-run.googleapis.com/generate_204) - us-west2-run.googleapis.com/generate_204"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null https://d-hub-us-run-httpbin-i6ankopyoa-nw.a.run.app/) - https://d-hub-us-run-httpbin-i6ankopyoa-nw.a.run.app/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null https://d-spoke1-eu-run-httpbin-2zcsnlaqcq-nw.a.run.app/) - https://d-spoke1-eu-run-httpbin-2zcsnlaqcq-nw.a.run.app/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null https://d-spoke2-us-run-httpbin-bttbo6m6za-wl.a.run.app/) - https://d-spoke2-us-run-httpbin-bttbo6m6za-wl.a.run.app/"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null dhuball.p.googleapis.com/generate_204) - dhuball.p.googleapis.com/generate_204"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null dspoke1sec.p.googleapis.com/generate_204) - dspoke1sec.p.googleapis.com/generate_204"
echo  "\$(curl -kL -H 'Cache-Control: no-cache' --connect-timeout 1 -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null dspoke2sec.p.googleapis.com/generate_204) - dspoke2sec.p.googleapis.com/generate_204"
echo ""
EOF
chmod a+x /usr/local/bin/playz
