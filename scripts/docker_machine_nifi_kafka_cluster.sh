# ################ #
# size the cluster #
# ################ #

# Define the number of managers/workers
MANAGER=1
WORKER=2


# ######################## #
# create the cluster hosts #
# ######################## #

# Create the Docker hosts
### for i in $(seq 1 $MANAGER); do docker-machine create --driver virtualbox manager$i; done
### for i in $(seq 1 $WORKER); do docker-machine create --driver virtualbox worker$i; done


# ##################################### #
# create the swarm on the cluster hosts #
# ##################################### #

# Init the swarm
docker-machine ssh manager1 docker swarm init --advertise-addr $(docker-machine ip manager1):2377 --listen-addr $(docker-machine ip manager1):2377

# docker-machine ssh manager1 docker swarm init --advertise-addr eth0 --listen-addr eth0

# Get the swarm manager join token
MANAGER_JOIN_TOKEN=$(docker-machine ssh manager1 docker swarm join-token manager -q)

# Get the swarm worker join token
WORKER_JOIN_TOKEN=$(docker-machine ssh manager1 docker swarm join-token worker -q)

# Add additional swarm manager(s)
#for i in $(seq 2 $MANAGER); do docker-machine ssh manager$i docker swarm join --manager --listen-addr $(docker-machine ip manager$i):2377 $(docker-machine ip manager1):2377; done

# Add swarm workers
# for i in $(seq 1 $WORKER); do docker-machine ssh worker$i docker swarm join --listen-addr $(docker-machine ip worker$i):2377 $(docker-machine ip manager1):2377; done
for i in $(seq 1 $WORKER); do docker-machine ssh worker$i docker swarm join --token $WORKER_JOIN_TOKEN $(docker-machine ip manager1):2377; done
							  

# ############################### #
# create the network on the swarm #
# ############################### #

# Create the overlay network
docker-machine ssh manager1 docker network create --driver overlay --subnet 10.1.0.0/24 kafkanet


# ################################ #
# create the services on the swarm #
# ################################ #

# Create the zookeeper service
### docker-machine ssh manager1 docker service create --name zk --publish 2181:2181 --network kafkanet jplock/zookeeper

# Create the kafka service
### docker-machine ssh manager1 docker service create --name kafka --publish 9092:9092 --publish 7203:7203 --env KAFKA_ADVERTISED_HOST_NAME=kafka --env ZOOKEEPER_IP=zk --network kafkanet ches/kafka

# Create the nifi service
### docker-machine ssh manager1 docker service create --name nifi --publish 8080:8080 --publish 8081:8081 --network ingress --network kafkanet mkobit/nifi

# ########################################## #
# create the clustered services on the swarm #
# ########################################## #

# Create the zookeeper cluster services
docker-machine ssh manager1 "docker service create --name zoo1 --publish 2182:2181 --env ZOO_MY_ID=1 --env ZOO_SERVERS='server.1=0.0.0.0:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888' --network kafkanet obees/zookeeper"
docker-machine ssh manager1 "docker service create --name zoo2 --publish 2183:2181 --env ZOO_MY_ID=2 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=0.0.0.0:2888:3888 server.3=zoo3:2888:3888' --network kafkanet obees/zookeeper"
docker-machine ssh manager1 "docker service create --name zoo3 --publish 2184:2181 --env ZOO_MY_ID=3 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=0.0.0.0:2888:3888' --network kafkanet obees/zookeeper"

#docker-machine ssh manager1 "docker service create --name zoo1 --publish 2181:2181 --env ZOO_MY_ID=1 --env ZOO_SERVERS='server.1=0.0.0.0:2888:3888' --env ZOO_PORT=2181 --network kafkanet obees/zookeeper"

# Create the kafka cluster  service
docker-machine ssh manager1 "docker service create --name kafka0 --publish 9092:9092 --env KAFKA_BROKER_ID=0 --env KAFKA_PORT=9092 --env KAFKA_ADVERTISED_HOST_NAME=kafka0 --env KAFKA_ADVERTISED_PORT=9092 --env ZOOKEEPER_CONNECTION_STRING='zoo1:2181,zoo2:2181,zoo3:2181' --network kafkanet ches/kafka"
docker-machine ssh manager1 "docker service create --name kafka1 --publish 9093:9093 --env KAFKA_BROKER_ID=1 --env KAFKA_PORT=9093 --env KAFKA_ADVERTISED_HOST_NAME=kafka1 --env KAFKA_ADVERTISED_PORT=9093 --env ZOOKEEPER_CONNECTION_STRING='zoo1:2181,zoo2:2181,zoo3:2181' --network kafkanet ches/kafka"
docker-machine ssh manager1 "docker service create --name kafka2 --publish 9094:9094 --env KAFKA_BROKER_ID=2 --env KAFKA_PORT=9094 --env KAFKA_ADVERTISED_HOST_NAME=kafka2 --env KAFKA_ADVERTISED_PORT=9094 --env ZOOKEEPER_CONNECTION_STRING='zoo1:2181,zoo2:2181,zoo3:2181' --network kafkanet ches/kafka"

