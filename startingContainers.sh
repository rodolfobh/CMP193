#!/bin/sh

docker build -t aqualtune/netflow_collector -f Dockerfile.collector .
docker build -t aqualtune/netflow_data_export -f Dockerfile.dataExport .
docker run -d -p 2055:2055 --name containerc aqualtune/netflow_collector
docker run -it -d --name containera aqualtune/netflow_data_export /bin/bash
docker run -it -d --name containerb aqualtune/netflow_data_export /bin/bash
docker exec -d containerb ping 172.17.0.3
docker exec -d containera ping 172.17.0.4
