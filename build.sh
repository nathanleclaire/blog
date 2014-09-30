#!/bin/bash

if [[ -d public ]]; then
    echo "removing public/ directory..."
    rm -rf public
fi

docker build -t nathanleclaire/octoblog .
docker run nathanleclaire/octoblog sh -c "rake install['pageburner'] && rake generate"
LAST_CONTAINER=$(docker ps -lq)
docker cp ${LAST_CONTAINER}:/blog/public .
docker rm ${LAST_CONTAINER}
