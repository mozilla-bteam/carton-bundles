RUN qq{
    yum -y -q update &&
    yum -y -q groupinstall  "Development Tools" &&
    yum -y -q install perl-core gd-devel expat-devel httpd-devel mysql-devel
};
