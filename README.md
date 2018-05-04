# Dependencies Installer
Run the following commands to create a new installer URL (e.g. https://bitbucket.org/realtimecontent/rtcbaseinstall/get/rhel_66_postgresql_v1.1.3.zip)

    git tag -a <branch>-v<next version> -m"Latest version of <branch> installer"
    git push --tags

## To delete a tag

    git tag -d <tag>
    git push origin :refs/tags/<tag>

## To build Mod-H264-Streaming

    sudo yum install gcc httpd-devel
    git clone git@bitbucket.org:realtimecontent/mod_h264_streaming.git
    cd mod_h264_streaming/v2.2.7_source
    ./configure
    make
    sudo make install
    cp /etc/httpd/modules/mod_h264_streaming.so .
