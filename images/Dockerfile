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

# download and extract cf cli
RUN wget -O cf.tgz 'https://packages.cloudfoundry.org/stable?release=linux64-binary&version=6.49.0&source=github-rel' && \
    tar xvfz cf.tgz && \
    chmod +x cf && \
    mv cf /usr/bin/cf

# download and extract yq cli
RUN wget -O yq 'https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64' && \
    chmod +x yq && \
    mv yq /usr/bin/yq

# download and extract jq cli
RUN wget -O jq 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64' && \
    chmod +x jq && \
    mv jq /usr/bin/jq

# download and extract OM cli
RUN wget -O om 'https://github.com/pivotal-cf/om/releases/download/4.4.2/om-linux-4.4.2' && \
     chmod +x om && \
     mv om /usr/bin/om

# move only the binary to the output image
FROM ubuntu:latest 
COPY --from=build /usr/bin/sqlite3 /usr/bin/sqlite3
COPY --from=build /usr/bin/jq /usr/bin/jq
COPY --from=build /usr/bin/yq /usr/bin/yq
COPY --from=build /usr/bin/cf /usr/bin/cf
COPY --from=build /usr/bin/om /usr/bin/om
CMD /bin/bash
