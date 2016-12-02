FROM centos:7
MAINTAINER obees

# install c dependencies
RUN yum install -y gcc python-devel

# install librdkafka
RUN rpm --import http://packages.confluent.io/rpm/3.1/archive.key

RUN touch /etc/yum.repos.d/confluent.repo
RUN echo "[Confluent.dist]" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "name=Confluent repository (dist)" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "baseurl=http://packages.confluent.io/rpm/3.1/7" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "gpgcheck=1" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "gpgkey=http://packages.confluent.io/rpm/3.1/archive.key" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "enabled=1" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "[Confluent]" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "name=Confluent repository" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "baseurl=http://packages.confluent.io/rpm/3.1" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "gpgcheck=1" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "gpgkey=http://packages.confluent.io/rpm/3.1/archive.key" | tee --append /etc/yum.repos.d/confluent.repo
RUN echo "enabled=1" | tee --append /etc/yum.repos.d/confluent.repo

RUN yum install -y librdkafka-devel

# install pip
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
RUN python get-pip.py

# install python kafka client
RUN pip install confluent-kafka

CMD ["/bin/bash"]

