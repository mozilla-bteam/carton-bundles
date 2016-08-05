RUN qq{
    apt-key adv --keyserver ha.pool.sks-keyservers.net
                --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5
};


RUN qq{
    echo "deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.6" >
          /etc/apt/sources.list.d/mysql.list
};

RUN qq{
    apt-get update &&
    apt-get --no-install-recommends -y
    install apache2 build-essential
            cvs g++ git graphviz
            libapache2-mod-perl2
            libdaemon-generic-perl libfile-slurp-perl libdbd-mysql-perl
            libgd-dev libssl-dev
            mysql-client mysql-server
            patchutils pkg-config
            unzip wget libgmp10
};

