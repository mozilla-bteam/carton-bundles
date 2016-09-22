use Dockerfile;

$GIT_REPO   = "git://github.com/mozilla-bteam/bmo.git";
$GIT_BRANCH = "upstream-merge";

FROM 'centos:7';

COPY ['rpm_list', '/rpm_list'];

RUN q{
    yum -y update &&
    yum -y install epel-release &&
    yum -y -q groupinstall  "Development Tools" &&
    yum -y install `cat /rpm_list` &&
    yum clean all
};

build_bundle();
