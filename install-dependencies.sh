# freetype-devel???
# beanstalkd???
# pear Mail
# pear Net_SMTP

if [ `uname -m` != "x86_64" ]; then
   echo "ERROR: This script must be run on 64 bit linux."
   exit 1
fi

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
#

centosVersion=0
 if [ ! -z `uname -r | grep el6` ]; then
     centosVersion=6
 fi

 if [ ! -z `uname -r | grep el7` ]; then
     centosVersion=7
 fi

if [ $centosVersion -gt 6 ]; then
    echo "ERROR: You tried to install the EOV dependency installer for CentOS6 on CentOS7. Please install the EOV dependency installer for CentOS7 instead."
    exit 1
fi

function getTimezone() {
	if [ -f /etc/timezone ]
	then
		cat /etc/timezone
	elif [ -h /etc/localtime ]
	then
		readlink /etc/localtime | sed "s/.*\/usr\/share\/zoneinfo\///"
	else
		checksum=`md5sum /etc/localtime | cut -d' ' -f1`
		find /usr/share/zoneinfo/ -type f -exec md5sum {} \; | grep "^$checksum" | grep -v posix | egrep "/usr/share/zoneinfo/[^/]*/" | sed "s/.*\/usr\/share\/zoneinfo\///" | head -n 1
	fi
}

function installAwsCli() {
    if [ -z "`type aws 2> /dev/null`" ]
    then
        echo "Installing AWS CLI..."

        bundlePath="/tmp/awscli-bundle"
        zipPath="$bundlePath.zip"
        curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "$zipPath"

        if [ $? != 0 ]
        then
            echo "ERROR: Failed to download AWS CLI bundle"
            exit 1
        fi

        unzip "$zipPath" -d "/tmp"
        "$bundlePath/install" -i /usr/local/aws -b /usr/bin/aws

        aws --version > /dev/null 2>&1

        if [ $? != 0 ]
        then
            echo "ERROR: Failed to install AWS CLI"
            exit 1
        fi

        rm -rf "$zipPath" "$bundlePath"

        echo "Complete"
    fi
}

function yumInstall() {
    yum -y install $1

    if [ $? != 0 ] && [ ! -z "$2" ]
    then
        yum -y localinstall $2
    fi
}

yum -y update
yum -y install epel-release
yum -y install wget php php-pear php-gd php-devel php-xml php-pdo php-mysql libevent python-imaging python-devel php-mcrypt php-soap git freetype-devel mysql mod_ssl
yum -y install fonttools
yum -y install unzip
yum -y install memcached php-pecl-memcached

yumInstall php-mbstring rpms/php-mbstring-5.3.3-27.el6_5.x86_64.rpm
yumInstall libmcrypt rpms/libmcrypt-2.5.8-9.el6.x86_64.rpm
yumInstall php-mcrypt rpms/php-mcrypt-5.3.3-3.el6.x86_64.rpm

yum -y install ImageMagick
cp lib/aws.phar /usr/share/php/aws.phar
mkdir -p /opt/rtc/bin
chmod -R a+rx /opt/rtc
cp ffmpeg* ffprobe* mp4cat mp4len /opt/rtc/bin
chmod a+x /opt/rtc/bin/*

if [ `wc -c ffmpeg | awk '{print $1}'` -lt 64 ]
then
	ffmpegVer="`cat /opt/rtc/bin/ffmpeg`"
	rm /opt/rtc/bin/ffmpeg
	ln -s /opt/rtc/bin/$ffmpegVer /opt/rtc/bin/ffmpeg
fi

pushd src
# Following lines are not needed now that we use a static ffmpeg build

#git clone git://github.com/yasm/yasm.git
#pushd yasm && sh autogen.sh && make && make install && popd
#export PATH=$PATH:/usr/local/bin
#git clone git://git.videolan.org/x264.git x264
#pushd x264 && ./configure --enable-shared --extra-cflags=-fPIC --extra-asflags=-D__PIC__ && make && sudo make install && popd
#git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg
#pushd ffmpeg && ./configure --enable-nonfree --enable-libfreetype --enable-filter=drawtext --enable-libx264 --enable-gpl --enable-libfribidi --enable-libfaac && make && sudo make install && popd
#echo 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib' >> /etc/profile.d/ffmpeg.sh

popd

yum -y install beanstalkd
# curl -sS https://getcomposer.org/installer | php
# /root/composer.phar  install
pear install Mail-1.2.0
pear install Mail_Mime
pear install Net_SMTP
wget https://www.atomicorp.com/RPM-GPG-KEY.atomicorp.txt
mv RPM-GPG-KEY.atomicorp.txt /etc/pki/rpm-gpg/
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY.atomicorp.txt
wget http://updates.atomicorp.com/channels/atomic/centos/6/x86_64/RPMS/atomic-release-1.0-21.el6.art.noarch.rpm
rpm -Uvh atomic-release-1.0-21.el6.art.noarch.rpm
yum -y install php-ioncube-loader
phpVersion="`php -v | grep ^PHP | awk '{print $2}' | cut -d. -f-2`"
sed -ie 's/_.\{3\}\.so$/_'$phpVersion'.so/' /etc/php.d/ioncube.ini
cp etc/httpd/conf.d/mod_h264_streaming.conf /etc/httpd/conf.d/
mkdir -p /etc/httpd/modules
cp etc/httpd/modules/mod_h264_streaming.so /etc/httpd/modules/
chkconfig httpd on
chkconfig beanstalkd on
service httpd start
service beanstalkd start
iptables -I INPUT 5 -i eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
service iptables save
service iptables restart
service memcached start
chkconfig memcached on

installAwsCli

#Enable PHP short opening tags
sed -i 's/^\(short_open_tag[ =]*\)[a-z]*/\1On/gi' /etc/php.ini
#Update default timezone
if [ ! -z "`grep "^.date.timezone[= ]*$" /etc/php.ini`" ] || [ ! -z "`grep "^date.timezone[= ]*$" /etc/php.ini`" ]
then
	timezone=`getTimezone | sed 's/\//\\\\\\//g'`

	sed -i -e "s/^.*date.timezone *= *$/date.timezone = $timezone/g" /etc/php.ini
elif [ -z "`grep "^date.timezone" /etc/php.ini`" ]
then
	sed -i -e "s/;date.timezone/date.timezone/g" /etc/php.ini | grep timezone
fi

selinuxConfig="/etc/selinux/config"
if [ -f $selinuxConfig ] && [ ! -z "`sestatus | grep enforcing`" ]; then
    sed -i 's/^SELINUX=[a-z]*/SELINUX=disabled/g' $selinuxConfig

    command -v setenforce > /dev/null 2>&1
    if [ $? == 0 ]
    then
        setenforce 0
    else
        echo
        echo "### SELinux has been updated. Please reboot then run sh $( dirname $0 )/verifyBase.sh. ###"
        echo

        exit
    fi
fi

echo
echo "Verifying dependencies installation"
sh $( dirname $0 )/verifybase.sh
echo
