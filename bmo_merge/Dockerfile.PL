use Dockerfile;

FROM 'centos:7';

COPY ['rpm_list', '/rpm_list'];

RUN q{
    yum -y install epel-release &&
    yum -y install `cat /rpm_list` &&
    yum clean all
};

git_clone("git://github.com/mozilla-bteam/bmo.git", "upstream-merge");

build_tarball();
