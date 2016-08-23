# Define the number of managers/workers
#MANAGER=3
#WORKER=5

# Create the Docker hosts
#for i in $(seq 1 $MANAGER); do docker-machine create --driver virtualbox manager$i; done
#for i in $(seq 1 $WORKER); do docker-machine create --driver virtualbox worker$i; done

# Init the swarm
#docker-machine ssh manager1 docker swarm init --auto-accept manager --auto-accept worker --listen-addr $(docker-machine ip manager1):2377

# Add additional manager(s)
#for i in $(seq 2 $MANAGER); do docker-machine ssh manager$i docker swarm join --manager --listen-addr $(docker-machine ip manager$i):2377 $(docker-machine ip manager1):2377; done

# Add workers
#for i in $(seq 1 $WORKER); do docker-machine ssh worker$i docker swarm join --listen-addr $(docker-machine ip worker$i):2377 $(docker-machine ip manager1):2377; done

docker swarm init

docker network create --type overlay kafkanet

mkdir -p kafka-data/{data,logs} && cd kafka-data

#docker service create --name zk --publish 2181:2181 --network kafkanet wurstmeister/zookeeper
docker service create --name zk --publish 2181:2181 --network kafkanet jplock/zookeeper

docker service create \
--name kafka \
--publish 9092:9092 \
--publish 7203:7203 \
--mount ./data:/data \
--mount ./logs:/logs \
--env KAFKA_ADVERTISED_HOST_NAME 192.168.99.100 \
--env ZOOKEEPER_IP 192.168.99.100 \
--network kafkanet \
ches/docker-kafka

#mkdir -p kafka-ex/{data,logs} && cd kafka-ex
#$ docker run -d --name zookeeper --publish 2181:2181 jplock/zookeeper:3.4.6
#$ docker run -d \
#    --hostname localhost \
#    --name kafka \
#    --volume ./data:/data --volume ./logs:/logs \
#    --publish 9092:9092 --publish 7203:7203 \
#    --env KAFKA_ADVERTISED_HOST_NAME=127.0.0.1 --env ZOOKEEPER_IP=127.0.0.1 \
#    ches/kafka