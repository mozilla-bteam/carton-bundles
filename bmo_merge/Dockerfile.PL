use Dockerfile;

my $GIT_REPO   = "git://github.com/mozilla-bteam/bmo.git";
my $GIT_BRANCH = "upstream-merge";

FROM 'centos:7';

COPY ['rpm_list', '/rpm_list'];

RUN q{
    yum -y update &&
    yum -y install epel-release &&
    yum -y -q groupinstall  "Development Tools" &&
    yum -y install `cat /rpm_list` &&
    yum clean all
};

prepare_workdir {
    my $workdir = '/opt/bugzilla';

    COPY ["list-moreutils.patch", "/list-moreutils.patch"];
    RUN ["git", "clone", "-b", $GIT_BRANCH, $GIT_REPO, $workdir];
    WORKDIR $workdir;
    RUN ["git", "apply", "/list-moreutils.patch"];
    RUN ["rm", "-f", "t/013dbschema.t"];

    return $workdir;
};

build_bundle();
