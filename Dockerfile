# Choice of base image -- read DesignNotes.txt
FROM ubuntu:18.04

RUN apt-get update 
RUN apt-get install -y casync

ENTRYPOINT ["casync"]
