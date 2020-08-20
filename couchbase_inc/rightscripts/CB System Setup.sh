#!  /bin/bash -x

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0"
fi

shopt -s nocasematch
shopt -s expand_aliases
exec &> >(tee -ia /var/log/couchbase_right_script.log)

alias echo='{ save_flags="$-"; set +x;} 2> /dev/null; echo_and_restore'
echo_and_restore() {
        builtin echo "$*"
        case "$save_flags" in
         (*x*)  set -x
        esac
}

echo "Running Couchbase CB System Setup Script:"
echo `date`

if [ "$CB_ROOT_PASS" ]; then
  sudo sh -c 'echo $CB_ROOT_PASS | (passwd --stdin root)'
  sudo sh -c 'echo "root:$CB_ROOT_PASS" | /usr/sbin/chpasswd'
  sudo sh -c 'sed -ie "s/.*PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config'
  sudo sh -c 'sed -ie "s/.*PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config'
  sudo sh -c 'service sshd restart'
  sudo sh -c 'service ssh restart'
  echo $CB_ROOT_PASS | (passwd --stdin root)
  echo "root:$CB_ROOT_PASS" | /usr/sbin/chpasswd
  sed -ie "s/.*PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
  sed -ie "s/.*PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config
  service sshd restart
  service ssh restart
fi

if [ "$CB_ROOT_SSH_AUTH" ]; then
  echo "Updating list of authorized root ssh keys";
  #sudo sh -c 'curl -k -L "https://www.dropbox.com/s/gcwcs6lpbru11sj/authorized_keys.txt?dl=0" > /root/.ssh/authorized_keys'
  #curl -k -L "https://www.dropbox.com/s/gcwcs6lpbru11sj/authorized_keys.txt?dl=0" > /root/.ssh/authorized_keys
  sudo sh -c 'curl -s -k -L "https://raw.githubusercontent.com/couchbaselabs/technical_field_team/master/authorized_keys" > /root/.ssh/authorized_keys'
  curl -s -k -L "https://raw.githubusercontent.com/couchbaselabs/technical_field_team/master/authorized_keys" > /root/.ssh/authorized_keys
fi

####################################
if rpm --test; then  #RHEL/CentOS
 #echo "Downloading nodejs package:"
#  curl https://rpm.nodesource.com/setup_4.x | bash
  echo "Installing Amazon Linux Extras:"
    amazon-linux-extras install epel;
  echo "Installing epel-release:"
  if ! yum -y -q install epel-release; then
    if ! yum -y -q install epel-release; then
      echo "Could not install epel-release";
      exit 1;
    fi
  fi
#yum -y -q remove nodejs

  packages="make git openssl python-pip emacs telnet python-dev* xfsprogs vim wget at bc ntp ntpdate parallel curl nss nss-util nspr gcc gcc-c++ java iperf3 bind-utils lvm2 sysstat screen unzip --enablerepo=epel"
  echo "Installing yum packages: $packages"
  #yum update -y
  if ! yum  -y -q --skip-broken install $packages; then
    if ! yum  -y -q --skip-broken install $packages; then
      echo "Could not install packages";
      exit 1;
    fi
  fi


else   #Ubuntu

  echo "Setting up to install Java:"
  add-apt-repository -y ppa:openjdk-r/ppa

  echo "Downloading nodejs package:"
  #curl https://deb.nodesource.com/setup_4.x | bash -

  apt update
  apt-get update

  echo "Installing apt packages:"
  apt-get -qq -f install libcouchbase-dev* libcouchbase2-bin software-properties-common python-software-properties python-pip python-httplib2 \
    openjdk-8* iperf unzip build-essential git openssl emacs telnet xfsprogs vim wget at bc ntp lvm
  apt-get -qq -f install python-httplib2

fi
echo "Shutting off iptables and firewalld:"
service iptables stop
service firewalld stop
systemctl stop iptables
systemctl stop firewalld

echo "Set swappiness to 0":
echo 0 > /proc/sys/vm/swappiness
# Set the value in /etc/sysctl.conf so it stays after reboot.
echo "" >> /etc/sysctl.conf
echo "#Set swappiness to 0 to avoid swapping" >> /etc/sysctl.conf
echo "vm.swappiness = 0" >> /etc/sysctl.conf

echo "Turning off THP:"
if [ -d /sys/kernel/mm/transparent_hugepage ]; then
    echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
    echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
    echo 'never' > /sys/kernel/mm/redhat_transparent_hugepage/enabled
    echo 'never' > /sys/kernel/mm/redhat_transparent_hugepage/defrag
else
    return 0
fi

echo "Setting up NTP:"
service ntpd stop
service ntp stop
ntpdate 0.pool.ntp.org;
service ntpd start
service ntp start

####################################

#create ephemeral volume-------------
#undo Amazon Linux
for i in `ls -d /media/ephemeral*`; do
  umount "$i"
done

####################################
# Not sure if the snippet of logic above is used anymore or not
####################################

