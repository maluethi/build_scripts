######################### Setup the machine ###################################

# Get number of cores to use.

ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`
if [ $ncores -lt 1 ]; then
  ncores=1
fi
echo "Building using $ncores cores."

# Handling Ubuntu Builds
if [ `lsb_release -si` = "Ubuntu" ]; then
  OS="Ubuntu"
  OS_VERSION=`lsb_release -sr | cut -c 1-2`
  echo "Building for $OS $OS_VERSION"
  if [ -z ${LOCAL_PRODUCTS+x} ]; then
    echo "local larsoft product directory defined is not defined"
    exit 1
  fi
  echo "-H Linux64bit+3.19-2.19" > $LOCAL_PRODUCTS/ups_OVERRIDE.`hostname`
fi

# Local larsoft setup
echo "Using product directory $LOCAL_PRODUCTS"
source $LOCAL_PRODUCTS/setup || exit 1
source $LOCAL_PRODUCTS/setup_uboone.sh

# We use the machines git 

###############################################################################
