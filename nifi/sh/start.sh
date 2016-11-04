#!/bin/bash

# NIFI_HOME is defined by an ENV command in the backing Dockerfile
nifi_props_file=${NIFI_HOME}/conf/nifi.properties
state_management_props_file=${NIFI_HOME}/conf/state-management.xml


hr() {
    width=20
    if [[ -s "$TERM" ]]
    then
        width=$(tput cols)
    fi
    printf '\n%*s\n\n' "${COLUMNS:-${width}}" '' | tr ' ' '*'
}

enable_ssl() {
    echo Configuring environment with SSL settings
    : ${KEYSTORE_PATH:?"Must specify an absolute path to the keystore being used."}
    if [[ ! -f "${KEYSTORE_PATH}" ]]; then
        echo "Keystore file specified (${KEYSTORE_PATH}) does not exist."
        exit 1
    fi
    : ${KEYSTORE_TYPE:?"Must specify the type of keystore (JKS, PKCS12, PEM) of the keystore being used."}
    : ${KEYSTORE_PASSWORD:?"Must specify the password of the keystore being used."}

    : ${TRUSTSTORE_PATH:?"Must specify an absolute path to the truststore  being used."}
    if [[ ! -f "${TRUSTSTORE_PATH}" ]]; then
        echo "Keystore file specified (${TRUSTSTORE_PATH}) does not exist."
        exit 1
    fi
    : ${TRUSTSTORE_TYPE:?"Need to set DEST non-empty"}
    : ${TRUSTSTORE_PASSWORD:?"Need to set DEST non-empty"}

    sed -i '\|^nifi.security.keystore=| s|$|'${KEYSTORE_PATH}'|g' ${nifi_props_file}
    sed -i '\|^nifi.security.keystoreType=| s|$|'${KEYSTORE_TYPE}'|g' ${nifi_props_file}
    sed -i '\|^nifi.security.keystorePasswd=| s|$|'${KEYSTORE_PASSWORD}'|g' ${nifi_props_file}
    sed -i '\|^nifi.security.truststore=| s|$|'${TRUSTSTORE_PATH}'|g' ${nifi_props_file}
    sed -i '\|^nifi.security.truststoreType=| s|$|'${TRUSTSTORE_TYPE}'|g' ${nifi_props_file}
    sed -i '\|^nifi.security.truststorePasswd=| s|$|'${TRUSTSTORE_PASSWORD}'|g' ${nifi_props_file}

    # Disable HTTP and enable HTTPS
    sed -i -e 's|nifi.web.http.port=.*$|nifi.web.http.port=|' ${nifi_props_file}
    sed -i -e 's|nifi.web.https.port=.*$|nifi.web.https.port=443|' ${nifi_props_file}
}

disable_ssl() {
    echo Configuring environment with default HTTP settings

    sed -i -e 's|^nifi.security.keystore=.*$|nifi.security.keystore=|' ${nifi_props_file}
    sed -i -e 's|^nifi.security.keystoreType=.*$|nifi.security.keystoreType=|' ${nifi_props_file}
    sed -i -e 's|^nifi.security.keystorePasswd=.*$|nifi.security.keystorePasswd=|' ${nifi_props_file}
    sed -i -e 's|^nifi.security.truststore=.*$|nifi.security.truststore=|' ${nifi_props_file}
    sed -i -e 's|^nifi.security.truststoreType=.*$|nifi.security.truststoreType=|' ${nifi_props_file}
    sed -i -e 's|^nifi.security.truststorePasswd=.*$|nifi.security.truststorePasswd=|' ${nifi_props_file}

    # Disable HTTPS and enable HTTP
    sed -i -e 's|nifi.web.http.port=.*$|nifi.web.http.port=80|' ${nifi_props_file}
    sed -i -e 's|nifi.web.https.port=.*$|nifi.web.https.port=|' ${nifi_props_file}
}

