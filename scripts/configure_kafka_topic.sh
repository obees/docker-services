# ####################################### #
# create the testbox on the cluster hosts #
# ####################################### #

# Create the test box
docker-machine create --driver virtualbox testbox

# Get the manager1 host ip
MANAGER1_IP=$(docker-machine ip manager1)


# ##################################### #
# launch container with root privileges #
# ##################################### #

docker run -u root -ti ches/kafka bash

	# Rajouter l'adresse de MANAGER1_IP associée à zk
	# printf "192.168.99.100 zk\n" | tee -a /etc/hosts
	printf "Adresse_ip_manager zk\n" | tee -a /etc/hosts

	# Rajouter l'adresse de MANAGER1_IP associée à kafka
	printf "Adresse_ip_manager kafka\n" | tee -a /etc/hosts

	# Créer le topic topic dans zookeeper
	bin/kafka-topics.sh --create --topic topic --replication-factor 1 --partitions 1 --zookeeper zk:2181

	# Vérifier la création du topic
	bin/kafka-topics.sh --describe --zookeeper zk:2181 --topic topic

	# Lancer un producteur de data kafka
	bin/kafka-console-producer.sh --topic topic --broker-list "kafka:9092"

	# Lancer un consommateur de data kafka
	bin/kafka-console-consumer.sh --topic topic --from-beginning --zookeeper "zk:2181"


# ####################################### #
# call rest api url with curl             #
# ####################################### #

# Configuration de nifi
# Dans l'interface de nifi http://192.168.99.100:8080/nifi

# 1 : Créer une api rest sur le port 8081
# 2 : Pousser les messages vers le topic topic de kafka:9092 version 10


# ####################################### #
# call rest api url with curl             #
# ####################################### #

curl -i -X POST -H 'Content-Type: application/json' -d '{"nom":"data is here"}' http://192.168.99.100:8081/contentListener