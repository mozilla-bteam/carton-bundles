# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

FROM centos:6

RUN yum -y -q update && \
    yum -y -q groupinstall  "Development Tools" && \
    yum -y -q install perl-core gd-devel expat-devel httpd-devel mysql-devel ImageMagick-perl mod_perl gmp gmp-devel

ADD https://raw.github.com/tokuhirom/Perl-Build/master/perl-build /usr/local/bin/perl-build
ADD https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm /usr/local/bin/cpanm
RUN chmod a+x /usr/local/bin/perl-build /usr/local/bin/cpanm

ENV PERL_VER 5.10.1
ENV PERL_DIR /opt/perl-$PERL_VER
ENV PERL $PERL_DIR/bin/perl
ENV PERL_BUILD_OPTIONS --noman -A ccflags=-fPIC -D useshrplib
RUN perl-build $PERL_BUILD_OPTIONS $PERL_VER /opt/perl-$PERL_VER

RUN $PERL /usr/local/bin/cpanm Carton App::FatPacker File::pushd
ENV CARTON $PERL_DIR/bin/carton

COPY bugzilla/ /opt/bugzilla/

RUN cd /opt/bugzilla && \
    git clean -df && \
    $PERL Makefile.PL && \
    make cpanfile GEN_CPANFILE_ARGS='-A -U pg -U oracle -U mod_perl'  && \
    $CARTON install && \
    $CARTON bundle && \
    $CARTON fatpack && \
    rm -vfr local/lib/perl5

# Now install to the system perl
RUN cd /opt/bugzilla && ./vendor/bin/carton install -cached --deployment

# And run tests
RUN cd /opt/bugzilla && prove -I local/lib/perl5 t
RUN rpm -qa > /opt/bugzilla/RPM_LIST
RUN cd /opt/bugzilla && tar -zcf /vendor.tar.gz RPM_LIST cpanfile cpanfile.snapshot vendor
