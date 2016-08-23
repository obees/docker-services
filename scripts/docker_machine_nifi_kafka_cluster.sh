# Define the number of managers/workers
MANAGER=3
WORKER=5

# Create the Docker hosts
for i in $(seq 1 $MANAGER); do docker-machine create --driver virtualbox manager$i; done
for i in $(seq 1 $WORKER); do docker-machine create --driver virtualbox worker$i; done

# Init the swarm
docker-machine ssh manager1 docker swarm init --auto-accept manager --auto-accept worker --listen-addr $(docker-machine ip manager1):2377

# Add additional manager(s)
for i in $(seq 2 $MANAGER); do docker-machine ssh manager$i docker swarm join --manager --listen-addr $(docker-machine ip manager$i):2377 $(docker-machine ip manager1):2377; done

# Add workers
for i in $(seq 1 $WORKER); do docker-machine ssh worker$i docker swarm join --listen-addr $(docker-machine ip worker$i):2377 $(docker-machine ip manager1):2377; done