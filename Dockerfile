# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

FROM centos:6
RUN yum -y -q update && yum -q -y groupinstall  "Development Tools"
RUN yum -y -q install perl-core gd-devel expat-devel httpd-devel mysql-devel
ADD https://raw.github.com/tokuhirom/Perl-Build/master/perl-build /usr/local/bin/perl-build
ADD https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm /usr/local/bin/cpanm
RUN chmod a+x /usr/local/bin/perl-build /usr/local/bin/cpanm

ENV PERL_VER 5.10.1
ENV PERL_DIR /opt/perl-$PERL_VER
ENV PERL $PERL_DIR/bin/perl
ENV PERL_BUILD_OPTIONS --noman -A ccflags=-fPIC
RUN perl-build $PERL_BUILD_OPTIONS $PERL_VER /opt/perl-$PERL_VER
RUN $PERL /usr/local/bin/cpanm Carton App::FatPacker File::pushd
ENV CARTON $PERL_DIR/bin/carton

COPY bugzilla/ /opt/bugzilla/
RUN cd /opt/bugzilla && git clean -df
RUN cd /opt/bugzilla && $PERL Makefile.PL && make cpanfile && sed -i -e '/sqlite/ d' -e '/DBD::Pg/ d' -e '/Oracle/ d' -e '/mod_perl2/ d' cpanfile && $CARTON install
# RUN cd /opt/bugzilla && $CARMEL inject Module::Build
# RUN cd /opt/bugzilla && $CARMEL inject ExtUtils::MakeMaker
RUN cd /opt/bugzilla && $CARTON bundle && $CARTON fatpack && tar -zcf /vendor.tar.gz cpanfile cpanfile.snapshot vendor
