#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -u

PROXY=$1
MAC=$(curl -s http://169.254.169.254/latest/meta-data/mac/)
VPC_CIDR=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/vpc-ipv4-cidr-blocks | xargs | tr ' ' ',')

cat << EOF >> /etc/yum.conf
proxy=http://$PROXY
EOF

cat << EOF >> /etc/environment
http_proxy=http://$PROXY
https_proxy=http://$PROXY
HTTP_PROXY=http://$PROXY
HTTPS_PROXY=http://$PROXY
no_proxy=$VPC_CIDR,localhost,127.0.0.1,169.254.169.254,.internal,.eks.amazonaws.com
NO_PROXY=$VPC_CIDR,localhost,127.0.0.1,169.254.169.254,.internal,.eks.amazonaws.com
EOF

mkdir -p /etc/systemd/system/docker.service.d
cat << EOF > /etc/systemd/system/docker.service.d/proxy.conf
[Service]
EnvironmentFile=/etc/environment
EOF

mkdir -p /etc/systemd/system/kubelet.service.d
cat << EOF > /etc/systemd/system/kubelet.service.d/proxy.conf
[Service]
EnvironmentFile=/etc/environment
EOF

mkdir -p /etc/systemd/system/containerd.service.d
cat << EOF > /etc/systemd/system/containerd.service.d/proxy.conf
[Service]
EnvironmentFile=/etc/environment
EOF

mkdir -p /etc/systemd/system/sandbox-image.service.d
cat << EOF > /etc/systemd/system/sandbox-image.service.d/proxy.conf
[Service]
EnvironmentFile=/etc/environment
EOF

systemctl daemon-reload
systemctl enable --now --no-block containerd
