use Dockerfile;

FROM 'centos:7';

DOCKER_ENV BUGZILLA_GIT => 'git://github.com/bugzilla/bugzilla.git';

RUN qq{
    yum -y -q update &&
    yum -y -q groupinstall  "Development Tools" &&
    yum -y -q install
        expat-devel
        gd-devel
        httpd-devel
        mysql-devel
        openssl
        openssl-devel
        perl-core
};

build_tarball();
