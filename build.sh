#!/bin/bash

docker build -t nathanleclaire/octoblog .
if [[ -d public ]]; then
    rm -rf public
fi

# extreme hack to get exit code
docker run nathanleclaire/octoblog sh -c "rake install['pageburner'] && rake generate"
LAST_CONTAINER=$(docker ps -lq)
docker cp ${LAST_CONTAINER}:/blog/public .
docker rm ${LAST_CONTAINER}