enable_cluster() {

    # nifi.properties 
    sed -i -e 's|nifi.web.http.host=.*$|nifi.web.http.host='${NIFI_WEB_HTTP_HOST}'|' ${nifi_props_file}                                                 # NIFI_WEB_HTTP_HOST ... nifi1, nifi2, ... à passer en variable d'environnement
    sed -i -e 's|nifi.web.http.port=.*$|nifi.web.http.port='${NIFI_WEB_HTTP_PORT}'|' ${nifi_props_file}                                                 # NIFI_WEB_HTTP_PORT 80 à passer --env
    sed -i -e 's|nifi.cluster.is.node=.*$|nifi.cluster.is.node='${NIFI_CLUSTER_IS_NODE}'|' ${nifi_props_file}                                           # NIFI_CLUSTER_IS_NODE true # Mettre à true si cluster
    sed -i -e 's|nifi.cluster.node.address=.*$|nifi.cluster.node.address='${NIFI_CLUSTER_NODE_ADDRESS}'|' ${nifi_props_file}                            # NIFI_CLUSTER_NODE_ADDRESS ... nifi1, nifi2 # Set this to the fully qualified hostname of the node. If left blank, it defaults to "localhost".
    sed -i -e 's|nifi.cluster.node.protocol.port=.*$|nifi.cluster.node.protocol.port='${NIFI_CLUSTER_NODE_PROTOCOL_PORT}'|' ${nifi_props_file}          # NIFI_CLUSTER_NODE_PROTOCOL_PORT 2190 par ex. # Set this to an open port that is higher than 1024 (anything lower requires root).
    sed -i -e 's|nifi.cluster.node.protocol.threads=.*$|nifi.cluster.node.protocol.threads='${NIFI_CLUSTER_NODE_PROTOCOL_THREADS}'|' ${nifi_props_file} # NIFI_CLUSTER_NODE_PROTOCOL_THREADS 10 # The number of threads that should be used to communicate with other nodes in the cluster. This property defaults to 10, but for large clusters, this value may need to be larger.
    sed -i -e 's|nifi.zookeeper.connect.string=.*$|nifi.zookeeper.connect.string='${NIFI_ZOOKEEPER_CONNECT_STRING}'|' ${nifi_props_file}                # NIFI_ZOOKEEPER_CONNECT_STRING zoo1:2181,zoo2:2181,zoo3:2181 # The Connect String that is needed to connect to Apache ZooKeeper. This is a comma-separted list of hostname:port pairs. For example, localhost:2181,localhost:2182,localhost:2183. This should contain a list of all ZooKeeper instances in the ZooKeeper quorum.
    sed -i -e 's|nifi.zookeeper.root.node=.*$|nifi.zookeeper.root.node='${NIFI_ZOOKEEPER_ROOT_NODE}'|' ${nifi_props_file}                               # NIFI_ZOOKEEPER_ROOT_NODE /nifi/nifi1 ou /nifi/nifi2

    # state-management.xml
    # sed "/<fiction type='a'>/,/<\/fiction>/ s/<author type=''><\/author>/<author type='Local'><\/author>/g;" ${state_management_props_file}

    sed -i -e "s/<property name=\"Connect String\"><\/property>/<property name=\"Connect String\">${NIFI_ZOOKEEPER_CONNECT_STRING}<\/property>/g;" ${state_management_props_file}  # NIFI_ZOOKEEPER_CONNECT_STRING zoo1:2181,zoo2:2181,zoo3:2181 # The Connect String that is needed to connect to Apache ZooKeeper. This is a comma-separted list of hostname:port pairs. For example, localhost:2181,localhost:2182,localhost:2183. This should contain a list of all ZooKeeper instances in the ZooKeeper quorum. # myhost.mydomain:2181,host2.mydomain:5555,host3:6666
    sed -i -e "s/<property name=\"Root Node\"><\/property>/<property name=\"Root Node\">${NIFI_ZOOKEEPER_ROOT_NODE}<\/property>/g;" ${state_management_props_file} # NIFI_ZOOKEEPER_ROOT_NODE /nifi/nifi1 ou /nifi/nifi2

}

if [[ "$DISABLE_SSL" != "true" ]]; then
    enable_ssl
else
    hr
    echo 'NOTE: Apache NiFi has not been configured to run with SSL and is open to anyone that has access to the exposed UI port on which it runs.  Please safeguard accordingly.'
    hr
    disable_ssl
fi

echo 'Cluster configuration will start now'
enable_cluster
echo 'Cluster configuration finished'

# Continuously provide logs so that 'docker logs' can produce them
tail -F ${NIFI_HOME}/logs/nifi-app.log &
${NIFI_HOME}/bin/nifi.sh run
