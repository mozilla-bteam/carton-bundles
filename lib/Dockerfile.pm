package Dockerfile;
use strict;
use warnings;
use base qw(Exporter);
use Carp;
use Cwd 'realpath';
use File::Copy 'copy';
use File::Basename;
use FindBin;
use v5.10.1;

BEGIN { chdir $FindBin::Bin };

our $BASE_DIR = realpath("$FindBin::Bin/..");
our @EXPORT = qw(
    FROM RUN COPY ADD MAINTAINER 
    DOCKER_ENV build_tarball $BASE_DIR
);

my %env;
sub _CMD (@) {
    my $keyword = shift;
    say join(' ', $keyword, map { docker_arg($_, $keyword) } @_)
}

sub DOCKER_ENV ($$) {
    my ($k, $v) = @_;
    $env{$k} = 1;
    _CMD('ENV', $k, $v);
}

sub FROM ($)       { _CMD 'FROM', @_ }
sub ADD ($$)       { _CMD 'ADD', @_ }
sub COPY ($$)      { _CMD 'COPY', @_ }
sub MAINTAINER ($) { _CMD 'MAINTAINER', @_ }
sub WORKDIR ($)    { _CMD 'WORKDIR', @_ }

sub RUN (@) {
    if (@_ == 1) {
        _CMD 'RUN', $_[0];
    } else {
        say 'RUN [', join(', ', map { docker_quote($_) } @_), ']';
    }
}

sub CMD (@) {
    if (@_ == 1) {
        _CMD 'CMD', $_[0];
    } else {
        say 'CMD [', join(', ', map { docker_quote($_) } @_), ']';
    }
}

sub build_tarball {
    my $GEN_CPANFILE_ARGS = $ENV{GEN_CPANFILE_ARGS} // '-A -U pg -U oracle -U mod_perl';

    DOCKER_ENV NAME         => basename($FindBin::Bin);
    DOCKER_ENV BUGZILLA_DIR => '/opt/bugzilla';
    DOCKER_ENV PERL_DIR     => '/opt/vanilla-perl';
    DOCKER_ENV PERL         => '$PERL_DIR/bin/perl';
    DOCKER_ENV CARTON       => '$PERL_DIR/bin/carton';

    ADD 'https://raw.github.com/tokuhirom/Perl-Build/master/perl-build', '/usr/local/bin/perl-build';
    ADD 'https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm', '/usr/local/bin/cpanm';
    RUN 'chmod a+x /usr/local/bin/perl-build /usr/local/bin/cpanm';
    add_script('build-vanilla-perl');

    RUN 'build-vanilla-perl';
    RUN '$PERL /usr/local/bin/cpanm --notest --quiet Carton App::FatPacker File::pushd';

    RUN 'git clone $BUGZILLA_GIT $BUGZILLA_DIR';

    if (-f 'vendor.tar.gz') {
        WORKDIR '/opt/vendor';
        COPY 'vendor.tar.gz', 'vendor.tar.gz';
        RUN q{
            tar -xvf vendor.tar.gz &&
            mv $NAME/vendor $BUGZILLA_DIR/vendor &&
            rm vendor.tar.gz
        };
    }

    WORKDIR '$BUGZILLA_DIR';

    RUN '$PERL Makefile.PL';

    if (-f 'cpanfile') {
        COPY 'cpanfile', 'cpanfile';
    }
    else {
        RUN "make cpanfile GEN_CPANFILE_ARGS='$GEN_CPANFILE_ARGS'";
    }

    COPY 'cpanfile.snapshot', 'cpanfile.snapshot' if -f 'cpanfile.snapshot';

    add_script('probe-libs');
    add_script('probe-packages');
    add_script('build-bundle');
    CMD 'build-bundle';
}

sub add_script {
    my ($name) = @_;
    copy("$BASE_DIR/scripts/$name", "$name.tmp") or die "copy failed: $!";
    COPY "$name.tmp", "/usr/local/bin/$name";
    RUN "chmod a+x /usr/local/bin/$name";
}

sub docker_arg {
    my ($item, $keyword) = @_;
    my $prefix = ' ' x (length($keyword) + 1);
    $item =~ s/^\s+//gs;
    $item =~ s/\s+$//gs;
    $item =~ s/\n[ \t]*/ \\\n$prefix/gs;
    while ($item =~ /[^\\]\$(\w+)/g) {
        croak "Undefined variable: \$$1" unless $env{$1};
    }
    return $item;
}

sub docker_quote {
    my ($item) = @_;
    $item =~ s/(["\\])/\\$1/gs;
    $item =~ s/\n/\\n/gs;
    return qq{"$item"};
}

1;