# Look for any unmounted devices
for i in `ls /dev | egrep "xvd|nvme.n" | grep -v xvdp`; do
  echo $i
  if ! `grep -q $i /proc/mounts`; then
    devices+="/dev/$i "
  fi
done

# Mount devices if they exist
if [ -n "$devices" ]; then
  # Devices exist, proceed to mount at /ephemeral
  mkdir /ephemeral
  if [[ "$CB_SERVER_ANALYTICS_DISK" == TRUE ]]; then
    # Analytics enabled for this node, user wants the attached devices to be used as analytics devices
    echo "Configuring devices for analytics"
    mkdir -p /tmp/couchbase/
    for i in $devices; do
      pvcreate -f $i
      mkfs.xfs -f $i

      dir="/ephemeral/analytics/"`echo $i | awk '{split($0,a,"/"); print a[3]}'`
      mkdir -p $dir
      mount -o noatime,nobarrier $i $dir
      if [[ "$CB_SERVER_DISK" == "-1" ]]; then
        echo "$dir" >> /tmp/couchbase/analytics_devices
      fi
    done
  else
    # Otherwise, devices are combined into a logical volume group for /couchbase to be installed to
    echo "Creating logical volume from attached devices"
    pvcreate $devices
    vgcreate vgroup $devices
    lvcreate --name volume --extents 100%FREE vgroup

    echo "Mounting volume to /ephemeral"
    mkfs.xfs /dev/vgroup/volume
    mount -o noatime,nobarrier /dev/vgroup/volume /ephemeral

    if [[ "$CB_SERVER_DISK" == "-1" ]] || [[ "$devices" == *"nvme1n1"* ]]; then
      # N.B. some instances attach SSD instead of EBS, this does not persist and so should behave the same as ephemeral
      # Create symbolic link between /couchbase and /ephemeral
      ln -s /ephemeral /couchbase
    fi
  fi
  chmod -R 777 /ephemeral/
fi

if [[ -e /root/.couchbase/system_setup ]]; then
  echo "Don't want to run a second time."
  exit 0;
else
  mkdir -p /root/.couchbase/system_setup
fi

#Check for EBS Mounted Storage
mkdir /couchbase
if [ -e "/dev/xvdp" ]; then
  # Mount ebs partition
  mkfs.xfs /dev/xvdp
  echo "/dev/xvdp /couchbase xfs defaults,nofail    0    1" >> /etc/fstab
  mount -a
fi

####################################

cd /root
#echo -e "-fqsL" >> .curlrc

if rpm --test; then  #RHEL/CentOS
  echo "Downloading Couchbase C-SDK:"
  curl -s -O http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-4-x86_64.rpm
  rpm --quiet -i couchbase-release-1.0-4-x86_64.rpm
    if ! yum -y -q install libcouchbase-dev* libcouchbase2-bin; then
    if ! yum -y -q install libcouchbase-dev* libcouchbase2-bin; then
      echo "Could not install libcouchbase";
    fi
  fi



else   #Ubuntu
  echo "Downloading Couchbase release package:"
  curl -s -O http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-4-amd64.deb
  dpkg -i couchbase-release-1.0-4-amd64.deb

  echo "Setting up to install Java:"
  add-apt-repository -y ppa:openjdk-r/ppa

fi

echo "Setting up NTP:"
service ntpd stop
service ntp stop
ntpdate 0.pool.ntp.org;
service ntpd start
service ntp start

echo "Downloading YCSB:"
curl -s -OL https://github.com/brianfrankcooper/YCSB/releases/download/0.11.0/ycsb-0.11.0.tar.gz
tar xfz ycsb-0.11.0.tar.gz

echo "Installing NVM (log output redirected to /var/log/couchbase_nvm_install.log):"
#curl -s https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash &>> /var/log/couchbase_nvm_install.log
curl -s https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash &>> /var/log/couchbase_nvm_install.log
source /root/.nvm/nvm.sh &>> /var/log/couchbase_nvm_install.log
. ~/.bashrc
nvm install 9 &>> /var/log/couchbase_nvm_install.log
nvm alias default node &>> /var/log/couchbase_nvm_install.log

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

echo "Installing Fakit:"
#npm --quiet install fakeit --global
git clone --quiet https://github.com/bentonam/fakeit
cd fakeit
make install
make build
npm link

echo "Installing Python SDK:"
pip install --upgrade pip
hash -r
pip install couchbase==2.5.7



#################################
if [ -z "$CB_SHUTDOWN" ];then
echo "Not setting the shutdown timer"
exit 0;
fi

echo "Shutting down in $CB_SHUTDOWN minutes"
#shutdown -hP +$CB_SHUTDOWN &

#rs_run_right_script -i 547634003

echo "rs_shutdown -ti;" | at now + $CB_SHUTDOWN minutes
let "CB_SHUTDOWN+=5"
echo "shutdown -hP now;" | at now + $CB_SHUTDOWN minutes


###########################
exit 0;