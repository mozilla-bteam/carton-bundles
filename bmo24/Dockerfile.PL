use Dockerfile;

FROM 'centos:6.7';

COPY ['rpm_list', '/rpm_list'];

RUN q{
    rpm -qa --queryformat '/^%{NAME}$/ d\n' > rpm_fix.sed &&
    sed -f rpm_fix.sed /rpm_list > /rpm_list.clean
};

RUN q{
    yum -y install epel-release &&
    yum -y install `cat /rpm_list.clean` &&
    yum clean all
};

RUN q{yum -y install centos-release-scl};
RUN q{yum -y install rh-perl524 rh-perl524-perl-core rh-perl524-mod_perl-devel.x86_64};
#DOCKER_ENV BASH_ENV => q{/opt/rh/rh-perl524/enable};
DOCKER_ENV LD_LIBRARY_PATH => '/opt/rh/rh-perl524/root/usr/lib64';
DOCKER_ENV PATH => '/opt/rh/rh-perl524/root/usr/local/bin:/opt/rh/rh-perl524/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

build_bundle(system_perl => '/opt/rh/rh-perl524/root/usr/bin/perl');

