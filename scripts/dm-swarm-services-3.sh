#!/usr/bin/env bash

eval $(docker-machine env swarm-1)

docker network create --driver overlay proxy

docker network create --driver overlay go-demo

docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    --network proxy \
    --replicas 3 \
    -e MODE=swarm \
    vfarcic/docker-flow-proxy:1.96

docker service create --name swarm-listener \
    --network proxy \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e DF_NOTIFICATION_URL=http://proxy:8080/v1/docker-flow-proxy/reconfigure \
    vfarcic/docker-flow-swarm-listener

docker service create --name go-demo-db \
    --network go-demo \
    mongo:3.2.10

docker service create --name go-demo \
    -e DB=go-demo-db \
    --network go-demo \
    --network proxy \
    --replicas 3 \
    --label com.df.notify=true \
    --label com.df.distribute=true \
    --label com.df.servicePath=/demo \
    --label com.df.port=8080 \
    vfarcic/go-demo:1.2

echo ""
echo ">> The services scheduled and will be up-and-running soon"