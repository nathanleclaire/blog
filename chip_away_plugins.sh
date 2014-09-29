#!/bin/bash

# Reset
Color_Off='\e[0m'       # Text Reset

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

echo "stashing working directory changes..."
STASH_MSG=$(git stash)
for plugin in plugins/*; do
    echo "${ICyan}=> Trying out removing plugin ${plugin}..."

    # invalidate public diff so that failed generate will get caught
    echo "invalidate" >>public/index.html

    git rm ${plugin}
    ./build.sh &>/dev/null

    # remove XML timestamp stuff (not what we're interested in)
    find public -name *.xml | xargs -n 3 git checkout --

    DIFF=$(git diff)
    if [[ "$DIFF" != "" ]]; then
        echo "${IRed}==> There was a difference after removing the plugin ${plugin}!"
        git reset HEAD ${plugin}
        git checkout -- ${plugin} public/
    else
        echo "${IGreen}Great success removing plugin!"
    fi
done
echo "restoring working directory changes..."
if [ "$STASH_MSG" != "No local changes to save" ]; then
    git stash pop >/dev/null
fi
