# Define the number of managers/workers
MANAGER=1
WORKER=2

# Create the Docker hosts
for i in $(seq 1 $MANAGER); do docker-machine create --driver virtualbox manager$i; done
for i in $(seq 1 $W 192.11.99.100:2377ORKER); do docker-machine create --driver virtualbox worker$i; done

# Init the swarm
# docker-machine ssh manager1 docker swarm init --listen-addr $(docker-machine ip manager1):2377
# docker swarm init --advertise-addr eth1
docker-machine ssh manager1 docker swarm init --advertise-addr $(docker-machine ip manager1)


# Add additional manager(s)
#for i in $(seq 2 $MANAGER); do docker-machine ssh manager$i docker swarm join --manager --listen-addr $(docker-machine ip manager$i):2377 $(docker-machine ip manager1):2377; done

WORKER_JOIN_TOKEN=$(docker-machine ssh manager1 docker swarm join-token worker -q)
# Add workers
for i in $(seq 1 $WORKER); do docker-machine ssh worker$i docker swarm join --token $WORKER_JOIN_TOKEN $(docker-machine ip manager1):2377; done

docker-machine ssh worker1 docker swarm join --token SWMTKN-1-5z9f9a4ip9xvlo6gf286nf5nntg6ebfa1zi3ynwt5g26qjysr5-cca1nddh38sfdsy3ushes9iww 192.168.99.100:2377

# Création du réseau de l'application
docker-machine ssh manager1 docker network create -d overlay mynet

# Création du service zookeeper
docker-machine ssh manager1 docker service create --name zk --publish 2181:2181 --publish 2888:2888 --publish 3888:3888 --network mynet --replicas 1 wurstmeister/zookeeper

# Scale de zookeeper
# docker-machine ssh manager1 docker service scale zk=3

# Création du service Kafka
#kafka:
#    build: .
#    ports:
#      - "9092"
#    environment:
#      KAFKA_ADVERTISED_HOST_NAME: 192.168.99.100
#      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
#    volumes:
#- /var/run/docker.sock:/var/run/docker.sock
# --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly=false \
# --mount target=/var/run/docker.sock source=/var/run/docker.sock type=bind \

docker-machine ssh manager1 sudo docker service create \
--name kafka \
--publish 9092:9092/tcp \
--mount target=/var/run/docker.sock source=/var/run/docker.sock type=bind \
--env KAFKA_ADVERTISED_HOST_NAME=$(docker-machine ip manager1) \
--env KAFKA_ZOOKEEPER_CONNECT=$(docker-machine ip manager1):2181 \
--network mynet \
--replicas 1 \
wurstmeister/kafka

#docker-machine ssh manager1 docker service create \
#--name kafka \
#--publish 9092:9092 \
#--env KAFKA_ADVERTISED_HOST_NAME=$(docker-machine ip manager1) \
#--env KAFKA_ZOOKEEPER_CONNECT=$(docker-machine ip manager1):2181 \
#--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
#--network mynet \
#--replicas 1 \
#wurstmeister/kafka

#docker service create \
#--name kafka \
#--publish 9092:9092 \
#--env KAFKA_ADVERTISED_HOST_NAME=eth1 \
#--env KAFKA_ZOOKEEPER_CONNECT=eth1:2181 \
#--mount target=/var/run/docker.sock,source=/var/run/docker.sock \
#--network mynet \
#--replicas 1 \
#wurstmeister/kafka

#--mount type=bind,source=`pwd`/static-site,target=/usr/share/nginx/html \

# ches kafka

docker swarm init --advertise-addr eth0

docker-machine create --driver virtualbox manager1
docker-machine create --driver virtualbox worker1
docker-machine create --driver virtualbox worker2
docker-machine ssh manager1 docker swarm init --advertise-addr $(docker-machine ip manager1)
WORKER_JOIN_TOKEN=$(docker-machine ssh manager1 docker swarm join-token worker -q)
docker-machine ssh worker1 docker swarm join --token $WORKER_JOIN_TOKEN $(docker-machine ip manager1):2377
docker-machine ssh worker2 docker swarm join --token $WORKER_JOIN_TOKEN $(docker-machine ip manager1):2377
docker-machine ssh manager1 docker network create --driver overlay --subnet 10.1.0.0/24 kafkanet
docker-machine ssh manager1 docker service create --name zk --publish 2181:2181 --network kafkanet jplock/zookeeper
docker-machine ssh manager1 docker service create --name kafka --publish 9092:9092 --publish 7203:7203 --env KAFKA_ADVERTISED_HOST_NAME=kafka --env ZOOKEEPER_IP=zk --network kafkanet ches/kafka
docker-machine ssh manager1 docker service create --name nifi --publish 8080:8080 --publish 8081:8081 --network ingress --network kafkanet mkobit/nifi

# Debug docker
10.0.2.15 zk

echo $(docker-machine ip manager1)

kafka-topics.sh --create --topic topic --replication-factor 1 --partitions 1 --zookeeper zk:2181
kafka-topics.sh --describe --zookeeper zk:2181 --topic topic

kafka-console-producer.sh --topic topic --broker-list kafka:9092

kafka-console-consumer.sh --topic topic --from-beginning --zookeeper zk:2181

curl -i -X POST -H 'Content-Type: application/json' -d '{"nom":"data is here"}' http://192.168.99.100:8081/contentListener

docker-machine ssh manager1 docker run --rm ches/kafka kafka-topics.sh --describe --zookeeper $(docker-machine ip manager1):2181 --topic topic

docker-machine ssh manager1 docker run --rm ches/kafka kafka-topics.sh --describe --zookeeper 192.168.99.100:2181 --topic topic

docker-machine ssh manager1 docker service create --name kafkaadm --env ZOOKEEPER_IP=192.168.99.100 --network kafkanet ches/kafka
