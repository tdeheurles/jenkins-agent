#!/usr/bin/env bash

# import names
. ./build/release.cfg
artifact_name="gcr.io/$projectid/$servicename"
artifact_version="$servicemajor.$serviceminor.$BUILD_NUMBER"

# Build
docker build -t $artifact_name ./build/
docker tag $artifact_name $artifact_name:$artifact_version

# Push to Google Cloud Engine
gcloud preview docker push $artifactname_build
gcloud preview docker push $artifactname_latest
