####1. Build application containers
Input---->apllication  dockerfiles or docker compose files
Output---->application containers 
``` 
docker-compose up  -d
``` 
####2. Extract containers PID information 
Input---->containers names " 
Output---->containers PIDs" 
``` 
PID1=$(docker inspect --format '{{.State.Pid}}' dockernetflowalpine_wordpress_1)
PID2=$(docker inspect --format '{{.State.Pid}}' dockernetflowalpine_db_1)
``` 
####3. Generates user network namespaces for application containers 
Input----> app containers PIDs
Output---->user network namespace  for application containers" 
``` 
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/$PID1/ns/net /var/run/netns/ufrgscmp193_wordpress_1
sudo ln -sf /proc/$PID2/ns/net /var/run/netns/ufrgscmp192_db_1
``` 
####4. Creates an user network to isolate containers 
Input---->non
Output---->user isolate network 
```
docker network create netflow
```
####5. Build netflow collector image
Input----> collector Dockerfile
Output---->collector image 
``` 
docker build -t netflow_collector -f Dockerfile.collector .
``` 
####6. Run collector container (detach mode)
Input---->arg  host:container port, network, name and image
Output---->collector image
``` 
docker run -d -p 2055:2055 --network=netflow  --name containerc netflow_collector /bin/bash  
``` 
####7. Extract container collector  information
Input----> collector container name , IP address and probe interface 
Output---->fprobe cofiguration file - fprobe 
``` 
collectorIp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' containerc)
sed "s/INTERFACE=.*/INTERFACE=\"eth0\"/g"   fprobe > output && mv output fprobe
sed "s/FLOW_COLLECTOR=.*/FLOW_COLLECTOR=\"${collectorIp}:2055\"/g"   fprobe > output && mv output fprobe
``` 
####8. Generate user network namespace for collect container
Input----> collector container PID
Output---->collectro namespace 
``` 
PID5=$(docker inspect --format '{{.State.Pid}}' containerc)
sudo ln -sf /proc/$PID5/ns/net /var/run/netns/containerc
``` 
####9. Build Netflow data export probe image 
Input----> probe Dockerfile 
Output---->probe image 
``` 
docker build  -t netflow_data_export -f Dockerfile.dataExport .
``` 
####10. Run  probe containers (detach mode)
 Input----> probe container names, application containers PID 
Output---->probe containers 
``` 
docker run -e environment=$PID1 --rm -d -it  --privileged --pid=host --network=netflow --name containera  netflow_data_export /bin/bash
docker run -e environment=$PID2 --rm -d -it  --privileged --pid=host --network=netflow --name containerb  netflow_data_export /bin/bash
``` 
####11.  Generate user netwok container namespace
``` 
PID3=$(docker inspect --format '{{.State.Pid}}' containera)
PID4=$(docker inspect --format '{{.State.Pid}}' containerb)
PID5=$(docker inspect --format '{{.State.Pid}}' containerc)
sudo ln -sf /proc/$PID3/ns/net /var/run/netns/containera
sudo ln -sf /proc/$PID4/ns/net /var/run/netns/containerb
``` 
####12. Connect application containers to user network 
``` 
docker network connect netflow dockernetflow_wordpress_1
docker network connect netflow dockernetflow_db_1
``` 