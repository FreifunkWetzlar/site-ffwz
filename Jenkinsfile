#!/bin/sh
#
###############################################################################################
#
# Buildscript zur Erstellung der Images
# 
###############################################################################################
# Based on https://github.com/FreiFunkMuenster/site-ffms/blob/master/build-jenkins.sh
###############################################################################################

set -e

# Load local build config
test -f build.conf && . build.conf || (echo "Build config build.conf missing."; exit 1)

# Default config
export GLUON_URL=${GLUON_URL:-"https://github.com/freifunk-gluon/gluon.git"}
export GLUON_COMMIT=${GLUON_COMMIT:-"master"}
export SITE_VERSION=${SITE_VERSION:-`date '+%Y%m%d'`}
export SITE_MANIFEST=${SITE_MANIFEST:-""}
export SITE_DIR=${SITE_DIR:-`pwd`}
export WORKSPACE=${WORKSPACE:-`pwd`}

# Compute more vars
export GLUON_RELEASE=$SITE_VERSION
export GLUON_DIR="$WORKSPACE/gluon-$GLUON_COMMIT"

echo "Building ($SITE_BRANCH): $GLUON_RELEASE"
echo "- Gluon: $GLUON_COMMIT"
echo "- Workspace: $GLUON_DIR"
echo

# Create gluon build directory (based on gluon version so builds are cached
#                               but do not clash with each other)
test -d "$GLUON_DIR" || git clone "$GLUON_URL" "$GLUON_DIR"
cd "$GLUON_DIR"
git fetch 
git checkout -f $GLUON_COMMIT

# Copy site config to gluon build directory
test -d "$GLUON_DIR/site" && rm -rf "$GLUON_DIR/site"
mkdir "$GLUON_DIR/site"
cp "$SITE_DIR/site.conf" "$GLUON_DIR/site/"
cp "$SITE_DIR/site.mk" "$GLUON_DIR/site/"

# Update gluon, than build site 
cd "$GLUON_DIR"
make update
make clean
make -j8 V=s "GLUON_RELEASE=$GLUON_RELEASE"

if [[ -n "$SITE_MANIFEST" ]]; then
    # Sign build
    cd "$GLUON_DIR"
    make manifest "GLUON_RELEASE=$GLUON_RELEASE" GLUON_BRANCH=$SITE_MANIFEST
    sh contrib/sign.sh "$JENKINS_HOME/secret" "images/sysupgrade/$SITE_MANIFEST.manifest"
fi

cp -vau images ..
