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
for i in $(seq 1 $MANAGER); do docker-machine create --driver virtualbox manager$i; done
for i in $(seq 1 $WORKER); do docker-machine create --driver virtualbox worker$i; done


# ##################################### #
# create the swarm on the cluster hosts #
# ##################################### #

# Init the swarm
docker-machine ssh manager1 docker swarm init --advertise-addr $(docker-machine ip manager1)

# Get the swarm manager join token
WORKER_JOIN_TOKEN=$(docker-machine ssh manager1 docker swarm join-token manager -q)

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
docker-machine ssh manager1 docker service create --name zk --publish 2181:2181 --network kafkanet jplock/zookeeper

# Create the kafka service
docker-machine ssh manager1 docker service create --name kafka --publish 9092:9092 --publish 7203:7203 --env KAFKA_ADVERTISED_HOST_NAME=kafka --env ZOOKEEPER_IP=zk --network kafkanet ches/kafka

# Create the nifi service
docker-machine ssh manager1 docker service create --name nifi --publish 8080:8080 --publish 8081:8081 --network ingress --network kafkanet mkobit/nifi


