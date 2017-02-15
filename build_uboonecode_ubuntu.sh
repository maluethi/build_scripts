#!/bin/bash

#------------------------------------------------------------------
#
# Name: build_uboonecode_ubuntu.sh
#
# Purpose: Build debug and prof flavors of uboonecode on Jenkins 
#          on Ubuntu. Heaviliy based on buildUboone.sh. Not that
#          fancy, but works.
#
# Created:  15.February 2017  Matthias Luethi
#
# 
#------------------------------------------------------------------

echo "uboonecode version: $UBOONE"
echo "base qualifiers: $QUAL"
echo "larsoft qualifiers: $LARSOFT_QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

echo "local larsoft products: $LOCAL_PRODUCTS"

source $setup_ubuntu.sh || exit 1

setup mrb

setup gitflow || exit 1
export MRB_PROJECT=uboone
echo "Mrb path:"
which mrb

set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
mrb newDev  -v $UBOONE -q $QUAL:$BUILDTYPE || exit 1

set +x
source localProducts*/setup || exit 1

set -x
cd $MRB_SOURCE  || exit 1
# make sure we get a read-only copy
mrb g -r -t $UBOONE uboonecode || exit 1

# Extract ubutil version from uboonecode product_deps
ubutil_version=`grep ubutil $MRB_SOURCE/uboonecode/ups/product_deps | grep -v qualifier | awk '{print $2}'`

# extract uboone_data version from uboonecode product_deps
uboone_data_version=`grep uboone_data $MRB_SOURCE/uboonecode/ups/product_deps | grep -v qualifier | awk '{print $2}'`
uboone_data_dot_version=`echo ${uboone_data_version} | sed -e 's/_/./g' | sed -e 's/^v//'`
uboone_data_tar=uboone_data-${uboone_data_dot_version}-noarch.tar.bz2

cd $LOCAL_PRODUCTS
mkdir -p archive
cd archive

echo "Downloading uboone_data: $uboone_data_tar"
wget -nc http://scisoft.fnal.gov/scisoft/packages/uboone_data/$uboone_data_version/$uboone_data_tar || exit 1
tar -xf $uboone_data_tar -C $LOCAL_PRODUCTS --skip-old-files || exit 1

cd $MRB_SOURCE || exit 1

echo "ubuitil version: $ubutil_version"
mrb g -r -t $ubutil_version ubutil || exit 1

cd $MRB_BUILDDIR || exit 1
mrbsetenv || exit 1
mrb b -j$ncores || exit 1
if uname | grep -q Linux; then
  cp /usr/lib64/libXmu.so.6 uboonecode/lib
fi
mrb mp -n uboone -- -j$ncores || exit 1

# add uboone_data to the manifest

manifest=uboone-*_MANIFEST.txt
echo "uboone_data          ${uboone_data_version}       uboone_data-${uboone_data_dot_version}-noarch.tar.bz2" >>  $manifest

# add uboonedaq_datatypes to the manifest

manifest=uboone-*_MANIFEST.txt
uboonedaq_datatypes_version=`grep uboonedaq_datatypes $MRB_SOURCE/uboonecode/ups/product_deps | grep -v qualifier | awk '{print $2}'`
uboonedaq_datatypes_dot_version=`echo ${uboonedaq_datatypes_version} | sed -e 's/_/./g' | sed -e 's/^v//'`
os=`get-directory-name os`
plat=`get-directory-name platform`
qual=`echo $QUAL |  sed 's/:*noifdh:*//'`
if [ x$uboonedaq_datatypes_version != x ]; then
  echo "uboonedaq_datatypes          ${uboonedaq_datatypes_version}       uboonedaq_datatypes-${uboonedaq_datatypes_dot_version}-${os}-${plat}-${qual}-${BUILDTYPE}.tar.bz2" >>  $manifest
fi

# add swtrigger to the manifest

manifest=uboone-*_MANIFEST.txt
swtrigger_version=`grep swtrigger $MRB_SOURCE/uboonecode/ups/product_deps | grep -v qualifier | awk '{print $2}'`
swtrigger_dot_version=`echo ${swtrigger_version} | sed -e 's/_/./g' | sed -e 's/^v//'`
os=`get-directory-name os`
plat=`get-directory-name platform`
qual=`echo $QUAL |  sed 's/:*noifdh:*//'`
if [ x$swtrigger_version != x ]; then
  echo "swtrigger          ${swtrigger_version}       swtrigger-${swtrigger_dot_version}-${os}-${plat}-${qual}-${BUILDTYPE}.tar.bz2" >>  $manifest
fi

# Extract larsoft version from product_deps.

larsoft_version=`grep larsoft $MRB_SOURCE/uboonecode/ups/product_deps | grep -v qualifier | awk '{print $2}'`
larsoft_dot_version=`echo ${larsoft_version} |  sed -e 's/_/./g' | sed -e 's/^v//'`

# Extract flavor.

flvr=''
if uname | grep -q Darwin; then
  flvr=`ups flavor -2`
else
  flvr=`ups flavor`
fi

# Construct name of larsoft manifest.

larsoft_hyphen_qual=`echo $LARSOFT_QUAL | tr : - | sed 's/-noifdh//'`
larsoft_manifest=larsoft-${larsoft_dot_version}-${flvr}-${larsoft_hyphen_qual}-${BUILDTYPE}_MANIFEST.txt
echo "Larsoft manifest:"
echo $larsoft_manifest
echo

# Fetch laraoft manifest from scisoft and append to uboonecode manifest.

curl --fail --silent --location --insecure http://scisoft.fnal.gov/scisoft/bundles/larsoft/${larsoft_version}/manifest/${larsoft_manifest} >> $manifest || exit 1

# Special handling of noifdh builds goes here.

if echo $QUAL | grep -q noifdh; then

  else

    # Otherwise (for slf builds), delete the manifest entirely.

    rm -f $manifest

  fi
fi

# Save artifacts.

mv *.bz2  $WORKSPACE/copyBack/ || exit 1
manifest=uboone-*_MANIFEST.txt
if [ -f $manifest ]; then
  mv $manifest  $WORKSPACE/copyBack/ || exit 1
fi
cp $MRB_BUILDDIR/uboonecode/releaseDB/*.html $WORKSPACE/copyBack/
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1
set +x

# install uboonecode / ubutil
tar -xf $WORKSPACE/copyBack/uboonecode-* -C $LOCAL_PRODUCTS || exit 1
tar -xf $WORKSPACE/copyBack/ubutil-* -C $LOCAL_PRODUCTS || exit 1

exit 0
