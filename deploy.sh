#!/bin/sh

. ./.secrets
rm -rf public/
hugo
aws s3 sync --delete public/ s3://nathanleclaire.com --region us-west-1
