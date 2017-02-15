#!/bin/bash

#------------------------------------------------------------------
#
# Name: build_uboonedaq_datatypes_ubuntu.sh
#
# Purpose: Build debug and prof flavors of uboonedaq_datatypes
#          on Jenkins and ubuntu.
#
# Created:  15.February 2017  Matthias Luethi
#
#------------------------------------------------------------------

echo "uboonedaq_datatypes version: $VERSION"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

echo "local larsoft products: $LOCAL_PRODUCTS"

source $BUILD_SCRIPTS/setup_ubuntu.sh || exit 1


# Interpret build type.

opt=''
if [ $BUILDTYPE = debug ]; then
  opt='-d'
elif [ $BUILDTYPE = prof ]; then
  opt='-p'
else
  echo "Unknown build type $BUILDTYPE"
  exit 1
fi


# Set up working area.

set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
export UBOONEDAQ_HOME_DIR=`pwd`

set +x

# Make build area.

mkdir -p build

# Make install area.

mkdir -p install

# Make source area and check out sources.

mkdir -p srcs
cd srcs
git clone http://cdcvs.fnal.gov/projects/uboonedaq-datatypes
cd uboonedaq-datatypes

# Make sure repository is up to date and check out desired tag.

git checkout master
git pull
git checkout $VERSION

# Initialize build area.

cd ${UBOONEDAQ_HOME_DIR}/build
source ${UBOONEDAQ_HOME_DIR}/srcs/uboonedaq-datatypes/projects/ups/setup_for_development $opt

# Run cmake.

env CC=gcc CXX=g++ FC=gfortran cmake -DCMAKE_INSTALL_PREFIX="${UBOONEDAQ_HOME_DIR}/install" -DCMAKE_BUILD_TYPE=${CETPKG_TYPE} "${CETPKG_SOURCE}"

# Run make

make -j$ncores
make install

# Make distribution tarball

cd ${UBOONEDAQ_HOME_DIR}/install
dot_version=`echo $VERSION | sed -e 's/_/\./g' | sed -e 's/^v//'`
subdir=`echo $CET_SUBDIR | sed -e 's/\./-/g'`
qual=`echo $CETPKG_QUAL | sed -e 's/:/-/g'`
tarballname=uboonedaq_datatypes-${dot_version}-${subdir}-${qual}.tar.bz2
echo "Making ${tarballname}"
tar cjf ${UBOONEDAQ_HOME_DIR}/${tarballname} uboonedaq_datatypes

# install to local installation
echo "Installing swtrigger $VERSION to $LOCAL_PRODUCTS"
cp -r uboonedaq_datatypes $LOCAL_PRODUCTS

# Save artifacts.

mv ${UBOONEDAQ_HOME_DIR}/${tarballname}  $WORKSPACE/copyBack/ || exit 1
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1
set +x

exit 0
