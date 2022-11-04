#!/bin/bash
# Start an instance of k3s server using docker image

# Identification of the server, used for directories names and disambiguate tokens and KUBECONFIG files
SERVERNAME=${SERVERNAME:-default_smarter}
# Especific port to be used at the server
HOSTPORT=${HOSTPORT:-6443}
# IP that the clients will be used to connect (If on the cloud it will probably be the external IP of the server)
# HOSTIP
# Which version of k3s or k8s to use
DOCKERIMAGE=${DOCKERIMAGE:-rancher/k3s:v1.25.2-k3s1}

# Do not set this variables, they are used below
CLOUD_INSTANCE=No

function check_running_cloud() {
    type cloud-init 2>/dev/null || CLOUD_INSTANCE=No;return

    echo "Cloud instance, grabbing the extrnal IP"
    CLOUD_INSTANCE=Yes

    echo "Getting platform info from cloud-init"
    export PLATFORM=$(sudo cloud-init query platform)

    if [ $? -ne 0 ]
    then
        echo "cloud-init failed, exiting script..."
        exit -1
    fi

    case ${PLATFORM} in
        ec2)
            # Use this export if AWS EC2
            echo "Running on AWS EC2"
            HOSTIP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4) || (echo "Not able to get IP address from AWS";exit -1)
            ;;

        gce)
            # Use this export if Google GCE
            echo "Running on Google GCE"
            HOSTIP=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
            ;;
        *)
            ;;
    esac
}

function check_main_ip() {
	DEFAULT_ROUTE=$(ip route | grep default | head -n 1)

	if [ -z "${DEFAULT_ROUTE}" ]
	then
		echo "no main route, so bailing"
		exit -1
	fi

	DEFAULT_DEV=$(echo "${DEFAULT_ROUTE}" | sed -e "s/^.* dev \([^ ]*\) .*/\1/")

	if [ "${DEFAULT_DEV}" == "${DEFAULT_ROUTE}" ]
	then
		echo "no dev in the route, check route \"${DEFAULT_ROUTE}\""
		exit -1
	fi

	HOSTIP=$(ip addr show dev ${DEFAULT_DEV} | grep " inet " | sed -e "s/^ *inet \([0-9.]*\)\/.*/\1/" )

	if [ -z "${HOSTIP}" ]
	then
		echo "Not able to find a suitable hostIP"
		exit -1
	fi

}

[ -z "${HOSTIP}" ] && check_running_cloud
[ -z "${HOSTIP}" ] && check_main_ip

echo "IP to use ${HOSTIP}"

START_FILE=start_k3s_${SERVERNAME}.sh
ENV_FILE=env-${SERVERNAME}.sh
KUBECTL_FILE=kubectl-${SERVERNAME}.sh
KUBECTL_EDGE_INSTALL_FILE=kube_edge_install-${SERVERNAME}.sh
LOCALSERVERDIR=$(pwd)/${SERVERNAME}

if [ ! -e "${START_FILE}" ]
then
	cat<<EOF >> "${START_FILE}"
#!/bin/bash
#
export SERVERNAME=${SERVERNAME}
export HOSTPORT=${HOSTPORT}
export HOSTIP=${HOSTIP}
export DOCKERIMAGE=${DOCKERIMAGE}

docker inspect k3s_${SERVERNAME} >/dev/null 2>&1 || \\
docker run -d --rm -p ${HOSTPORT}:${HOSTPORT} \\
      --name k3s_${SERVERNAME} \\
      -v ${LOCALSERVERDIR}:/var/lib/rancher/k3s \\
      ${DOCKERIMAGE} server \\
      --tls-san ${HOSTIP} \\
      --advertise-address ${HOSTIP} \\
      --https-listen-port ${HOSTPORT} \\
      --disable-agent \\
      --disable traefik \\
      --disable metrics-server \\
      --disable coredns \\
      --disable local-storage \\
      --flannel-backend=none
