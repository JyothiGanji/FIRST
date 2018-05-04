function verifyPrograms() {
    for PROGRAM in $*
    do
        command -v $PROGRAM >/dev/null 2>&1 || { echo >&2 "$PROGRAM required but it's not installed."; }
    done
}

function getOptRtcBinaries() {
    find /opt/rtc/bin -maxdepth 1 -type f -executable
}

function verifyApacheModule() {
	if [ -z "`httpd -t -D DUMP_MODULES 2>&1 | grep $1`" ]
	then
		echo "Apache module $1 is not installed"
	fi
}

if [ $# == 0 ]
then
	result="$(sh $0 perform | tee /dev/tty)"
	if [ -z "$result" ]
	then
		echo Verification successful
	fi
else
	verifyPrograms httpd beanstalkd python pear git convert

	verifyApacheModule h264_streaming_module

	if [ ! -d "/opt/rtc/bin" ]; then
	    echo /opt/rtc/bin does not exist
	elif [ -z "`getOptRtcBinaries`" ]; then
	    echo Binaries have not been install under /opt/rtc/bin
	else
	    verifyPrograms `getOptRtcBinaries`
	fi

	python verifybase.py
	php verifybase.php
	ioncubetest=`php ioncube_loaders_verify.php`
	if [ "$ioncubetest" != 'OK' ]; then
	    echo ioncube not configured
	fi

	if [ ! -z "`which sestatus`" ] && [ ! -z "`sestatus | grep enforcing`" ]; then
	    echo SELinux must be disabled
	fi
fi

aws --version > /dev/null 2>&1
if [ $? != 0 ]
then
	echo "AWS CLI tools are not installed"
fi
