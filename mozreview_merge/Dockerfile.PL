use Dockerfile;

my $GIT_REPO   = "git://github.com/mozilla-bteam/bmo.git";
my $GIT_BRANCH = "upstream-merge";

FROM 'ubuntu:14.04';

RUN qq{
    apt-key adv --keyserver ha.pool.sks-keyservers.net
                --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5
};

COPY "mysql.list", "/etc/apt/sources.list.d/mysql.list";

RUN qq{
    apt-get update &&
    apt-get --no-install-recommends -y install
        apache2
        build-essential
        cvs
        g++
        git
        graphviz
        libapache2-mod-perl2
        libdaemon-generic-perl
        libfile-slurp-perl
        libgd-dev
        libgmp3-dev
        libmysqlclient-dev
        libssl-dev
        mysql-client
        mysql-server
        patchutils
        pkg-config
        unzip
        wget
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