if [ ! -e kube.${SERVERNAME}.config  -o ! -e token.${SERVERNAME} ]
then
	sleep 30
	echo "Copying the secrets, token to token.${SERVERNAME} and kube.confg to kube.${SERVERNAME}.config"
	docker cp k3s_${SERVERNAME}:/etc/rancher/k3s/k3s.yaml kube.${SERVERNAME}.config
	sed -i -e "s/\(https:\/\/\)127.0.0.1/\1${HOSTIP}/" kube.${SERVERNAME}.config
	docker cp k3s_${SERVERNAME}://var/lib/rancher/k3s/server/token token.${SERVERNAME}
	if [ ! -e kube.${SERVERNAME}.config  -o ! -e token.${SERVERNAME} ]
	then
		docker stop stop k3s_${SERVERNAME}
		echo "Error in getting credentials"
		exit 1
	fi
fi
echo "k3s_${SERVERNAME} is running, access thois instance using the credentials at this directory"

exit 0
EOF
	chmod u+x  "${START_FILE}"
fi

./${START_FILE}

if [ $? -gt 0 ]
then
        echo "Docker failed......"
        exit -1
fi

echo "Checking k3s"
K3S_VERSION=$(echo ${DOCKERIMAGE} | cut -d ":" -f 2 | sed -e "s/-\(k3s[0-9]*\)$/+\1/")

case $(uname -m) in
	x86_64)
		FILE_DOWNLOAD=k3s;;
	aarch64)
		FILE_DOWNLOAD=k3s-arm64;;
	*)
		echo "Architecture not supported, download the specific k3s from https://github.com/k3s-io/k3s/releases/download/"
		exit 1;;
esac

if [ ! -e "${FILE_DOWNLOAD}" ]
then
        wget "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/${FILE_DOWNLOAD}"

	if [ ! -e "${FILE_DOWNLOAD}" ]
	then
		echo "Download failed....... sorry, but check to see what was wrong"
		exit 1
	fi
	chmod u+x "${FILE_DOWNLOAD}"
fi

if [ ! -e "${KUBECTL_FILE}" ]
then
	cat<<EOF > "${KUBECTL_FILE}"
#!/bin/bash

export KUBECONFIG=$(pwd)/kube.default_smarter.config

exec $(pwd)/${FILE_DOWNLOAD} kubectl \$*
EOF
	chmod u+x "${KUBECTL_FILE}"
fi

if [ ! -e "${ENV_FILE}" ]
then
	cat<<EOF > "${ENV_FILE}"
export KUBECONFIG=$(pwd)/kube.default_smarter.config
alias kubectl="$(pwd)/${FILE_DOWNLOAD} kubectl"
EOF
	chmod u+x "${ENV_FILE}"
fi

if [ ! -e "${KUBECTL_EDGE_INSTALL_FILE}" ]
then
	cat<<EOF > "${KUBECTL_EDGE_INSTALL_FILE}"
export INSTALL_K3S_VERSION="${K3S_VERSION}"
export K3S_TOKEN=$(cat token.${SERVERNAME})
export K3S_URL=https://${HOSTIP}:${HOSTPORT}

curl -sfL https://get.k3s.io | \\
sh -s - \\
  --kubelet-arg cluster-dns=169.254.0.2 \\
  --log /var/log/k3s.log \\
  --node-label smarter-device-manager=enabled \\
  --node-label smarter.cni=deploy \\
  --node-label smarter.cri=containerd \\
  --node-label smarter.nodetype=unknown \\
  --node-label smarter.nodemodel=unknown \\
  --node-label smarter.type=edge \\
  --node-taint smarter.type=edge:NoSchedule \\
  --node-label smarter-build=user-installed 
EOF
	chmod u+x "${KUBECTL_EDGE_INSTALL_FILE}"
fi

echo "an useful trick is to create an alias for shell like: alias kubectl='$(pwd)/${KUBECTL_FILE}', if that is your only k3s running"

exit 0
