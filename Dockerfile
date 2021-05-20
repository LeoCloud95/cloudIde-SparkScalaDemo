ARG NODE_VERSION=12.18.3
FROM ibmcom/ibmjava:8-sdk as java-base

FROM node:$NODE_VERSION
COPY --from=java-base /opt/ibm/java /opt/ibm/java

ENV TZ='Asia/Shanghai' \
    JAVA_HOME=/opt/ibm/java \
    PATH=/opt/ibm/java/jre/bin:/opt/ibm/java/bin/:$PATH

RUN apt-get update && \
  apt-get install -y curl apt-transport-https maven gradle && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && apt-get install -y yarn && \
  rm -rf /var/lib/apt/lists/*
# install scala
RUN wget https://downloads.lightbend.com/scala/2.11.8/scala-2.11.8.deb && dpkg -i scala-2.11.8.deb && rm scala-2.11.8.deb

# See : https://github.com/theia-ide/theia-apps/issues/34
RUN adduser --disabled-password --gecos '' theia
RUN chmod g+rw /home && \
    mkdir -p /home/project && \
    chown -R theia:theia /home/theia && \
    chown -R theia:theia /home/project;
WORKDIR /home/theia
USER theia

ARG version=latest
ADD $version.package.json ./package.json
ARG GITHUB_TOKEN
RUN yarn --cache-folder ./ycache && rm -rf ./ycache && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build ; \
    yarn theia download:plugins
EXPOSE 3000
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins

USER root
COPY src/ /root/dockerstartup/
RUN chmod +x /root/dockerstartup/*.sh

RUN mkdir -p /home/project/SparkScalaDemo
COPY SparkScalaDemo/ /home/project/SparkScalaDemo

WORKDIR /home/project/SparkScalaDemo
RUN mvn package

ENTRYPOINT ["/root/dockerstartup/startup.sh"]
