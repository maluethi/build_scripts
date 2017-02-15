
if [ -z ${LOCAL_PRODUCTS+x} ]; then
  echo "local larsoft product directory defined is not defined"
  exit 1
fi

cd $LOCAL_PRODUCTS

# Check if all requirements of the machine are fulfilled
echo "Checking larsoft prerequisites"
curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/bundles/tools/checkPrerequisites || exit 1
chmod +x checkPrerequisites
./checkPrerequisites


# Download necessary larsoft version
echo "Checking / Installing necessary larsoft version"
curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/bundles/tools/pullProducts || exit 1
chmod +x pullProducts

LARSOFT_QUAL_MINUS=`echo ${LARSOFT_QUAL} |  sed -e 's/:/-/g'`
./pullProducts -r $LOCAL_PRODUCTS u14 larsoft-$UBOONE $LARSOFT_QUAL_MINUS prof || exit 1
./pullProducts -r $LOCAL_PRODUCTS u14 larsoft-$UBOONE $LARSOFT_QUAL_MINUS debug || exit 1

cd -
