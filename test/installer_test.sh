#!/bin/bash -eu 
set -o pipefail

CONTAINER_ID=$(docker run --publish 80:80 --detach myfavoritethings-test)
echo "Testcontainer running with id $CONTAINER_ID"

sleep 5

echo "Killing testcontainer $CONTAINER_ID"
docker rm -f $CONTAINER_ID