# Create the nifi cluster service

### docker-machine ssh manager1 docker service create --name nifi --publish 8080:8080 --publish 8081:8081 --network ingress --network kafkanet mkobit/nifi

#docker-machine ssh manager1 "docker service create --name kafka0 --publish 9092:9092 --env KAFKA_BROKER_ID=0 --env KAFKA_PORT=9092 --env KAFKA_ADVERTISED_HOST_NAME=kafka0 --env KAFKA_ADVERTISED_PORT=9092 --env ZOOKEEPER_CONNECTION_STRING='zoo1:2181,zoo2:2181,zoo3:2181' --network kafkanet obees/kafka:0.5"
#docker-machine ssh manager1 "docker service create --name kafka1 --publish 9093:9093 --env KAFKA_BROKER_ID=1 --env KAFKA_PORT=9093 --env KAFKA_ADVERTISED_HOST_NAME=kafka1 --env KAFKA_ADVERTISED_PORT=9093 --env ZOOKEEPER_CONNECTION_STRING='zoo1:2181,zoo2:2181,zoo3:2181' --network kafkanet obees/kafka:0.5"
#docker-machine ssh manager1 "docker service create --name kafka2 --publish 9094:9094 --env KAFKA_BROKER_ID=2 --env KAFKA_PORT=9094 --env KAFKA_ADVERTISED_HOST_NAME=kafka2 --env KAFKA_ADVERTISED_PORT=9094 --env ZOOKEEPER_CONNECTION_STRING='zoo1:2181,zoo2:2181,zoo3:2181' --network kafkanet obees/kafka:0.5"



#docker-machine ssh manager1 "docker service create --name kafka1 --publish 9093:9092 --env KAFKA_BROKER_ID=0 --env KAFKA_ADVERTISED_HOST_NAME=kafka1 --env KAFKA_ADVERTISED_PORT=9092 --env ZOOKEEPER_CONNECTION_STRING='zoo1:2181,zoo2:2181,zoo3:2181' --network kafkanet ches/kafka"
#docker-machine ssh manager1 "docker service create --name kafka2 --publish 9094:9092 --env KAFKA_BROKER_ID=1 --env KAFKA_ADVERTISED_HOST_NAME=kafka2 --env KAFKA_ADVERTISED_PORT=9092 --env ZOOKEEPER_CONNECTION_STRING='zoo1:2181,zoo2:2181,zoo3:2181' --network kafkanet ches/kafka"
#docker-machine ssh manager1 "docker service create --name kafka3 --publish 9095:9092 --env KAFKA_BROKER_ID=2 --env KAFKA_ADVERTISED_HOST_NAME=kafka3 --env KAFKA_ADVERTISED_PORT=9092 --env ZOOKEEPER_CONNECTION_STRING='zoo1:2181,zoo2:2181,zoo3:2181' --network kafkanet ches/kafka"


# Create the nifi service


# ################################ #
# tests avec 31z4/zookeeper     #
# ################################ #

# Create the zookeeper service 1 for cluster
### docker-machine ssh manager1 "docker service create --name zoo1 --publish 2184:2181 --env ZOO_PORT=2181 --env ZOO_MY_ID=1 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2889:3889 server.3=zoo3:2890:3890' --network kafkanet 31z4/zookeeper"
### docker-machine ssh manager1 "docker service create --name zoo2 --publish 2185:2182 --env ZOO_PORT=2182 --env ZOO_MY_ID=2 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2889:3889 server.3=zoo3:2890:3890' --network kafkanet 31z4/zookeeper"
### docker-machine ssh manager1 "docker service create --name zoo3 --publish 2186:2183 --env ZOO_PORT=2183 --env ZOO_MY_ID=3 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2889:3889 server.3=zoo3:2890:3890' --network kafkanet 31z4/zookeeper"

