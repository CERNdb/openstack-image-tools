install

# installation path, additional repositories
url --url http://linuxsoft.cern.ch/enterprise/5Server_U11/en/os/x86_64

repo --name="EPEL"            --baseurl http://linuxsoft.cern.ch/epel/5/x86_64
repo --name="RHEL - updates"  --baseurl http://linuxsoft.cern.ch/rhel/rhel5server-x86_64/RPMS.updates/
repo --name="RHEL - fastrack" --baseurl http://linuxsoft.cern.ch/rhel/rhel5server-x86_64/RPMS.fastrack/

text

key --skip
keyboard us
lang en_US.UTF-8
langsupport --default en_US.UTF-8 en_US.UTF-8
mouse generic3ps/2 --device psaux
skipx
network --bootproto dhcp
rootpw --iscrypted NOT-A-ROOT-PASSWORD

# Firewall rules
firewall --enabled --ssh

# authconfig
authconfig --enableshadow --enablemd5

selinux --enforcing
timezone --utc Europe/Zurich

bootloader --location=mbr --append="console=ttyS0,115200 console=tty0"
zerombr
clearpart --all

part /boot --size=1024  --fstype ext3 --ondisk vda
part /     --size=10240 --fstype ext3 --ondisk vda
part /var  --size=10240 --fstype ext3 --ondisk vda
part /tmp  --size=10240 --fstype ext3 --ondisk vda
part /ORA  --size=10240 --fstype ext3 --ondisk vda --grow
part swap  --size 4096

reboot

%packages
@core
@base
-yum-autoupdate
yum-protectbase
yum-priorities
python-hashlib
ntp
zsh

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
# Update the machine
#
/usr/bin/yum update -y --skip-broken || :

#
# Misc fixes
#

exit 0
