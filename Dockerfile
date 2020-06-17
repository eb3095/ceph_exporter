FROM ubuntu:18.04 as builder
MAINTAINER Vaibhav Bhembre <vaibhav@digitalocean.com>
MAINTAINER Eric Benner <ebennerit@gmail.com>

ARG TEST

ENV GOROOT /goroot
ENV GOPATH /go
ENV PATH $GOROOT/bin:$PATH
ENV APPLOC $GOPATH/src/github.com/digitalocean/ceph_exporter

RUN apt-get update && \
    apt-get install -y apt-transport-https build-essential git curl wget gnupg2

RUN wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add -
RUN echo "deb https://download.ceph.com/debian-luminous bionic main" >> /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y --force-yes librados-dev librbd-dev

RUN \
  mkdir -p /goroot && \
  curl https://storage.googleapis.com/golang/go1.13.linux-amd64.tar.gz | tar xvzf - -C /goroot --strip-components=1

ADD . $APPLOC
WORKDIR $APPLOC
RUN go get -d
RUN if [ -n "${TEST}" ]; then go test -v ./...; fi
RUN go build -o /bin/ceph_exporter

FROM ubuntu:18.04
MAINTAINER Vaibhav Bhembre <vaibhav@digitalocean.com>
MAINTAINER Eric Benner <ebennerit@gmail.com>

RUN apt-get update && \
    apt-get install -y apt-transport-https curl wget gnupg2
RUN wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add -
RUN echo "deb https://download.ceph.com/debian-luminous bionic main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --force-yes librados2 librbd1 ceph-common && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /bin/ceph_exporter /bin/ceph_exporter
RUN chmod +x /bin/ceph_exporter

EXPOSE 9128
ENTRYPOINT ["/bin/ceph_exporter"]
