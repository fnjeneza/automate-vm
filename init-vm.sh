#!/bin/bash

if [ -z $1 ]; then
  echo "Container name shall be provided"
  exit
fi

if [ -z $2 ]; then
  echo "Need a username"
  exit
fi

HOST=$1
USERNAME=$2

#mkpasswd --method=SHA-512 --rounds=4096 $USERNAME

echo "Copying VM image..."
cp $HOME/vm/images/debian.qcow2 $HOME/vm/images/$HOST.qcow2

echo "Exporting cloud-init config"
cat > user-data << EOF
#cloud-config

#apt:
#  proxy: http://[[user][:pass]@]host[:port]/
#  https_proxy: https://[[user][:pass]@]host[:port]/

#
## Upgrade the instance on first boot
## (ie run apt-get upgrade)
##
## Default: false
## Aliases: apt_upgrade
#package_upgrade: true

# Setup Hostname
preserve_hostname: false
hostname: $HOST

# Install packages
packages:
  - sudo
  - git
  - python3-venv

# Add users to the system
#users:
#  - name: $USERNAME
#    gecos: $USERNAME
#    lock_passwd: false
#    groups: [adm, cdrom, dialout, sudo, dip, floppy, plugdev, video, netdev]

# Remove cloud init
runcmd:
  - [dpkg-reconfigure, openssh-server]
  #- [apt, remove, -y, cloud-init]
# Output logs
output:
   all: ">> /var/log/cloud-init.log"
EOF

cat > meta-data << EOF
instance-id: $HOST; local-hostname: $HOST
EOF

echo "Running...
genisoimage -output $HOST-cidata.iso -volid cidata -joliet -r user-data meta-data &>> $HOST.log"
genisoimage -output $HOST-cidata.iso -volid cidata -joliet -r user-data meta-data &>> $HOST.log

echo "Running...
virt-install --import --name $HOST --memory 2048 --vcpus 2 --disk $HOME/vm/images/$HOST.qcow2,bus=virtio --disk $HOST-cidata.iso,device=cdrom --os-type=linux --os-variant=debian9 --noautoconsole"
virt-install --import --name $HOST --memory 2048 --vcpus 2 --disk $HOME/vm/images/$HOST.qcow2,bus=virtio --disk $HOST-cidata.iso,device=cdrom --os-type=linux --os-variant=debian9 --noautoconsole
