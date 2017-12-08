FROM ubuntu:17.10
LABEL refresh=2017-12-08
RUN apt-get update
RUN apt-get install -y software-properties-common git
RUN add-apt-repository ppa:haxe/releases -y
RUN apt-get update && apt-get install -y neko haxe && haxelib setup /usr/share/haxe/lib

