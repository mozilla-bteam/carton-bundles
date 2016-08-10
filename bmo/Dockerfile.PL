use Dockerfile;

my $GIT_REPO = "git://github.com/dylanwh/bmo.git";

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

prepare_workdir {
    my $workdir = '/opt/bugzilla';
    RUN ["git", "clone", $GIT_REPO, $workdir];

    return $workdir;
};

build_bundle();
