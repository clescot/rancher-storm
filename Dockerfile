FROM ubuntu:15.10
MAINTAINER Florian HUSSONNOIS, florian.hussonnois_gmail.com


# Install Oracle JDK 8 and others useful packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y python-software-properties software-properties-common
RUN add-apt-repository -y ppa:webupd8team/java && apt-get update

# Accept the Oracle license before the installation
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections 
RUN apt-get update && apt-get install -y oracle-java8-installer

# Tells Supervisor to run interactively rather than daemonize
RUN apt-get install -y supervisor wget tar 
RUN echo [supervisord] | tee -a /etc/supervisor/supervisord.conf ; echo nodaemon=true | tee -a /etc/supervisor/supervisord.conf

ENV STORM_VERSION 0.10.0

# Create storm group and user
ENV STORM_HOME /usr/share/apache-storm

RUN groupadd storm; useradd --uid 87 --gid storm --home-dir /home/storm --create-home --shell /bin/bash storm

# Download and Install Apache Storm
RUN wget http://apache.mirrors.ovh.net/ftp.apache.org/dist/storm/apache-storm-$STORM_VERSION/apache-storm-$STORM_VERSION.tar.gz && \
tar -xzvf apache-storm-$STORM_VERSION.tar.gz -C /usr/share && mv $STORM_HOME-$STORM_VERSION $STORM_HOME && \
rm -rf apache-storm-$STORM_VERSION.tar.gz

RUN chown -R storm:storm $STORM_HOME

#add confd 
COPY confd-0.11.0-linux-amd64  /usr/local/bin/confd
RUN bash -c 'mkdir -p /etc/confd/{conf.d,templates}'
RUN chmod 777 /usr/local/bin/confd

COPY ./confd /etc/confd
RUN chmod a+x /etc/confd

RUN mkdir /var/log/storm ; chown -R storm:storm /var/log/storm ; ln -s /var/log/storm /home/storm/log
RUN ln -s $STORM_HOME/bin/storm /usr/bin/storm

# add ping for checkrancher function in entrypoint
RUN apt-get install -y iputils-ping

USER storm

#COPY conf/storm.yaml.template $STORM_HOME/conf/storm.yaml.template

# Add scripts required to run storm daemons under supervision
COPY supervisor/storm-daemon.conf /home/storm/storm-daemon.conf
COPY script/entrypoint.sh /home/storm/entrypoint.sh

USER root 
RUN chmod u+x /home/storm/entrypoint.sh


# Add VOLUMEs to allow backup of config and logs
VOLUME ["/usr/share/apache-storm/conf","/var/log/storm"]


ENTRYPOINT ["/bin/bash", "/home/storm/entrypoint.sh"]

