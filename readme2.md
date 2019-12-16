### 
#### 1. Build and Run application
``` 
docker-compose up  -d
``` 
#### 2. Generates collector image
```
 docker build -t netflow_collector -f Dockerfile.collector .
```
#### 3. Run collector image 
```
docker run -d -p 2055:2055 --name containerc netflow_collector
```

#### 4. Collect collector IP 
```
collectorIp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' containerc)
```
##### Generates Data Export containers

#### 5. Build probes Image
```
docker build  --build-arg collectorIpArg=collectorIp  -t netflow_data_export -f Dockerfile.dataExport . 
```
##### Generates probes taking PID of application
#### 6. Netflow Data Export 1: Wordpress probe
```
docker run --rm -it -d --privileged --pid="container:dockernetflow_wordpress_1"   --name containera  netflow_data_export  \bin\bash
``` 
#### 7. Netflow Data Export 1: MySql (db) probe
```
docker run --rm -it -d --privileged --pid="container:dockernetflow_db_1"   --name containerb  netflow_data_export  \bin\bash
``` 
#### 8. Trasnfering Netflow data to an output folder
``` 
while true; do docker cp containerc:/var/cache/nfdump ~/Docker/dockerNetflow/nes; sleep 300; done &
``` 
### ALL COMMANDS
```
docker-compose up  -d
docker build -t netflow_collector -f Dockerfile.collector .
docker run -d -p 2055:2055 --name containerc netflow_collector
collectorIp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' containerc)
docker build  --build-arg collectorIpArg=collectorIp  -t netflow_data_export -f Dockerfile.dataExport . 
docker run  -it -d --privileged --pid="container:dockernetflow_wordpress_1" --network=container:dockernetflow_wordpress_1  --name containera  netflow_data_export  \bin\bash
docker run -it -d --privileged --pid="container:dockernetflow_db_1" --network=container:dockernetflow_db_1  --name containerb  netflow_data_export  \bin\bash
```

##sem o compartilhamento de rede
```
docker-compose up  -d
docker build -t netflow_collector -f Dockerfile.collector .
docker run -d -p 2055:2055 --name containerc netflow_collector
collectorIp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' containerc)
docker build  --build-arg collectorIpArg=collectorIp  -t netflow_data_export -f Dockerfile.dataExport . 
docker run --rm  -it -d --privileged --pid="container:dockernetflow_wordpress_1"  --name containera  netflow_data_export  \bin\bash
docker run --rm -it -d --privileged --pid="container:dockernetflow_db_1" --name containerb  netflow_data_export  \bin\bash
```


#### Netflow  traffic output folder
``` 
while true; do docker cp containerc:/var/cache/nfdump ~/Docker/dockerNetflow/nes; sleep 300; done &
``` 

#### DELETING containers and Images

##### Kill containers
```
docker kill dockernetflow_wordpress_1  dockernetflow_db_1 containera containerb containerc
```
##### Remove containers
```
docker rm dockernetflow_wordpress_1  dockernetflow_db_1 containera containerb containerc -f
```
##### Remove images
```
docker image rm netflow_collector netflow_data_export
```

#### DELETING ALL 

```
docker kill dockernetflow_wordpress_1  dockernetflow_db_1 containera containerb containerc
docker rm dockernetflow_wordpress_1  dockernetflow_db_1 containera containerb containerc -f
docker image rm netflow_collector netflow_data_export
```


#### Dockerfile.dataExport
```
#ARG variavel
# especifica a imagem do ubuntu de base 
FROM ubuntu:latest
#declara uma variavel que vai vir do prompt
ARG collectorIpArg="default Value"
# instala ferramentas
# apt-utils (para o apt-get)  para iputils (para o ping) net-tolls (para ping)

ENV COLLECTOR_IP=${collectorIpArg}

RUN apt-get update && apt-get install -y \
    apt-utils \
    iputils-ping \
    net-tools \
    fprobe
# apaga arquivo de config. do coletor
RUN rm -f /etc/default/fprobe
# substitui arquivo de config. do coletor pelo predefinido fprobe ~/netflow/fprobe
COPY fprobe /etc/default/
#entrypoint
ENTRYPOINT service fprobe start && /bin/bash
#RUN nsenter -t ${variavel} -n service fprobe start &&  tail -F /var/log/fprobe/*.log
#CMD fprobe -ieth0 172.17.0.2:2055  
#172.17.0.2:2055
```
#### Dockerfile.colllector
```
# base image is ubuntu latest version
FROM ubuntu:latest
# install nfdump and some tools: apt-utils for  apt-get,  iputils for ifconfig,  net-tools for ping
RUN apt-get update && apt-get install -y \
    apt-utils \
    iputils-ping \
    net-tools \
    nfdump
# expose port
EXPOSE 2055
#
ENTRYPOINT ["/usr/bin/nfcapd","-l","/var/cache/nfdump","-p","2055"]
```
#### Namespaces and PIDs
```
PID1=$(docker inspect --format '{{.State.Pid}}' dockernetflow_wordpress_1)
PID2=$(docker inspect --format '{{.State.Pid}}' dockernetflow_db_1)
PID3=$(docker inspect --format '{{.State.Pid}}' containera)
PID4=$(docker inspect --format '{{.State.Pid}}' containerb)
PID5=$(docker inspect --format '{{.State.Pid}}' containerc)
:
```
##### All namespaces
```
sudo ls /proc/$PID1/ns -la
sudo ls /proc/$PID2/ns -la
sudo ls /proc/$PID3/ns -la
sudo ls /proc/$PID4/ns -la
sudo ls /proc/$PID5/ns -la
```

