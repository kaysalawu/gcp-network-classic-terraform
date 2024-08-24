# LAB E: NVA with Shared VPC <!-- omit from toc -->

Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Outputs](#outputs)
- [Testing](#testing)
  - [1. Test Site1 (On-premises)](#1-test-site1-on-premises)
  - [2. test from Spoke2 (Cloud)](#2-test-from-spoke2-cloud)
- [Cleanup](#cleanup)
- [Requirements](#requirements)
- [Inputs](#inputs)
- [Outputs](#outputs-1)

## Overview

In this lab:

* A Shared VPC architecture using network virtual appliances (NVA) appliance for traffic inspection.
* NVA appliances are simulated using iptables on Linux instances.
* All north-south and east-west traffic are allowed via the NVA instances in this lab.
* Hybrid connectivity to simulated on-premises sites is achieved using HA VPN.
* [Network Connectivity Center router appliances](https://cloud.google.com/network-connectivity/docs/network-connectivity-center/concepts/ra-overview) are used to connect the on-premises sites together via the external Hub VPC.
* Other networking features such as Cloud DNS, PSC for Google APIs and load balancers are also deployed in this lab.

<img src="./image.png" alt="NVA with Shared VPC" width="1200">

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/README.md) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/gcp-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd gcp-network-terraform/1-blueprints-e-nva-shared-vpc
   ```
3. (Optional) If you want to enable additional features such as IPv6, VPC flow logs and logging set the following variables to `true` in the [`01-main.tf`](./01-main.tf) file.

   | Variable | Description | Default | Link |
   |----------|-------------|---------|------|
   | enable_ipv6 | Enable IPv6 on all supported resources | false | [main.tf](./01-main.tf#L21) |
   ||||

4. Run the following terraform commands and type ***yes*** at the prompt:

   ```sh
   terraform init
   terraform plan
   terraform apply -parallelism=50
   ```

## Troubleshooting

See the [troubleshooting](../../troubleshooting/README.md) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Outputs

The table below shows the auto-generated output files from the lab. They are located in the `_output` directory.

| Item    | Description  | Location |
|--------|--------|--------|
| Hub EU NVA | Linux iptables, web server and test scripts | [_output/hub-eu-nva.sh](./_output/hub-eu-nva.sh) |
| Hub US NVA | Linux iptables, web server and test scripts | [_output/hub-us-nva.sh](./_output/hub-us-nva.sh) |
| Hub Unbound DNS | Unbound DNS configuration | [_output/hub-unbound.sh](./_output/hub-unbound.sh) |
| Site1 Unbound DNS | Unbound DNS configuration | [_output/site1-unbound.sh](./_output/site1-unbound.sh) |
| Site2 Unbound DNS | Unbound DNS configuration | [_output/site2-unbound.sh](./_output/site2-unbound.sh) |
| Web server | Python Flask web server, test scripts | [_output/vm-startup.sh](./_output/vm-startup.sh) |
||||

## Testing

Each virtual machine (VM) is pre-configured with a shell [script](../../scripts/startup/gce.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines. In each VM instance, The pre-configured test script `/usr/local/bin/playz` can be run from the SSH terminal to test network reachability.

The full list of the scripts in each VM instance is shown below:

```sh
$ ls -l /usr/local/bin/
-rwxr-xr-x 1 root root   98 Aug 17 14:58 aiz
-rwxr-xr-x 1 root root  203 Aug 17 14:58 bucketz
-rw-r--r-- 1 root root 1383 Aug 17 14:58 discoverz.py
-rwxr-xr-x 1 root root 1692 Aug 17 14:58 pingz
-rwxr-xr-x 1 root root 5986 Aug 17 14:58 playz
-rwxr-xr-x 1 root root 1957 Aug 17 14:58 probez
```

### 1. Test Site1 (On-premises)

**1.1** Login to the instance `e-site1-vm` using the [SSH-in-Browser](https://cloud.google.com/compute/docs/ssh-in-browser) from the Google Cloud console.

**1.2** Run the `playz` script to test network reachability to all VM instances.

```sh
playz
```

<details>

<summary>Sample output</summary>

```sh
admin_cloudtuple_com@e-site1-vm:~$ playz

 apps ...

200 (0.006121s) - 10.10.1.9 - app1.site1.onprem:8080/
200 (0.293658s) - 10.20.1.9 - app1.site2.onprem:8080/
200 (0.016132s) - 10.1.11.70 - ilb4.eu.hub.gcp:8080/
200 (0.292465s) - 10.1.21.70 - ilb4.us.hub.gcp:8080/
200 (0.033704s) - 10.1.11.80 - ilb7.eu.hub.gcp/
000 (2.002704s) -  - ilb7.us.hub.gcp/
000 (2.002140s) -  - ilb4.eu.spoke1.gcp:8080/
200 (0.289768s) - 10.22.21.30 - ilb4.us.spoke2.gcp:8080/
000 (2.002861s) -  - ilb7.eu.spoke1.gcp/
200 (0.711261s) - 10.22.21.40 - ilb7.us.spoke2.gcp/
000 (2.002878s) -  - nva.eu.hub.gcp:8001/
000 (2.002512s) -  - nva.eu.hub.gcp:8002/
200 (0.290562s) - 10.1.21.60 - nva.us.hub.gcp:8001/
200 (0.289146s) - 10.1.21.60 - nva.us.hub.gcp:8002/
200 (0.010735s) - 10.2.11.30 - app1.eu.mgt.hub.gcp:8080/
200 (0.291079s) - 10.2.21.30 - app1.us.mgt.hub.gcp:8080/

 psc4 ...

000 (0.128859s) -  - psc4.consumer.spoke2-us-svc.psc.hub.gcp:8080
000 (0.128147s) -  - psc4.consumer.spoke2-us-svc.psc.spoke1.gcp:8080

 apis ...

204 (0.003096s) - 142.250.180.10 - www.googleapis.com/generate_204
204 (0.012345s) - 10.1.0.1 - storage.googleapis.com/generate_204
204 (0.036484s) - 10.1.11.80 - europe-west2-run.googleapis.com/generate_204
204 (1.735335s) - 10.22.21.40 - us-west2-run.googleapis.com/generate_204
204 (1.531734s) - 10.1.11.80 - europe-west2-run.googleapis.com/generate_204
204 (1.724371s) - 10.22.21.40 - us-west2-run.googleapis.com/generate_204
200 (0.042181s) - 10.1.0.1 - https://e-hub-us-run-httpbin-i6ankopyoa-nw.a.run.app/
200 (0.034820s) - 10.1.0.1 - https://e-spoke1-eu-run-httpbin-2zcsnlaqcq-nw.a.run.app/
200 (0.857989s) - 10.1.0.1 - https://e-spoke2-us-run-httpbin-bttbo6m6za-wl.a.run.app/
204 (0.006566s) - 10.1.0.1 - ehuball.p.googleapis.com/generate_204
204 (0.003310s) - 216.58.212.234 - espoke1sec.p.googleapis.com/generate_204
204 (0.002643s) - 216.58.213.10 - espoke2sec.p.googleapis.com/generate_204
```

</details>
<p>

**1.3** Run the `pingz` script to test ICMP reachability to all VM instances.

```sh
pingz
```

<details>

<summary>Sample output</summary>

```sh
admin_cloudtuple_com@e-site1-vm:~$ pingz

 ping ...

app1.site1.onprem - OK 0.028 ms
app1.site2.onprem - OK 139.828 ms
ilb4.eu.hub.gcp - NA
ilb4.us.hub.gcp - NA
ilb7.eu.hub.gcp - NA
ilb7.us.hub.gcp - NA
ilb4.eu.spoke1.gcp - NA
ilb4.us.spoke2.gcp - NA
ilb7.eu.spoke1.gcp - NA
ilb7.us.spoke2.gcp - NA
nva.eu.hub.gcp - NA
nva.us.hub.gcp - NA
app1.eu.mgt.hub.gcp - OK 3.066 ms
app1.us.mgt.hub.gcp - OK 138.660 ms
```

</details>
<p>

**1.4** Run the `bucketz` script to test access to selected Google Cloud Storage buckets.

```sh
bucketz
```

<details>

<summary>Sample output</summary>

```sh
admin_cloudtuple_com@e-site1-vm:~$ bucketz

hub : <--- HUB EU --->

spoke1 : <--- SPOKE 1 --->

spoke2 : <--- SPOKE 2 --->
```

</details>
<p>

**1.5** On your local terminal or Cloud Shell, run the `discoverz.py` script to test access to all Google API endpoints.

```sh
gcloud compute ssh e-site1-vm \
--project $TF_VAR_project_id_onprem \
--zone europe-west2-b \
-- 'python3 /usr/local/bin/discoverz.py' | tee  _output/site1-api-discovery.txt
```

The script save the output to the file [_output/site1-vm-api-discoverz.sh`](./_output/site1-api-discovery.txt).

### 2. test from Spoke2 (Cloud)

Login to the instance `e-spoke2-us-ilb4-vm` using the [SSH-in-Browser](https://cloud.google.com/compute/docs/ssh-in-browser) from the Google Cloud console.


```sh
playz
```

<details>

<summary>Sample output</summary>

```sh
admin_cloudtuple_com@e-spoke1-eu-ilb4-vm:~$ playz

 apps ...

200 (0.015715s) - 10.10.1.9 - app1.site1.onprem:8080/
200 (0.292626s) - 10.20.1.9 - app1.site2.onprem:8080/
200 (0.008328s) - 10.1.11.70 - ilb4.eu.hub.gcp:8080/
200 (0.287474s) - 10.1.21.70 - ilb4.us.hub.gcp:8080/
200 (0.032460s) - 10.1.11.80 - ilb7.eu.hub.gcp/
000 (2.002568s) -  - ilb7.us.hub.gcp/
200 (0.006243s) - 10.11.11.30 - ilb4.eu.spoke1.gcp:8080/
200 (0.289221s) - 10.22.21.30 - ilb4.us.spoke2.gcp:8080/
200 (0.028811s) - 10.11.11.40 - ilb7.eu.spoke1.gcp/
000 (2.002104s) -  - ilb7.us.spoke2.gcp/
000 (2.003020s) -  - nva.eu.hub.gcp:8001/
000 (2.002195s) -  - nva.eu.hub.gcp:8002/
000 (2.002044s) -  - nva.us.hub.gcp:8001/
000 (2.002865s) -  - nva.us.hub.gcp:8002/
200 (0.007992s) - 10.2.11.30 - app1.eu.mgt.hub.gcp:8080/
200 (0.289815s) - 10.2.21.30 - app1.us.mgt.hub.gcp:8080/

 psc4 ...

000 (0.007476s) -  - psc4.consumer.spoke2-us-svc.psc.hub.gcp:8080
000 (0.007462s) -  - psc4.consumer.spoke2-us-svc.psc.spoke1.gcp:8080

 apis ...

204 (0.003026s) - 216.58.213.10 - www.googleapis.com/generate_204
204 (0.003987s) - 10.2.0.1 - storage.googleapis.com/generate_204
204 (0.002326s) - 10.2.0.1 - europe-west2-run.googleapis.com/generate_204
204 (0.002383s) - 10.2.0.1 - us-west2-run.googleapis.com/generate_204
204 (0.002566s) - 10.2.0.1 - europe-west2-run.googleapis.com/generate_204
204 (0.002507s) - 10.2.0.1 - us-west2-run.googleapis.com/generate_204
200 (0.029421s) - 10.2.0.1 - https://e-hub-us-run-httpbin-i6ankopyoa-nw.a.run.app/
200 (0.029301s) - 10.2.0.1 - https://e-spoke1-eu-run-httpbin-2zcsnlaqcq-nw.a.run.app/
200 (0.854403s) - 10.2.0.1 - https://e-spoke2-us-run-httpbin-bttbo6m6za-wl.a.run.app/
000 (0.007430s) -  - ehuball.p.googleapis.com/generate_204
000 (0.007478s) -  - espoke1sec.p.googleapis.com/generate_204
000 (0.007448s) -  - espoke2sec.p.googleapis.com/generate_204
```

</details>
<p>

**1.3** Run the `pingz` script to test ICMP reachability to all VM instances.

```sh
pingz
```

<details>

<summary>Sample output</summary>

```sh
admin_cloudtuple_com@e-spoke1-eu-ilb4-vm:~$ pingz

 ping ...

app1.site1.onprem - OK 2.073 ms
app1.site2.onprem - OK 137.929 ms
ilb4.eu.hub.gcp - NA
ilb4.us.hub.gcp - NA
ilb7.eu.hub.gcp - NA
ilb7.us.hub.gcp - NA
ilb4.eu.spoke1.gcp - OK 0.026 ms
ilb4.us.spoke2.gcp - NA
ilb7.eu.spoke1.gcp - NA
ilb7.us.spoke2.gcp - NA
nva.eu.hub.gcp - OK 0.912 ms
nva.us.hub.gcp - NA
app1.eu.mgt.hub.gcp - OK 1.296 ms
app1.us.mgt.hub.gcp - OK 136.736 ms
```

</details>
<p>

**1.4** Run the `bucketz` script to test access to selected Google Cloud Storage buckets.

```sh
bucketz
```

<details>

<summary>Sample output</summary>

```sh
admin_cloudtuple_com@e-spoke1-eu-ilb4-vm:~$ bucketz

hub : <--- HUB EU --->

spoke1 : <--- SPOKE 1 --->

spoke2 : <--- SPOKE 2 --->
```

</details>
<p>

**1.5** On your local terminal or Cloud Shell, run the `discoverz.py` script to test access to all Google API endpoints.

```sh
gcloud compute ssh e-spoke1-eu-ilb4-vm \
--project $TF_VAR_project_id_spoke1 \
--zone europe-west2-b \
-- 'python3 /usr/local/bin/discoverz.py' | tee  _output/spoke1-api-discovery.txt
```

The script save the output to the file [_output/spoke1-api-discovery.txt`](./_output/spoke1-api-discovery.txt).

## Cleanup

1\. (Optional) Navigate back to the lab directory (if you are not already there).

```sh
cd gcp-network-terraform/1-blueprints-e-nva-shared-vpc
```

2\. Run terraform destroy twice.

The second run is required to delete the the *null_resource* resource that could not be deleted on teh first run due to race conditions.

```sh
terraform destroy -auto-approve
terraform destroy -auto-approve
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bgp_range"></a> [bgp\_range](#input\_bgp\_range) | bgp interface ip cidr ranges. | `map(string)` | <pre>{<br>  "cidr1": "169.254.101.0/30",<br>  "cidr10": "169.254.110.0/30",<br>  "cidr2": "169.254.102.0/30",<br>  "cidr3": "169.254.103.0/30",<br>  "cidr4": "169.254.104.0/30",<br>  "cidr5": "169.254.105.0/30",<br>  "cidr6": "169.254.106.0/30",<br>  "cidr7": "169.254.107.0/30",<br>  "cidr8": "169.254.108.0/30",<br>  "cidr9": "169.254.109.0/30"<br>}</pre> | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | disk size | `string` | `"20"` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | disk type | `string` | `"pd-ssd"` | no |
| <a name="input_gre_range"></a> [gre\_range](#input\_gre\_range) | gre interface ip cidr ranges. | `map(string)` | <pre>{<br>  "cidr1": "172.16.1.0/24",<br>  "cidr2": "172.16.2.0/24",<br>  "cidr3": "172.16.3.0/24",<br>  "cidr4": "172.16.4.0/24",<br>  "cidr5": "172.16.5.0/24",<br>  "cidr6": "172.16.6.0/24",<br>  "cidr7": "172.16.7.0/24",<br>  "cidr8": "172.16.8.0/24"<br>}</pre> | no |
| <a name="input_image_cos"></a> [image\_cos](#input\_image\_cos) | container optimized image | `string` | `"cos-cloud/cos-stable"` | no |
| <a name="input_image_debian"></a> [image\_debian](#input\_image\_debian) | vm instance image | `string` | `"debian-cloud/debian-12"` | no |
| <a name="input_image_panos"></a> [image\_panos](#input\_image\_panos) | palo alto image from gcp marketplace | `string` | `"https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-bundle1-810"` | no |
| <a name="input_image_ubuntu"></a> [image\_ubuntu](#input\_image\_ubuntu) | vm instance image | `string` | `"ubuntu-os-cloud/ubuntu-2404-lts-amd64"` | no |
| <a name="input_image_vyos"></a> [image\_vyos](#input\_image\_vyos) | vyos image from gcp marketplace | `string` | `"https://www.googleapis.com/compute/v1/projects/sentrium-public/global/images/vyos-1-3-0"` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | vm instance size | `string` | `"e2-micro"` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | organization id | `any` | `null` | no |
| <a name="input_project_id_host"></a> [project\_id\_host](#input\_project\_id\_host) | host project id | `any` | n/a | yes |
| <a name="input_project_id_hub"></a> [project\_id\_hub](#input\_project\_id\_hub) | hub project id | `any` | n/a | yes |
| <a name="input_project_id_onprem"></a> [project\_id\_onprem](#input\_project\_id\_onprem) | onprem project id (for onprem site1 and site2) | `any` | n/a | yes |
| <a name="input_project_id_spoke1"></a> [project\_id\_spoke1](#input\_project\_id\_spoke1) | spoke1 project id (service project id attached to the host project | `any` | n/a | yes |
| <a name="input_project_id_spoke2"></a> [project\_id\_spoke2](#input\_project\_id\_spoke2) | spoke2 project id (standalone project) | `any` | n/a | yes |
| <a name="input_shielded_config"></a> [shielded\_config](#input\_shielded\_config) | Shielded VM configuration of the instances. | `map` | <pre>{<br>  "enable_integrity_monitoring": true,<br>  "enable_secure_boot": true,<br>  "enable_vtpm": true<br>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
