#!/bin/bash

set -e

# Include mobile app vars.
. development.properties

if [ -z $1 ]; then
    echo "Error: We need an argument, android or ios"
    exit 1
fi

if [ "$1" != "android" -a "$1" != "ios" ]; then
    echo "Error: \$1 should be android or ios"
    exit 1
fi

# Grrrrr.
if [ "$1" == "ios" ]; then
    sedcmd="sed -i ''"
else
    sedcmd="sed -i"
fi

# I usually have problems with this...
npm prune ; npm cache clean

# Install project dependencies.
bower install
npm install
node node_modules/protractor/bin/webdriver-manager update

if [ ! -d "dist" ]; then
    mkdir -p dist/app
fi

if [ ! -d "public/shared-build" ]; then
    mkdir public/shared-build
fi

# Create cordova app and add dependencies.
cordova create dist/app "$PACKAGENAME.$1" "$appname"

# Build the project to populate public/shared-build and friends.
grunt build:dev

# App icons.
if [ ! -d "dist/app/res" ]; then
    mkdir -p dist/app/res
fi
ln icons/* dist/app/res

cd dist/app

# I'm tired of dealing with ios resources not reading the
# filter or picking the wrong icon.
if [ "$1" == "ios" ]; then
    ${sedcmd} 's#</widget>#\
    <icon src="res/icon-ios.png" />\
    <splash src="res/splash-portrait.png" width="320" height="480"/>\
    <splash src="res/splash-portrait.png" width="640" height="960"/>\
    <splash src="res/splash-portrait.png" width="768" height="1024"/>\
    <splash src="res/splash-portrait.png" width="1536" height="2048"/>\
    <splash src="res/splash-landscape.png" width="1024" height="768"/>\
    <splash src="res/splash-landscape.png" width="2048" height="1536"/>\
    <splash src="res/splash-portrait.png" width="640" height="1136"/>\
    <splash src="res/splash-portrait.png" width="750" height="1334"/>\
    <splash src="res/splash-portrait.png" width="1242" height="2208"/>\
    <splash src="res/splash-landscape.png" width="2208" height="1242"/>\
    <platform name="ios">\
        <preference name="EnableViewportScale" value="true"/>\
    </platform>\
    </widget>#' config.xml
else
    ${sedcmd} 's#</widget>#\
    <icon src="res/icon-android.png" />\
    <icon src="res/icon-android.png" density="ldpi" />\
    <icon src="res/icon-android.png" density="mdpi" />\
    <icon src="res/icon-android.png" density="hdpi" />\
    <icon src="res/icon-android.png" density="xhdpi" />\
    <splash src="res/splash-portrait.png" density="hdpi"/>\
    <splash src="res/splash-portrait.png" density="ldpi"/>\
    <splash src="res/splash-portrait.png" density="mdpi"/>\
    <splash src="res/splash-portrait.png" density="xhdpi"/>\
    <splash src="res/splash-landscape.png" density="land-hdpi"/>\
    <splash src="res/splash-landscape.png" density="land-ldpi"/>\
    <splash src="res/splash-landscape.png" density="land-mdpi"/>\
    <splash src="res/splash-landscape.png" density="land-xhdpi"/>\
    </widget>#' config.xml

fi
# Setting the app config.
# - Set minimum supported versions. Android API 16 (no PushPlugin GET_ACCOUNTS permission) & IOS 6.
# - No zoom
${sedcmd} 's#</widget>#\
    <preference name="android-minSdkVersion" value="16" />\
    <preference name="deployment-target" value="6.0" />\
    <preference name="Fullscreen" value="true" />\
</widget>#' config.xml

# Set description, author...
${sedcmd} "s#<author.*>#<author email=\"$AUTHOR_EMAIL\" href=\"$AUTHOR_WEBSITE\">#" config.xml
${sedcmd} "s#Apache Cordova Team#$AUTHOR_NAME#" config.xml
${sedcmd} "s#A sample Apache Cordova application that responds to the deviceready event.#$DESCRIPTION#" \
config.xml
${sedcmd} 's#<access.*>#\
    <access origin="'$BACKEND_URL'" />\
    <access origin="http://*.gravatar.com" />#\
    <access origin="https://*.gravatar.com" />#' config.xml

# Only the required platform.
cordova platform add "$1"

# Install all plugins.
while read -a plugin; do
    cordova plugin add ${plugin[1]}
done < ../../cordova-plugins.list
