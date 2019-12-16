#!/bin/sh
docker-compose up  -d
docker build -t netflow_collector -f Dockerfile.collector .
docker build -t netflow_data_export -f Dockerfile.dataExport .

HOST_PORT=2055
docker run -d -p $HOST_PORT:2055 --network=dockernetflow_default --name containerc netflow_collector

collectorIp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' containerc)
probeInterface=eth0
collectorPort=2055

docker run  -e FLOW_COLLECTOR=$collectorIp -e INTERFACE=$probeInterface -e COLLECTOR_PORT=$collectorPort -d -it --network=container:dockernetflow_wordpress_1  --name containera  netflow_data_export /bin/bash
docker run  -e FLOW_COLLECTOR=$collectorIp -e INTERFACE=$probeInterface -e COLLECTOR_PORT=$collectorPort   -d -it --network=container:dockernetflow_db_1 --name containerb  netflow_data_export /bin/bash

