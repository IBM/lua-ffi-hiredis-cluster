#!/bin/sh
if [ $# != "1" ]
then
    echo "Usage: $0 <tag-name>"
    exit 1
fi

PACKAGE=lua-ffi-hiredis-cluster
TAG=$1
TARNAME="${PACKAGE}-${TAG}.tar"
TARGETDIR="/tmp"
mkdir -p ${TARGETDIR}
echo "Generating ${TARGETDIR}/${TARNAME}"
git archive $TAG --prefix ${PACKAGE}-${TAG}/ > ${TARGETDIR}/$TARNAME || exit 1
echo "Gizipping the archive"
rm -f ${TARGETDIR}/$TARNAME.gz
gzip -9 ${TARGETDIR}/$TARNAME
echo "Package is ready in ${TARGETDIR}/$TARNAME.gz"
MD5=$(md5sum ${TARGETDIR}/${PACKAGE}-${TAG}.tar.gz | cut -d ' ' -f4)

# In "builtin" mode, lua rocks installs whatever is under "lua" directory as the raw files in the rock.

ROCKSPEC=$(cat << EOF
package = "${PACKAGE}"
version = "${TAG}"
source = {
  url = "file://${TARGETDIR}/$TARNAME.gz",
  md5 = "${MD5}"
}

description = {
  summary = "Lua FFI binding for Hiredis-cluster library.",
  detailed = [[]],
  homepage = "",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  build_variables = {},
  install_variables = {},
  build = {},
  modules = {},
}
EOF
)

ROCKSPEC_FILE=${TARGETDIR}/${PACKAGE}-${TAG}.rockspec

rm -rf ${ROCKSPEC_FILE}

echo "${ROCKSPEC}" > ${ROCKSPEC_FILE}

chmod 444 ${ROCKSPEC_FILE}

echo "rockspec file is ready in ${ROCKSPEC_FILE}"

luarocks pack ${ROCKSPEC_FILE}

echo "Rock is ready in your current path."
