#!/bin/sh

if [[ ! -d bugzilla || ! -f bugzilla/Makefile.PL ]]; then
    echo "You need a bugzilla checkout in the ./bugzilla dir, and it should have a Makefile.PL" >&1
    exit 1
fi

docker build -t bmo:latest .
docker rm bmo
docker run --name bmo bmo:latest
docker cp bmo:/vendor.tar.gz .
