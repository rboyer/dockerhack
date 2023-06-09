#!/bin/bash

set -euo pipefail

unset CDPATH

cd "$(dirname "$0")"

# If we're not on OS X, then error
case $OSTYPE in
    darwin*)
        set -x
        wget -q https://desktop.docker.com/mac/main/amd64/Docker.dmg
        sudo hdiutil attach -noverify Docker.dmg
        sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license --user=runner
        # sudo hdiutil detach /Volumes/Docker

        # Remove quarantine attribute
        sudo xattr -r -d com.apple.quarantine /Applications/Docker.app

        # Install privileged components
        /Applications/Docker.app/Contents/MacOS/Docker \
              --quit-after-install \
              --unattended \
              --install-privileged-components

        nohup /Applications/Docker.app/Contents/MacOS/Docker --unattended &

        echo "We are waiting for Docker to be up and running. It can take over 2 minutes..."
        while ! docker info ; do sleep 1; done

        # HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask docker
        # /Applications/Docker.app/Contents/MacOS/Docker --unattended --install-privileged-components
        # open -a /Applications/Docker.app --args --unattended --accept-license
        # echo "We are waiting for Docker to be up and running. It can take over 2 minutes..."
        # while ! /Applications/Docker.app/Contents/Resources/bin/docker info &>/dev/null; do sleep 1; done

        echo "docker.local: $(host docker.local)"

        echo "getting ip of the host"
        docker run --rm --net host alpine:latest ip addr
        ;;
    *)
        echo "Can't setup interfaces on non-Mac. Error!"
        exit 1
        ;;
esac

docker rm -f ping &>/dev/null || true
docker network rm hacktest &>/dev/null || true

docker network create hacktest

docker run -d --name ping --net=hacktest rboyer/pingpong

ping_ip="$(docker inspect ping | jq -r '.[0].NetworkSettings.Networks.hacktest.IPAddress')"

echo "PING IP: ${ping_ip}"

curl -sL "http://${ping_ip}:8080" | jq .
