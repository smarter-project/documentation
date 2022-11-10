# SMARTER Demo Deployment Instructions

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/smarter)](https://artifacthub.io/packages/search?repo=smarter)
## This demo makes the following assumptions about your environment

In the case you wish to deploy the demo we assume you have done the following:
- You should have a cloud-based k3s master dedicated for edge deployment (we will refer to this as k3s-edge-master) before proceeding any further
    - if you don't have a k3s-edge-master, you can follow [these instructions](./k3s-edge-master.md)
- You should also have an installed InfluxDB and Grafana instance in a separate kubernetes cluster
    - these may be installed on a second cloud node, with its own k3s master, we will refer to this as the cloud-data-node
    - if you don't have a cloud-data-node, you can follow [these instructions](./cloud-data-node.md)
- You will also need an installed k3s edge node which has already been setup to talk to k3s-edge-master
    - instructions for installing a SMARTER image on Xavier AGX 16GB or Rpi4 are available [here](http://gitlab.com/arm-research/smarter/smarter-yocto)
    - instructions for registering an arbitrary arm64 node running a **64 bit kernel and user space with docker installed** are available [here](./k3s-edge-master.md) under the section `Joining a non-yocto k3s node`
- You will need a KUBECONFIG that is authenticated against the k3s-edge-master on the Dev machine (where you intend to run these commands)
- Using our provided node images, your nodes should automatically register with the edge k3s master. You can verify this by running `kubectl get nodes -o wide`

**Hardware:** 
- Xavier AGX or Raspberry Pi 4 using our [Smarter Yocto Images](http://gitlab.com/arm-research/smarter/smarter-yocto) (release > v0.6.4.1)
- Rpi4 4GB running Ubuntu 19.10 (can be provisioned using smarter edge setup convenience script found in the scripts directory) or Xavier AGX 16GB running L4T 32.4.3 provided by the jetpack 4.4 release. Others have demonstrated this stack working on Nvidia Nano and Nvidia Xavier NX, but our team does not test on these platforms. Any Arm based device running a **64 bit kernel and user space with docker installed** should work. For instructions on how to register a **non-yocto** node, you can follow [these instructions](./k3s-edge-master.md) under the section `Joining a non-yocto k3s node`. Note that **Ubuntu 20.04** on the RPI 4 will **not** work, please use **19.10**
- PS3 Eye Camera (or Linux compatible web cam with audio) serving both audio and video data (other USB cameras with microphones may work). Microphone **MUST** support 16KHz sampling rate.
- A development machine (your work machine) setup to issue kubectl commands to your edge k3s cluster
- (optional) PMS7003 Air Quality Sensor connected over Serial USB to USB port
- (optional) Weather:bit connected over Serial USB to USB port

**Software:**
- Dev machine running kubectl client 1.25
- git, curl must also be installed
- K3s server version 1.25
- Node running docker > 18.09

**Connectivity:**
- You must be able to reach your node via IP on ports `22`(ssh) and `2520`(Webserver) from your dev machine for parts of this demo to work 
- The node must be able to reach your k3s-edge-master and cloud-data-node via IP

## Smarter k3s server configuration

- Use the helm chart on https://gitlab.com/smarter-project/documentation/chart to install CNI, DNS and device-manager
   ```bash
   helm install --namespace smarter --create-namespace smarter-edge chart
   ```
- Use the helm chart on each of the modules. Remember to use the namespace and the correct labels. The individual charts do not install on devices automatically, they require labels.

## To setup your registered edge node from your development machine
Plugin USB camera. You should be able to see the camera at `/dev/video0`.

The demo assumes that your microphone is assigned to card 2 device 0. On Jetson platforms the first usb microphone is automatically assigned to card 2 device 0, however on the **non-yocto** rpi4 devices this is not the default for instance. To fix this you must create the file `/etc/modprobe.d/alsa-base.conf` with the contents:
```
options snd_usb_audio index=2,3
options snd_usb_audio id="Mic1","Mic2"
```

On the rpi4 with **Ubuntu**, you must also append the text `cgroup_memory=1 cgroup_enable=memory` to the file:
```
- `/boot/firmware/nobtcmd.txt` if Ubuntu 19.10
- `/boot/firmware/cmdline.txt` if Ubuntu 20.04
```

Do not install docker using snap with **Ubuntu** instead install by running:
```bash
sudo apt update && sudo apt install docker.io
```

Then reboot the system.

If you are running on a **Xavier**(on the **non-yocto** build), **Xavier NX**, or a **Nano**, open the file `/etc/docker/daemon.json` on the device and ensure that the default runtime is set to nvidia. The file should look as follows:
```bash
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
```

For Single Tenant deployment instructions read [Here](./SingleTenantREADME.md)

For Virtual Tenant deployment instructions read [Here](./VirtualTenantREADME.md)
