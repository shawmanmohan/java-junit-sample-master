FROM java:latest

MAINTAINER Stuti Rastogi "stutirastogi92@gmail.com"

RUN mkdir /opt/sampleapp
WORKDIR /opt/sampleapp

ADD target/junitsample*.jar .
ADD bin/ bin/

EXPOSE 8080

CMD ["sh", "./bin/start.sh"]
