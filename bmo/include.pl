COPY "rpm_list /rpm_list";
ADD "https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm",
    "/usr/local/bin/cpanm";
RUN "chmod 755 /usr/local/bin/cpanm";

RUN q{
    rpm -qa --queryformat '/^%{NAME}$/ d\n' > rpm_fix.sed &&
    sed -f rpm_fix.sed /rpm_list > /rpm_list.clean
};

RUN q{
    yum -y install epel-release &&
    yum -y install `cat /rpm_list.clean` &&
    yum clean all
};

