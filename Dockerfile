# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

FROM ubuntu:14.04

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5
RUN echo "deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.6" > /etc/apt/sources.list.d/mysql.list
RUN apt-get update
RUN apt-get install -y build-essential git libgd-dev libssl-dev mysql-client graphviz libmysqlclient-dev

ADD https://raw.github.com/tokuhirom/Perl-Build/master/perl-build /usr/local/bin/perl-build
ADD https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm /usr/local/bin/cpanm
RUN chmod a+x /usr/local/bin/perl-build /usr/local/bin/cpanm

ENV PERL_VER 5.18.2
ENV PERL_DIR /opt/perl-$PERL_VER
ENV PERL $PERL_DIR/bin/perl
ENV PERL_BUILD_OPTIONS --noman -A ccflags=-fPIC -D useshrplib
RUN perl-build $PERL_BUILD_OPTIONS $PERL_VER /opt/perl-$PERL_VER

RUN $PERL /usr/local/bin/cpanm Carton App::FatPacker File::pushd
ENV CARTON $PERL_DIR/bin/carton

COPY bugzilla.bmo/ /opt/bugzilla/

# some dependencies of our dependencies don't end up in
# the cpanfile.snapshot, so we add these to our cpanfile
RUN echo 'requires "Test::Requires";' > /cpanfile.more
RUN echo 'requires "File::Slurper";' >> /cpanfile.more

RUN cd /opt/bugzilla && \
    git clean -df && \
    $PERL Makefile.PL && \
    make cpanfile GEN_CPANFILE_ARGS='-A -U pg -U oracle -U mod_perl -U extension_push_optional'  && \
    cat /cpanfile.more >> cpanfile && \
    $CARTON install && \
    $CARTON bundle && \
    $CARTON fatpack && \
    rm -vfr local/lib/perl5

# Now install to the system perl to test
RUN cd /opt/bugzilla && ./vendor/bin/carton install --cached --deployment

RUN dpkg -l > /opt/bugzilla/DEB_LIST
RUN cd /opt/bugzilla && tar -zcf /vendor.tar.gz DEB_LIST cpanfile cpanfile.snapshot vendor && tar -zcf /local.tar.gz local
