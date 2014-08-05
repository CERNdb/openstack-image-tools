# System authorization information
auth --enableshadow --passalgo=sha512

# Reboot after installation
reboot

# installation path, additional repositories
url --url "http://linuxsoft.cern.ch/cern/centos/7/os/x86_64/"

# Use network installation
repo --name="EPEL" --baseurl="http://linuxsoft.cern.ch/epel/beta/7/x86_64" --cost=1
#repo --name="CentOS-7 - Updates" --baseurl http://linuxsoft.cern.ch/cern/centos/7/updates/x86_64/
#repo --name="CentOS-7 - Extras" --baseurl http://linuxsoft.cern.ch/cern/centos/7/extras/x86_64/
#repo --name="CentOS-7 - CERN" --baseurl http://linuxsoft.cern.ch/cern/centos/7/cern/x86_64/
#repo --name="CentOS-7 - CERNONLY" --baseurl http://linuxsoft.cern.ch/cern/centos/7/cernonly/x86_64/

text
skipx

# Firewall configuration
firewall --enabled --service=ssh
firstboot --disable
ignoredisk --only-use=vda

# Network information
network  --bootproto=dhcp

# Keyboard layouts
# old format: keyboard us
# new format:
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Root password
rootpw --iscrypted nope

# SELinux configuration
selinux --enforcing

# System services
services --disabled="kdump,rhsmcertd" --enabled="network,sshd,rsyslog,ovirt-guest-agent,chronyd"

# Agree to EULA
eula --agreed

# System timezone
timezone Europe/Zurich

# System bootloader configuration
bootloader --append="console=tty0" --location=mbr --timeout=1 --boot-drive=vda

# Clear the Master Boot Record
zerombr

# Partition clearing information
clearpart --all --initlabel 

# Disk partitioning information
part / --fstype="xfs" --ondisk=vda --size=6144

%post --erroronfail

# workaround anaconda requirements
passwd -d root
passwd -l root

# Create grub.conf for EC2. This used to be done by appliance creator but
# anaconda doesn't do it. And, in case appliance-creator is used, we're
# overriding it here so that both cases get the exact same file.
# Note that the console line is different -- that's because EC2 provides
# different virtual hardware, and this is a convenient way to act differently
echo -n "Creating grub.conf for pvgrub"
rootuuid=$( awk '$2=="/" { print $1 };'  /etc/fstab )
mkdir /boot/grub
echo -e 'default=0\ntimeout=0\n\n' > /boot/grub/grub.conf
for kv in $( ls -1v /boot/vmlinuz* |grep -v rescue |sed s/.*vmlinuz-//  ); do
  echo "title Red Hat Enterprise Linux 7 ($kv)" >> /boot/grub/grub.conf
  echo -e "\troot (hd0)" >> /boot/grub/grub.conf
  echo -e "\tkernel /boot/vmlinuz-$kv ro root=$rootuuid console=hvc0 LANG=en_US.UTF-8" >> /boot/grub/grub.conf
  echo -e "\tinitrd /boot/initramfs-$kv.img" >> /boot/grub/grub.conf
  echo
done

#link grub.conf to menu.lst for ec2 to work
echo -n "Linking menu.lst to old-style grub.conf for pv-grub"
ln -sf grub.conf /boot/grub/menu.lst
ln -sf /boot/grub/grub.conf /etc/grub.conf

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

# this is installed by default but we don't need it in virt
echo "Removing linux-firmware package."
yum -C -y remove linux-firmware

# Remove firewalld; it is required to be present for install/image building.
echo "Removing firewalld."
yum -C -y remove firewalld --setopt="clean_requirements_on_remove=1"

echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

echo -n "Network fixes"
# initscripts don't like this file to be missing.
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
PERSISTENT_DHCLIENT="1"
EOF

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tuned/active_profile

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# workaround https://bugzilla.redhat.com/show_bug.cgi?id=966888
if ! grep -q growpart /etc/cloud/cloud.cfg; then
  sed -i 's/ - resizefs/ - growpart\n - resizefs/' /etc/cloud/cloud.cfg
fi

# allow sudo powers to cloud-user
echo -e 'cloud-user\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

# Disable subscription-manager yum plugins
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/product-id.conf
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/subscription-manager.conf

echo "Cleaning old yum repodata."
yum clean all

# clean up installation logs"
rm -rf /var/log/yum.log
rm -rf /var/lib/yum/*
rm -rf /root/install.log
rm -rf /root/install.log.syslog
rm -rf /root/anaconda-ks.cfg
rm -rf /var/log/anaconda*

echo "Fixing SELinux contexts."
touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/yum
/usr/sbin/fixfiles -R -a restore

# reorder console entries
sed -i 's/console=tty0/console=tty0 console=ttyS0,115200n8/' /boot/grub2/grub.cfg
%end

%packages
@core
chrony
cloud-init
cloud-utils-growpart
dracut-config-generic
dracut-norescue
firewalld
grub2
kernel
nfs-utils
rsync
tar
yum-utils
-NetworkManager
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-biosdevname
-iprutils
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware
-plymouth

%end

