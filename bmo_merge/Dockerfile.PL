use Dockerfile;

$GIT_REPO   = "git://github.com/mozilla-bteam/bmo.git";
$GIT_BRANCH = "upstream-merge";
$GEN_CPANFILE_ARGS = '-A -U pg -U oracle -U mod_perl';

FROM 'centos:7';

COPY ['rpm_list', '/rpm_list'];

RUN q{
    yum -y update &&
    yum -y install epel-release &&
    yum -y -q groupinstall  "Development Tools" &&
    yum -y install `cat /rpm_list` &&
    yum clean all
};

after_clone {
    COPY ["list-moreutils.patch", "/list-moreutils.patch"];
    RUN ["git", "apply", "/list-moreutils.patch"];
    RUN ["rm", "-f", "t/013dbschema.t"];
};

build_bundle();
