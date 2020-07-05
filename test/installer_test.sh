#!/bin/bash -u 
set -o pipefail

function is_healty {
    local container_id=$1
    test $(docker inspect --format='{{json .State.Health.Status}}' $container_id) = "\"healthy\""
}

function block_until_available {
    local container_id=$1
    printf "Waiting for testcontainer to become healthy"
    while ! is_healty $CONTAINER_ID; do
        printf "."
        sleep 1
    done
    printf "\n"
}

# CONTAINER_ID=$(docker run --publish 80:80 --detach --rm myfavoritethings-test)
CONTAINER_ID=$(docker run \
    --publish 80:80 \
    --detach \
    --rm \
    myfavoritethings-test)
echo "Testcontainer running with id $CONTAINER_ID"
block_until_available $CONTAINER_ID

docker exec $CONTAINER_ID curl -f localhost/cgi-bin/MyFavoriteThings/cgi/install.cgi
if [ $? -ne 0 ]; then
    docker logs $CONTAINER_ID
fi

echo "Killing testcontainer $CONTAINER_ID"
docker rm -f $CONTAINER_ID
