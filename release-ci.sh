#!/bin/bash

echo `git rev-parse --abbrev-ref HEAD`

#if [[ `git rev-parse --abbrev-ref HEAD` != "master" ]]; then
#    echo "not master branch, so skipping"
#    exit 0
#fi

set -e
set -o errexit
set -o pipefail
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LOCAL_VERSION=`jq -r .http4k.version $DIR/version.json`

BINTRAY_VERSION=`curl -s https://bintray.com/api/v1/packages/http4k/maven/http4k-core/versions/_latest | jq -r .name`

if [[ "$LOCAL_VERSION" == "$BINTRAY_VERSION" ]]; then
    echo "Version has not changed"
    exit 0
fi

echo "Attempting to release $LOCAL_VERSION (old version $BINTRAY_VERSION)"

./gradlew -PreleaseVersion=$LOCAL_VERSION clean javadocJar assemble

for i in $(find http4k* -maxdepth 0 -type d); do
    ./gradlew --stacktrace -PreleaseVersion=$LOCAL_VERSION :$i:bintrayUpload
done


function notify_slack {
    local MESSAGE=$1
    echo "Notifying on Slack..."
    curl -X POST -H 'Content-type: application/json' --data "{'text':'$MESSAGE'}" $SLACK_WEBHOOK
}

function notify_gitter {
    local MESSAGE=$1
    echo "Notifying on Gitter..."
    curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GITTER_BEARER_TOKEN" "$GITTER_WEBHOOK"  -d "{'text':'$MESSAGE'}"
}

if [ $? -ne 0 ]; then
    notify_slack "Release has failed. Check <https://travis-ci.org/http4k/http4k-core/builds/$TRAVIS_BUILD_ID|Build #$TRAVIS_BUILD_NUMBER> for details."
else
    notify_slack "Released version <https://bintray.com/http4k/maven/http4k-core/$LOCAL_VERSION|$LOCAL_VERSION> (See <https://github.com/http4k/http4k/blob/master/CHANGELOG.md#changelog|Changelog> for details)."
    notify_gitter "Released version <https://bintray.com/http4k/maven/http4k-core/$LOCAL_VERSION|$LOCAL_VERSION> (See <https://github.com/http4k/http4k/blob/master/CHANGELOG.md#changelog|Changelog> for details)."
fi
