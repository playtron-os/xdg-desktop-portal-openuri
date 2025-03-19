# Version 1.0.0

FROM fedora:41

RUN dnf update -y && \
    dnf install -y \
    rpm-build \
    rpmdevtools \
    tar \
    make \
    git \
    wget \
    nano \
    && dnf clean all

COPY ./Makefile .
RUN make deps

RUN rpmdev-setuptree

ENV RPMBUILD=/tmp/rpmbuild