FROM ubuntu:16.04

# Work around for license accept screen.
RUN echo debconf shared/accepted-oracle-license-v1-1 select true \
    | debconf-set-selections

RUN apt-get update --fix-missing -qq && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:webupd8team/java

RUN apt-get update --fix-missing -qq && \
    apt-get install -y \
    	wget \
    	nmap \
    	oracle-java8-installer \
    	golang \
		git

ENV SRC_PATH /usr/local/src
RUN mkdir -p $SRC_PATH

# Grab the osmosis files from the submodule so we can patch and
# build.
COPY ./src $SRC_PATH

WORKDIR $SRC_PATH

ENV OSMOSIS_PATH $SRC_PATH/osmosis/bin
ENV OSMOSIS $OSMOSIS_PATH/osmosis

ENV GOPATH /root/.go

# Download a custom Go library for chunking up the PBF file and
# making partial HTTP Range requests.
RUN go get github.com/mapbox/planet-stream

ENV SCRIPT_PATH /usr/local/scripts

ADD scripts/ $SCRIPT_PATH
WORKDIR $SCRIPT_PATH

RUN chmod +x $SCRIPT_PATH/*.sh

RUN mkdir -p $OSMOSIS_PATH
RUN $SCRIPT_PATH/patch-osmosis.sh

ENTRYPOINT $SCRIPT_PATH/docker-entrypoint.sh