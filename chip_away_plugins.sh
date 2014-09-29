#!/bin/bash

RESTORE='\033[0m'

RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
LIGHTGRAY='\033[00;37m'

echo "stashing working directory changes..."
STASH_MSG=$(git stash)

chip_away_at_plugins () {
    for plugin in plugins/*; do
        echo -e "|=> ${PURPLE}Trying out removing plugin ${plugin}...${RESTORE}"

        # invalidate public diff so that failed generate will get caught
        echo "invalidate" >>public/index.html

        printf "====> " && git rm ${plugin}
        ./build.sh &>/dev/null

        # remove XML timestamp stuff (not what we're interested in)
        find public -name *.xml | xargs -n 3 git checkout --

        DIFF=$(git diff)
        if [[ "$DIFF" != "" ]]; then
            echo -e "====> ${RED} There was a difference after removing the plugin ${plugin}!${RESTORE}"
            git reset HEAD ${plugin} >/dev/null
            git checkout -- ${plugin} public/ >/dev/null
        else
            echo -e "====> ${GREEN}Great success removing plugin ${plugin}!${RESTORE}"
        fi
    done
    echo "restoring working directory changes..."
    if [[ "$STASH_MSG" != "No local changes to save" ]]; then
        git stash pop >/dev/null
    fi
}

case "$1" in 
    apply)
        chip_away_at_plugins
        ;;
    rollback)
        git reset HEAD plugins/
        git checkout -- plugins
        ;;
    *)
        echo "Usage: $0 {apply|rollback}"
        exit 1
esac
