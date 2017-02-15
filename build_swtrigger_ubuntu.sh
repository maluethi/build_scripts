#!/bin/bash

#------------------------------------------------------------------
#
# Name: build_swtrigger_uboone.sh
#
# Purpose: Build debug and prof flavors of swtrigger on Jenkins 
#          on Ubuntu. Heaviliy based on build_swtrigger.sh
#
# Created:  15.February 2017  Matthias Luethi
#
# 
#------------------------------------------------------------------

echo "swtrigger version: $VERSION"
echo "qualifier: $QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"
echo "local larsoft products: $LOCAL_PRODUCTS"

# Setting up the local installation
source setup_machine.sh

# Other required setups.

setup cetbuildtools v5_04_02
if [ x$QUAL = xe9 ]; then
  setup gcc v4_9_3
elif [ x$QUAL = xe10 ]; then
  setup gcc v4_9_3a
else
  echo "Incorrect qualifier: $QUAL"
fi

# Set up working area.

set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
export SWTRIGGER_HOME_DIR=`pwd`

set +x

# Make source area and check out sources.

mkdir -p srcs
cd srcs
#git clone https://github.com/twongjirad/fememulator
git clone https://github.com/hgreenlee/fememulator
cd fememulator

# Make sure repository is up to date and check out desired tag.

git checkout master
git pull
git checkout $VERSION

# Do post-checkout initialization.

source configure.sh

# Run cmake.

mkdir build
cd build
cmake .. -DCMAKE_CXX_COMPILER=`which g++` -DCMAKE_BUILD_TYPE=$BUILDTYPE

# Run make

make -j$ncores

# Assemble ups product.

install_dir=${SWTRIGGER_HOME_DIR}/install/swtrigger/$VERSION
subdir=`get-directory-name subdir ${QUAL}:${BUILDTYPE}`
binary_dir=${install_dir}/$subdir
src_dir=${install_dir}/source
mkdir -p $binary_dir
mkdir -p $src_dir
cp -r lib $binary_dir
cp -r ${SWTRIGGER_HOME_DIR}/srcs/fememulator/SWTriggerBase $src_dir
cp -r ${SWTRIGGER_HOME_DIR}/srcs/fememulator/FEMBeamTrigger $src_dir
cp -r ${SWTRIGGER_HOME_DIR}/srcs/fememulator/ups $install_dir
mkdir ${SWTRIGGER_HOME_DIR}/install/.upsfiles

# Make a dbconfig file.

cat <<EOF > ${SWTRIGGER_HOME_DIR}/install/.upsfiles/dbconfig
FILE = DBCONFIG
AUTHORIZED_NODES = *
VERSION_SUBDIR = 1
PROD_DIR_PREFIX = \${UPS_THIS_DB}
UPD_USERCODE_DIR = \${UPS_THIS_DB}/.updfiles
EOF

# Declare ups product in temporary products area.

flavor=`ups flavor`
ups declare -z ${SWTRIGGER_HOME_DIR}/install -r swtrigger/$VERSION -m swtrigger.table -f $flavor -q ${QUAL}:${BUILDTYPE} -U ups swtrigger $VERSION

# Make distribution tarball

cd ${SWTRIGGER_HOME_DIR}/install
dot_version=`echo $VERSION | sed -e 's/_/\./g' | sed -e 's/^v//'`
subdir=`echo $subdir | sed -e 's/\./-/g'`
#qual=`echo $CETPKG_QUAL | sed -e 's/:/-/g'`
tarballname=swtrigger-${dot_version}-${subdir}.tar.bz2
echo "Making ${tarballname}"
tar cjf ${SWTRIGGER_HOME_DIR}/${tarballname} swtrigger

# install to local installation
echo "Installing swtrigger $VERSION to $LOCAL_PRODUCTS"
cp -r swtrigger $LOCAL_PRODUCTS

# Save artifacts.
mv ${SWTRIGGER_HOME_DIR}/${tarballname}  $WORKSPACE/copyBack/ || exit 1
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
#rm -rf $WORKSPACE/temp || exit 1
set +x

exit 0
