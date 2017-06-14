use Dockerfile;

FROM 'amazonlinux';

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

build_bundle();

RUN '$SYSTEM_PERL /usr/local/bin/cpanm Parse::CPAN::Meta';
