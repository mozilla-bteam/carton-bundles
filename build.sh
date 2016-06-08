#!/bin/sh

if [[ ! -d bugzilla.bmo || ! -f bugzilla.bmo/Makefile.PL ]]; then
    echo "You need a bugzilla checkout in the ./bugzilla.bmo dir, and it should have a Makefile.PL" >&1
    exit 1
fi

docker build -t bmo:latest .
docker rm bmo
docker run --name bmo bmo:latest
docker cp bmo:/vendor.tar.gz .
docker cp bmo:/local.tar.gz .
