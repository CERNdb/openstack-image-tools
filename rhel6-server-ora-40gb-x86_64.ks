#
# KS used to create RHEL images for VMs with 40GB disks
#
install

# installation path, additional repositories
url --url http://linuxsoft.cern.ch/enterprise/rhel/server/6/6.6/x86_64/

repo --name="EPEL"             --baseurl http://linuxsoft.cern.ch/epel/6/x86_64
repo --name="RHEL - optional"  --baseurl http://linuxsoft.cern.ch/cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/optional/os
#repo --name="RHEL - updates"   --baseurl http://linuxsoft.cern.ch/rhel/rhel6server-x86_64/RPMS.updates/
repo --name="RHEL - fastrack"  --baseurl http://linuxsoft.cern.ch/cdn.redhat.com/content/fastrack/rhel/server/6/x86_64/os

text
key --skip
keyboard us
lang en_US.UTF-8
skipx
network --bootproto dhcp
rootpw --iscrypted NOT-A-ROOT-PASSWORD

# Firewall rules
firewall --enabled --ssh

# authconfig
authconfig --useshadow --enablemd5 --enablekrb5 --disablenis

selinux --enforcing
timezone --utc Europe/Zurich

# logging
logging --level=debug

bootloader --location=mbr --append="console=ttyS0,115200 console=tty0"
zerombr
clearpart --all --initlabel

# dedicated partition table
part /boot      --size=1024  --fstype ext4 --ondisk vda
part /          --size=5120 --fstype ext4 --ondisk vda
part /var       --size=5120 --fstype ext4 --ondisk vda
part /tmp       --size=5120 --fstype ext4 --ondisk vda
part /ORA       --size=10240 --fstype ext4 --ondisk vda --grow
part swap --size 4096

reboot

##############################################################################
#
# Packages
#
##############################################################################
%packages
@ Server Platform
pam_krb5
-yum-autoupdate
yum-plugin-priorities
-fprintd
%end

##############################################################################
#
# post installation part of the KickStart configuration file
#
##############################################################################
%post --log=/root/anaconda-post.log

/usr/bin/logger "Starting anaconda postinstall"

set -x 

#
# Update the machine
#
/usr/bin/yum update -y --skip-broken || :

#
# Misc fixes
#

# The net.bridge.* entries in /etc/sysctl.conf make "sysctl -p" fail if "bridge" module is not loaded...
/usr/bin/perl -ni -e '$_ = "### Commented out by CERN... $_" if /^net\.bridge/;print' /etc/sysctl.conf || :

%end