docker-machine ssh manager1 "docker service create --name zoo1 --publish 2182:2181 --publish 2889:2888 --publish 3889:3888 --env ZOO_MY_ID=1 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2888:3888' --network kafkanet --network ingress 31z4/zookeeper"
docker-machine ssh manager1 "docker service create --name zoo2 --publish 2183:2181 --publish 2890:2888 --publish 3890:3888 --env ZOO_MY_ID=2 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2888:3888' --network kafkanet --network ingress 31z4/zookeeper"

### docker-machine ssh manager1 docker service create --name zoo1 --publish 2182:2181 --env ZOO_MY_ID=1 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888' --network kafkanet --network ingress 31z4/zookeeper

### zoo1:
###         image: 31z4/zookeeper
###         restart: always
###         ports:
###             - 2181
###         environment:
###             ZOO_MY_ID: 1
###             ZOO_SERVERS: server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888


# ################################ #
# tests avec fabric8/zookeeper     #
# ################################ #

### docker-machine ssh manager1 docker service create --name zookeeper-1 --publish 2182:2181 --env SERVER_ID=1 --env MAX_SERVERS=3 --network kafkanet fabric8/zookeeper
### docker-machine ssh manager1 docker service create --name zookeeper-2 --publish 2183:2181 --env SERVER_ID=2 --env MAX_SERVERS=3 --network kafkanet fabric8/zookeeper
### docker-machine ssh manager1 docker service create --name zookeeper-3 --publish 2184:2181 --env SERVER_ID=3 --env MAX_SERVERS=3 --network kafkanet fabric8/zookeeper

### SERVER_ID 	The id of the server
### MAX_SERVERS 	The number of servers in the ensemble


# ###################################### #
# tests avec cgswong/confluent-zookeeper #
# ###################################### #

### docker-machine ssh manager1 docker service create --name zk1 --publish 2182:2181 --env zk_id=1 --env zk_server_1=zk1 --env zk_server_2=zk2 --env zk_server_3=zk3 --network kafkanet cgswong/confluent-zookeeper
### docker-machine ssh manager1 docker service create --name zk2 --publish 2183:2181 --env zk_id=2 --env zk_server_1=zk1 --env zk_server_2=zk2 --env zk_server_3=zk3 --network kafkanet cgswong/confluent-zookeeper
### docker-machine ssh manager1 docker service create --name zk3 --publish 2184:2181 --env zk_id=3 --env zk_server_1=zk1 --env zk_server_2=zk2 --env zk_server_3=zk3 --network kafkanet cgswong/confluent-zookeeper

### docker run -d --name zk1 \
###   -p 2181:2181 -p 2888:2888 -p 3888:3888 \
###   -e zk_id=1 -e zk_server_1=172.17.8.101 -e zk_server_2=172.17.8.102 -e zk_server_3=172.17.8.103 \
###   cgswong/confluent-zookeeper


docker-machine ssh manager1 "docker service create --name zoo1 --publish 2182:2181 --publish 2889:2888 --publish 3889:3888 --env ZOO_MY_ID=1 --env ZOO_SERVERS='server.1=zoo1:2889:3889 server.2=zoo2:2890:3890' --network kafkanet --network ingress obees/zookeeper"
docker-machine ssh manager1 "docker service create --name zoo2 --publish 2183:2181 --publish 2890:2888 --publish 3890:3888 --env ZOO_MY_ID=2 --env ZOO_SERVERS='server.1=zoo1:2889:3889 server.2=zoo2:2890:3890' --network kafkanet --network ingress obees/zookeeper"

# L'accès par la virtual ip (vip) du service redirige à travers un load-balancer vers les conteneurs, 
# les ports n'ont pas besoin d'être exposés si le service partage un network overlay avec le conteneur appelant 

docker-machine ssh manager1 "docker service create --name zoo1 --publish 2181:2181 --env ZOO_MY_ID=1 --network kafkanet --network ingress 31z4/zookeeper"
# docker-machine ssh manager1 "docker service create --name zoo2 --publish 2183:2181 --env ZOO_MY_ID=2 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2888:3888' --network kafkanet --network ingress obees/zookeeper"

docker-machine ssh manager1 "docker service create --name zoo1 --publish 2182:2181 --env ZOO_MY_ID=1 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888' --network kafkanet obees/zookeeper"
docker-machine ssh manager1 "docker service create --name zoo2 --publish 2183:2181 --env ZOO_MY_ID=2 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888' --network kafkanet obees/zookeeper"
docker-machine ssh manager1 "docker service create --name zoo3 --publish 2184:2181 --env ZOO_MY_ID=3 --env ZOO_SERVERS='server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888' --network kafkanet obees/zookeeper"



