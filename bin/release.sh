#!/bin/bash

set -e

if [ -z $1 ]; then
    echo "
HEY YOU! BEFORE RUNNING THIS AGAIN:
# This script is used to push to production. You don't probably need to use this.
# Ensure you pulled the latest changes from the repo
# Run all tests and ensure they are passing
# Clean the kitchen and commit everthing
# Copy or increase the version (look the current one in package.json and increment it).

Once done, run 'grunt release:X.Y.Z', where X.Y.Z is the version number.
"
    exit 1
fi

unamestr=`uname`
if [ "$unamestr" == "Darwin" ]; then
    sedcmd="sed -i ''"
else
    sedcmd="sed -i"
fi

git remote show | grep dokku > /dev/null || \
    (echo "Error: This script is used to push to production. If you don't have a dokku remote I doubt you should be running this." ; exit 1)

if [ ! -z $1 ]; then

    version=$1

    # Clean the points and leading zeros.
    versionCode=${version//.}
    versionCode=$(echo $versionCode | sed 's/^0*//')

    # Check the strings length.
    if [ "${#version}" -ne "5" ]; then
        echo "Error: Check version value. Should be something like 2.3.1"
        exit 1
    fi

    # Check that versionCode is an integer.
    if [[ ! $versionCode =~ ^-?[0-9]+$ ]]; then
        echo "Error: Check version value. Should be something like 3.4.5"
        exit 1
    fi
fi

if [ -z $version ]; then
    echo "Error: There is no version value"
    exit 1
fi

# These are bundled in the package.
${sedcmd} "s#version *: *'\(.*\)'#version: '$versionCode'#" config/frontend.js.dist
${sedcmd} "s#\"version\" *: *\"\(.*\)\"#\"version\": \"$version\"#" package.json
${sedcmd} "s#\"version\" *: *\"\(.*\)\"#\"version\": \"$version\"#" bower.json

# These two might not be there as they are generated.
if [ -f "config/frontend.js" ]; then
    ${sedcmd} "s#version *: *'\(.*\)'#version: '$versionCode'#" config/frontend.js
fi
if [ -f "dist/app/config.xml" ]; then
    ${sedcmd} "s#version=\"\(.*\)\" xmlns#version=\"$version\" android-versionCode=\"$versionCode\" xmlns#" dist/app/config.xml
fi

# If there are version changes commit them and create a new tag in the repo.
git commit package.json bower.json config/frontend.js.dist -m "Release $version" && \
git tag -a "v$version" -m "Release v$version" && \
git push origin "v$version"

# Push latest changes to the public server (NO -f HERE!).
git push origin master

# Push latest changes to backend server (NO -f HERE!).
git push dokku master

echo "
-------------------------------------------------------------------------------
DONE!
- Backend public server updated to v$version
- Version updated in package.json, bower.json, config/frontend.js (also in config/frontend.js.dist and dist/app/config.xml if required)
- Tag v$version released if it didn't exist before
- Public repo master HEAD updated
"
exit 0
