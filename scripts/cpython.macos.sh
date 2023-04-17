#!/bin/bash

set -ex 

GIT_TAG=`git describe --tags --exact-match 2>/dev/null || true`

# macosx sdk
pushd /tmp 
rm -Rf MacOSX-SDKs 
git clone https://github.com/phracker/MacOSX-SDKs.git 1>/dev/null
export CMAKE_OSX_SYSROOT=$PWD/MacOSX-SDKs/MacOSX10.9.sdk
popd

# cmake
brew install swig cmake 
PYTHON=$(which python)
$PYTHON --version
$PYTHON -m pip install --upgrade pip

# compile
mkdir -p build 
cd build
cmake -GXcode -DCMAKE_OSX_SYSROOT=$CMAKE_OSX_SYSROOT -DPython_EXECUTABLE=${PYTHON} ../
cmake --build . --target ALL_BUILD --config Release --parallel 4
cmake --build . --target install   --config Release

# distrib
cd Release/pyplasm
rm -Rf ./dist
$PYTHON -m pip install setuptools wheel twine --upgrade 1>/dev/null || true
PYTHON_TAG=cp$(echo $PYTHON_VERSION | awk -F'.' '{print $1 $2}')
$PYTHON setup.py -q bdist_wheel --python-tag=${PYTHON_TAG} --plat-name=macosx_10_9_x86_64
if [[ "${GIT_TAG}" != "" ]] ; then
	$PYTHON -m twine upload --username ${PYPI_USERNAME} --password ${PYPI_TOKEN} --skip-existing   "dist/*.whl" 
fi

echo "All done"