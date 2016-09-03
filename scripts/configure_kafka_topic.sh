# ####################################### #
# create the testbox on the cluster hosts #
# ####################################### #

# Create the test box
### docker-machine create --driver virtualbox testbox

# Get the manager1 host ip
### MANAGER1_IP=$(docker-machine ip manager1)

### docker-machine ssh testbox docker run --rm ches/kafka /bin/bash

# c'est pas dans le host qu'il faut injecter mai dans le conteneur
### docker-machine ssh testbox echo "$MANAGER1_IP zk\n" | sudo tee -a /etc/hosts 

# Create topic
### docker-machine ssh testbox docker run --rm ches/kafka kafka-topics.sh --create --topic topic2 --replication-factor 1 --partitions 1 --zookeeper "$MANAGER1_IP:2181"

# Check if the topic is in kafka
# docker-machine ssh testbox docker run --rm ches/kafka kafka-topics.sh --describe --zookeeper "$MANAGER1_IP:2181" --topic topic

### docker-machine ssh testbox docker run --rm --interactive ches/kafka kafka-console-producer.sh --topic topic2 --broker-list "$MANAGER1_IP:9092"

### docker-machine ssh testbox docker run --rm ches/kafka kafka-console-consumer.sh --topic topic2 --from-beginning --zookeeper "$MANAGER1_IP:2181"