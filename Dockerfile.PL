#!/usr/bin/perl
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

use strict;
use warnings;
use v5.10.1;

BEGIN {
    my @keywords = qw(FROM ENV RUN COPY ADD);
    no strict 'refs';
    foreach my $keyword (@keywords) {
        *{$keyword} = sub (@) { say join(' ', $keyword, map { docker_escape($_) } @_) };
    }
};

my $DOCKER_IMAGE      = $ENV{DOCKER_IMAGE}      // 'mozillabteam/bmo-base:20160804.01';
my $BUGZILLA_GIT      = $ENV{BUGZILLA_GIT}      // 'https://github.com/mozilla-bteam/bmo.git';
my $GEN_CPANFILE_ARGS = $ENV{GEN_CPANFILE_ARGS} // '-A -U pg -U oracle -U mod_perl';

my $BUGZILLA_DIR = '/opt/bugzilla';
my $PERL_DIR     = '/opt/vanilla-perl';
my $PERL         = "$PERL_DIR/bin/perl";
my $CARTON       = "$PERL_DIR/bin/carton";

FROM $DOCKER_IMAGE;

require "include.PL" if -f "include.PL";

ADD 'https://raw.github.com/tokuhirom/Perl-Build/master/perl-build /usr/local/bin/perl-build';
ADD 'https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm /usr/local/bin/cpanm';
COPY 'build-vanilla-perl /usr/local/bin/build-vanilla-perl';
COPY 'probe-packages', '/usr/local/bin/probe-packages';
COPY 'probe-libs', '/usr/local/bin/probe-libs';

RUN 'chmod a+x /usr/local/bin/*';

RUN 'build-vanilla-perl';
RUN "$PERL /usr/local/bin/cpanm --notest --quiet Carton App::FatPacker File::pushd";

RUN "git clone $BUGZILLA_GIT $BUGZILLA_DIR";
RUN "cd $BUGZILLA_DIR && $PERL Makefile.PL";

if (-f 'cpanfile') {
    COPY 'cpanfile', "$BUGZILLA_DIR/cpanfile";
}
else {
    RUN "cd $BUGZILLA_DIR && make cpanfile GEN_CPANFILE_ARGS='$GEN_CPANFILE_ARGS'";
}

COPY 'cpanfile.snapshot', "$BUGZILLA_DIR/cpanfile.snapshot" if -f 'cpanfile.snapshot';

RUN qq{
    cd $BUGZILLA_DIR &&
    $PERL $CARTON install &&
    $PERL $CARTON bundle &&
    $PERL $CARTON fatpack &&
    rm -vfr local/lib/perl5
};

# Now install to the system perl
RUN "cd $BUGZILLA_DIR && perl ./vendor/bin/carton install --cached --deployment";
RUN "cd $BUGZILLA_DIR && prove -I local/lib/perl5 t";

RUN "probe-packages > $BUGZILLA_DIR/PACKAGES.txt";
RUN "cd $BUGZILLA_DIR && tar -zcf /vendor.tar.gz PACKAGES.txt cpanfile cpanfile.snapshot vendor";

sub docker_escape {
    my ($item) = @_;
    $item =~ s/^\s+//gs;
    $item =~ s/\s+$//gs;
    $item =~ s/\n/ \\\n/gs;
    return $item;
}
