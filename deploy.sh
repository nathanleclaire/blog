#!/bin/bash

rm -rf public/
hugo
aws s3 sync public/ s3://nathanleclaire.com --region us-west-1
