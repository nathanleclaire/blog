#!/bin/bash

echo "stashing working directory changes..."
STASH_MSG=$(git stash)
for plugin in plugins/*; do
    echo "=> Trying out removing plugin ${plugin}..."

    # invalidate public diff so that failed generate will get caught
    echo "invalidate" >>public/index.html

    git rm ${plugin}
    ./build.sh 2>&1

    # remove XML timestamp stuff (not what we're interested in)
    find public -name *.xml | xargs -n 3 git checkout --

    DIFF=$(git diff)
    if [[ "$DIFF" != "" ]]; then
        echo "==> There was a difference after removing the plugin ${plugin}!"
        git reset HEAD ${plugin}
        git checkout -- ${plugin} public/
        exit 1
    fi
done
echo "restoring working directory changes..."
if [ "$STASH_MSG" != "No local changes to save" ]; then
    git stash pop >/dev/null
fi
