#### Comandos
```
docker-compose up  -d
PID1=$(docker inspect --format '{{.State.Pid}}' dockernetflow_wordpress_1)
PID2=$(docker inspect --format '{{.State.Pid}}' dockernetflow_db_1)
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/$PID1/ns/net /var/run/netns/dockernetflow_wordpress_1
sudo ln -sf /proc/$PID2/ns/net /var/run/netns/dockernetflow_db_1
docker network create netflow
docker build -t netflow_collector -f Dockerfile.collector .
docker run -d -p 2055:2055 --network=netflow  --name containerc netflow_collector
collectorIp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' containerc)
sed "s/INTERFACE=.*/INTERFACE=\"eth0\"/g"   fprobe > output && mv output fprobe
sed "s/FLOW_COLLECTOR=.*/FLOW_COLLECTOR=\"${collectorIp}:2055\"/g"   fprobe > output && mv output fprobe
PID5=$(docker inspect --format '{{.State.Pid}}' containerc)
sudo ln -sf /proc/$PID5/ns/net /var/run/netns/containerc
docker build  -t netflow_data_export -f Dockerfile.dataExport .
docker run -e environment=$PID1 --rm -d -it  --privileged --pid=host --network=netflow --name containera  netflow_data_export /bin/bash
docker run -e environment=$PID2 --rm -d -it  --privileged --pid=host --network=netflow --name containerb  netflow_data_export /bin/bash
PID3=$(docker inspect --format '{{.State.Pid}}' containera)
PID4=$(docker inspect --format '{{.State.Pid}}' containerb)
PID5=$(docker inspect --format '{{.State.Pid}}' containerc)
sudo ln -sf /proc/$PID3/ns/net /var/run/netns/containera
sudo ln -sf /proc/$PID4/ns/net /var/run/netns/containerb
docker network connect netflow dockernetflow_wordpress_1
docker network connect netflow dockernetflow_db_1
```
####Delete all
```
docker kill dockernetflow_wordpress_1  dockernetflow_db_1 containera containerb containerc
docker rm dockernetflow_wordpress_1  dockernetflow_db_1 containera containerb containerc -f
docker image rm netflow_collector netflow_data_export
docker network rm netflow
sudo ip netns ls
sudo ip netns del containera
sudo ip netns del containerb
sudo ip netns del containerc
sudo ip netns del dockernetflow_wordpress_1
sudo ip netns del dockernetflow_db_1
sudo ip netns ls
```
#####Armazenamento a cada 5min dos fluxos no host  - soh p/ teste
```
while true; do docker cp containerc:/var/cache/nfdump ~/Docker/dockerNetflow/nes; sleep 300; done &
```