##### All interfaces
```
sudo nsenter -t $PID1 -n ip a
sudo nsenter -t $PID2 -n ip a
sudo nsenter -t $PID3 -n ip a
sudo nsenter -t $PID4 -n ip a
sudo nsenter -t $PID5 -n ip a
```
#### salvar com o nhup
```
nohup bash -c 'while true; do docker cp containerc:/var/cache/nfdump ~/Docker/dockerNetflow/nes; sleep 20; done' < /dev/null &
```
#### passar dado para um arquivo

```
 docker inspect -f '{{range .NetworkSettings.Networks}}{{.MacAddress}}{{end}}' containera > file.txt
```
#### acessar a pasta do nfdump do coletor
```
docker exec --privileged containerc nfdump -o line -R /var/cache/nfdump
```
#### acessar a pasta de saida de resultado do host
```
nfdump -o line -R ~/Docker/dockerNetflow/nes/nfdump
```
#### First, you’d create the veth pair:
```
ip link add veth0 type veth peer name veth1
```





####Creating and Listing Network Namespaces
Creating a network namespace is actually quite easy. Just use this command:
```
ip netns add <new namespace name>
```
For example, let’s say you wanted to create a namespace called “blue”. You’d use this command:

ip netns add blue
To verify that the network namespace has been created, use this command:
```
ip netns list
```
You should see your network namespace listed there, ready for you to use.

#### Assigning Interfaces to Network Namespaces
Creating the network namespace is only the beginning; the next part is to assign interfaces to the namespaces, and then configure those interfaces for network connectivity. One thing that threw me off early in my exploration of network namespaces was that you couldn’t assign physical interfaces to a namespace (see the update at the bottom of this post). How in the world were you supposed to use them, then?

It turns out you can only assign virtual Ethernet (veth) interfaces to a network namespace (incorrect; see the update at the end of this post). Virtual Ethernet interfaces are an interesting construct; they always come in pairs, and they are connected like a tube—whatever comes in one veth interface will come out the other peer veth interface. As a result, you can use veth interfaces to connect a network namespace to the outside world via the “default” or “global” namespace where physical interfaces exist.

Let’s see how that’s done. First, you’d create the veth pair:
```
ip link add veth0 type veth peer name veth1
```
I found a few sites that repeated this command to create veth1 and link it to veth0, but my tests showed that both interfaces were created and linked automatically using this command listed above. Naturally, you could substitute other names for veth0 and veth1, if you wanted.

You can verify that the veth pair was created using this command:
```
ip link list
```
You should see a pair of veth interfaces (using the names you assigned in the command above) listed there. Right now, they both belong to the “default” or “global” namespace, along with the physical interfaces.

Let’s say that you want to connect the global namespace to the blue namespace. To do that, you’ll need to move one of the veth interfaces to the blue namespace using this command:
```
ip link set veth1 netns blue
```
If you then run the ip link list command again, you’ll see that the veth1 interface has disappeared from the list. It’s now in the blue namespace, so to see it you’d need to run this command:
```
ip netns exec blue ip link list
```
Whoa! That’s a bit of a complicated command. Let’s break it down:

The first part, ip netns exec, is how you execute commands in a different network namespace.

Next is the specific namespace in which the command should be run (in this case, the blue namespace).

Finally, you have the actual command to be executed in the remote namespace. In this case, you want to see the interfaces in the blue namespace, so you run ip link list.

When you run that command, you should see a loopback interface and the veth1 interface you moved over earlier.

####Configuring Interfaces in Network Namespaces
Now that veth1 has been moved to the blue namespace, we need to actually configure that interface. Once again, we’ll use the ip netns exec command, this time to configure the veth1 interface in the blue namespace:
```
ip netns exec blue ifconfig veth1 10.1.1.1/24 up
```
As before, the format this command follows is:
```
ip netns exec <network namespace> <command to run against that namespace>
```
In this case, you’re using ifconfig to assign an IP address to the veth1 interface and bring that interface up. (Note: you could use the ip addr, ip route, and ip link commands to accomplish the same thing.)

Once the veth1 interface is up, you can verify that the network configuration of the blue namespace is completely separate by just using a few different commands. For example, let’s assume that your “global” namespace has physical interfaces in the 172.16.1.0/24 range, and your veth1 interface is in a separate namespace and assigned something from the 10.1.1.0/24 range. You could verify how network namespaces keep the network configuration separate using these commands:

ip addr list in the global namespace will not show any 10.1.1.0/24-related interfaces or addresses.

ip netns exec blue ip addr list will show only the 10.1.1.0/24-related interfaces and addresses, and will not show any interfaces or addresses from the global namespace.

Similarly, ip route list in each namespace will show different routing table entries, including different default gateways.

Connecting Network Namespaces to the Physical Network
This part of it threw me for a while. I can’t really explain why, but it did. Once I’d figured it out, it was obvious. To connect a network namespace to the physical network, just use a bridge. In my case, I used an Open vSwitch (OVS) bridge, but a standard Linux bridge would work as well. Place one or more physical interfaces as well as one of the veth interfaces in the bridge, and—bam!—there you go. Naturally, if you had different namespaces, you’d probably want/need to connect them to different physical networks or different VLANs on the physical network.

So there you go—an introduction to Linux network namespaces. It’s quite likely I’ll build on this content later, so while it seems a bit obscure right now just hang on to this knowledge. In the meantime, if you have questions, clarifications, or other information worth sharing with other readers, please feel free to speak up in the comments.

UPDATE: As I discovered after publishing this post, it most certainly is possible to assign various types of network interfaces to network namespaces, including physical interfaces. (I’m not sure why I ran into problems when I first wrote this post.) In any case, to assign a physical interface to a network namespace, you’d use this command:
```
ip link set dev <device> netns <namespace>
```


####consultar ip
```
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' containera
``` 






#####
``` 
PID1 = "$(docker inspect -f '{{.State.Pid}}'containera")"