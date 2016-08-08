=======================
Bugzilla Carton Bundles
=======================

This is a makefile and some scripts used for generating multiple
similar-but-different dockerfiles which are used to vendor bundles for
various Bugzilla configurations.

These vendor bundles come with all the CPAN modules required to run bugzilla
on a given system, the executable used to install them (vendor/bin/carton),
the lists of system packages (rpm or dpkg) to ensure they can be compiled,
and the cpanfile and cpanfile.snapshot used by carton.

*Note* It is highly recommended to commit the cpanfile.snapshot to the repository if
at all possible.

REQUIREMENTS
============

- GNU make
- perl 5.10.1 or newer
- docker (tested with 1.11.1)

Usage
=====

just run 'make' to build a vendor bundle.

.. code-block:: bash

    make bmo/vendor.tar.gz
    # or
    make mozreview/vendor.tar.gz

Linux Users
-----------
The scripts and makefile assume they can run "docker" as the current user.
On linux, docker must typically be run by root. You can instruct the Makefile
to use "sudo docker" by exporting and environmental variable 'DOCKER'

.. code-block:: bash

    DOCKER="sudo docker" make ...



Dockerfile.PL
=============

Dockerfile.PL is a thin perl-based sugar around Dockerfile syntax.

.. code-block:: perl

    use Dockerfile;

    FROM 'centos:6';

    DOCKER_ENV BUGZILLA_GIT => 'git://github.com/dylanwh/bmo.git';

    COPY 'rpm_list', '/rpm_list';

    RUN q{
        yum -y install epel-release &&
        yum -y install `cat /rpm_list` &&
        yum clean all
    };

    build_tarball();

As you can see, many docker commands are represented by the same word in perl,
except DOCKER_ENV replaces ENV due to a limitation of perl.
All of these functions are defined in lib/Dockerfile.pm
and simply output correct dockerfile syntax (in most cases, anyway).

RUN
---

This function behaves much the same as the docker namesake.
If passed a single argument, it behaves like the shell-based RUN command.
With multiple arguments, it uses the JSON array encoding, so you can do:

.. code-block:: perl

    RUN 'perl', '-E', 'say "Hello, world"'.

The single-argument form also ignores newlines, so you don't need to end lines with a backslash.

DOCKER_ENV
----------

Same as ENV. Because ENV is a perl special word, this function is spelled differently.
Note that Dockerfile.PL is smart enough to catch you using undeclared docker environmental variables.

*TODO*: Support ARG.

Other Docker Commands
---------------------

- CMD (same as RUN in syntax)
- WORKDIR
- COPY
- ADD
- MAINTAINER
- FROM

add_script()
------------

This will cause a file in the scripts() directory (at the level of the Makefile)
to be copied into /usr/local/bin inside the docker image. It will also be made executable.

Note that COPY can only refer to files in the build context, which is where the Dockerfile.PL is.


build_tarball()
---------------

build_tarball() is bulk of the automation: given a working compiler
and libraries, it will build the vendor tarball containing all the dependencies
specified in the cpanfile.

Adding New Targets
==================

Each target gets its own directory and a Dockerfile.PL

The Dockerfile.PL must begin with 'use Dockerfile; FROM "SOME IMAGE"' and need to have a compiler and all the development libraries and headers required to build
all the CPAN dependencies specified in the cpanfile.

After that, there should be a call to build_tarball(). 

Remember that the vendor bundle is not build when the image is built, but is
built when the container is run.

cpanfile
--------

If there is no cpanfile, build_tarball() will build one by running Makefile.PL && make cpanfile.
The list of features compiled in can be controlled with a docker environmental variable GEN_CPANFILE_FLAGS.

Alternatively, if a cpanfile is present in the target directory, it will be copied
into the $BUGZILLA_GIT checkout during the image build.

cpanfile.snapshot
-----------------

If this file is present in the target directory, it will take precedence over
the one provided in the git repository.

vendor.tar.gz
-------------

If present, this file will be uploaded to the docker image during the build
process, and will speed up subsequent builds.


License
=======

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

This Source Code Form is "Incompatible With Secondary Licenses", as
defined by the Mozilla Public License, v. 2.0.

However, this is all only relevant to you if you want to modify the code and
redistribute it. As with all open source software, there are no restrictions
on running it, or on modifying it for your own purposes.
