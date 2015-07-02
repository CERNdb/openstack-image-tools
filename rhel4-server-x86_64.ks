install

# installation path
#nfs --server linuxsoft.cern.ch --dir /enterprise/4ES_U8/en/os/x86_64
url --url http://linuxsoft.cern.ch/enterprise/4ES_U8/en/os/x86_64

text

keyboard us
lang en_US.UTF-8
langsupport --default en_US.UTF-8 en_US.UTF-8
mouse generic3ps/2 --device psaux
skipx
network --bootproto dhcp
rootpw --iscrypted NOT-A-ROOT-PASSWORD

# Firewall rules
firewall --enabled --ssh

timezone --utc Europe/Zurich

bootloader --location=mbr --append="console=ttyS0,115200 console=tty0"
zerombr
clearpart --all

part /boot --size   100 --ondisk vda --fstype ext3
part /     --size  6144 --ondisk vda --fstype ext3
part swap  --size  2048 --ondisk vda --fstype swap
part swap  --size  2048 --ondisk vda --fstype swap
part swap  --size  2048 --ondisk vda --fstype swap
part swap  --size  2048 --ondisk vda --fstype swap
part /var  --size  2048 --ondisk vda --fstype ext3 --grow
part /tmp  --size  3072 --ondisk vda --fstype ext3
part /ORA  --size 40960 --ondisk vda --fstype ext3

reboot

%packages
@core
@base
ntp

##############################################################################
#
# post installation part of the KickStart configuration file
#
##############################################################################
%post

/usr/bin/logger "Starting anaconda postinstall"

# redirect the output to the log file
exec >/root/anaconda-post.log 2>&1

# show the output on the seventh console
tail -f /root/anaconda-post.log >/dev/tty7 &

# changing to VT 7 that we can see what's going on....
/usr/bin/chvt 7

set -x 

#
# Configure up2date
#
/usr/bin/logger "Configuring up2date"
cat > /etc/sysconfig/rhn/sources << EOF
yum rhel4-os      http://linuxsoft.cern.ch/rhel/rhel4es-x86_64/RPMS.os
yum rhel4-updates http://linuxsoft.cern.ch/rhel/rhel4es-x86_64/RPMS.updates
yum rhel4-extras  http://linuxsoft.cern.ch/rhel/rhel4es-x86_64/RPMS.extras
EOF

#
# Update the machine
#
/usr/bin/logger "Updating the system"
rpm --import /usr/share/rhn/RPM-GPG-KEY
up2date up2date
up2date --update

#
# Misc fixes
#

exit 0
