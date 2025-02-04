# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#
# jenkins-packer-agent
#
# VERSION   0.0.1

FROM jpetazzo/dind

MAINTAINER Evan Brown <evanbrown@google.com>

# Install supervisord and Java
RUN apt-get update && apt-get install -y supervisor default-jdk

RUN apt-get install -y npm
RUN apt-get install -y tar

RUN apt-get install -y wget
RUN wget "http://apache.mirrors.ovh.net/ftp.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz"
RUN tar -xvzC /tmp -f apache-maven-3.3.3-bin.tar.gz
RUN mv /tmp/apache-maven-3.3.3 /maven
RUN rm apache-maven-3.3.3-bin.tar.gz
RUN rm -r --force /tmp/apache-maven-3.3.3
ENV MAVEN_PATH /maven
ENV PATH /maven/bin:$PATH

RUN apt-get install -y npm
RUN npm install -g bower
RUN npm install -g gulp
RUN npm install -g typescript@1.0

VOLUME /var/log/supervisor

# Install Packer
COPY third_party/packer_linux_amd64/* /usr/local/bin/

# Install Jenkins Swarm agent
ENV HOME /home/jenkins-agent
RUN useradd -c "Jenkins agent" -d $HOME -m jenkins-agent
RUN usermod -aG docker jenkins-agent
RUN curl --create-dirs -sSLo \
    /usr/share/jenkins/swarm-client-jar-with-dependencies.jar \
    http://maven.jenkins-ci.org/content/repositories/releases/org/jenkins-ci/plugins/swarm-client/1.22/swarm-client-1.22-jar-with-dependencies.jar \
    && chmod 755 /usr/share/jenkins

# Install gcloud
ENV CLOUDSDK_PYTHON_SITEPACKAGES 1
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y -qq --no-install-recommends wget unzip python php5-mysql php5-cli php5-cgi openjdk-7-jre-headless openssh-client python-openssl \
  && apt-get clean \
  && cd /home/jenkins-agent \
  && wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.zip && unzip google-cloud-sdk.zip && rm google-cloud-sdk.zip \
  && google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/.bashrc --disable-installation-options \
  && google-cloud-sdk/bin/gcloud --quiet components update pkg-go pkg-python pkg-java preview app \
  && google-cloud-sdk/bin/gcloud --quiet config set component_manager/disable_update_check true \
  && chown -R jenkins-agent /home/jenkins-agent/.config \
  && chown -R jenkins-agent google-cloud-sdk
ENV PATH /home/jenkins-agent/google-cloud-sdk/bin:$PATH

# Run Docker and Swarm processe with supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY jenkins-docker-supervisor.sh /usr/local/bin/jenkins-docker-supervisor.sh
ENTRYPOINT ["/usr/local/bin/jenkins-docker-supervisor.sh"]
