#!/bin/bash

# Parse version info in git tag, and overwrite version info in config.gradle
# Used for ci build and deploy

# Some examples on release tag format:
# + release-abc-0.2.3        will release 0.2.3abc
# + abc-0.2.3                will not trigger ci release
# + release-0.2.3            will not trigger ci release
# + release-fix-bug-0.35.2   will not trigger ci release  ("-"s are not allowed in classifier part)
# + release-fix_bug-0.35.2   will not trigger ci release (nor "_"s)
# + release-fixBug-0.35.2    will release 0.35.2fixBug
#   > please use camel cased classifier instead if you have to put multiple words here, which is not recommended
# + release-fixbug-0.34      will not trigger ci release, incomplete version number info

PATTERN='([a-zA-Z0-9]+)-([0-9]+)\.([0-9]+)\.([0-9]+)'
TAG=`echo ${CIRCLE_TAG} | grep -Eo $PATTERN`
echo "git tag: $TAG"

if [[ ! -z "$TAG" ]]; then
    VERSION_MAJOR=`echo $TAG | sed -E "s/$PATTERN/\2/"`
    VERSION_MINOR=`echo $TAG | sed -E "s/$PATTERN/\3/"`
    VERSION_PATCH=`echo $TAG | sed -E "s/$PATTERN/\4/"`
    VERSION_CLASS=`echo $TAG | sed -E "s/$PATTERN/\1/"`
else
    VERSION_MAJOR=''
    VERSION_MINOR=''
    VERSION_PATCH=''
    VERSION_CLASS=''
fi

if [[ ! -z "$VERSION_MAJOR" ]]; then
    echo "Overwriting to version $VERSION_MAJOR.$VERSION_MINOR.$VERSION_PATCH""$VERSION_CLASS"
    sed -i -E "s/versionMajor *= *.+/versionMajor = $VERSION_MAJOR/" .build/config.gradle
    sed -i -E "s/versionMinor *= *.+/versionMinor = $VERSION_MINOR/" .build/config.gradle
    sed -i -E "s/versionPatch *= *.+/versionPatch = $VERSION_PATCH/" .build/config.gradle
    sed -i -E "s/versionClassifier *= *.+/versionClassifier = \"$VERSION_CLASS\"/" .build/config.gradle
    echo "$VERSION_MAJOR.$VERSION_MINOR.$VERSION_PATCH$VERSION_CLASS" > VERSION
else
    echo "Skip overwriting as formatted tag not found"
fi

