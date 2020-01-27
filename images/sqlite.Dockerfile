FROM ubuntu:latest as build

ENV DEBIAN_FRONTEND noninteractive

# update packages
RUN apt-get update 

# install wget, gcc and tcl packages
RUN apt-get install wget build-essential tcl -y 

# download and extract sqlite
RUN wget -O sqlite.tar.gz \
      https://www.sqlite.org/src/tarball/sqlite.tar.gz?r=release && \
    tar xvfz sqlite.tar.gz 

# build and confgure sqlite
# test to make sure it built correctly
RUN ./sqlite/configure --prefix=/usr && \
    make && \
    make install && \
    sqlite3 --version

# move only the binary to the output image
FROM ubuntu:latest 
COPY --from=build /usr/bin/sqlite3 /usr/bin/sqlite3
CMD /bin/bash