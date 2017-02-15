export LOCAL_PRODUCTS=/home/build/products
export WORKSPACE=/home/build/workspace_datatypes

export BUILD_SCRIPTS=$WORKSPACE/build_scripts
export VERSION="v6_19_01_e10"

#mimic git clone on jenkins:
cp -r  ~/build_scripts $WORKSPACE/
