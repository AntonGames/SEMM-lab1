# cspell:words devcontainers TLAPS adduser libncurses opam rebar tlapm fontconfig sandboxing
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-24.04

##
##  Install packages needed for the build.
##
RUN set -xe \
    && apt-get update \
    && apt-get install -y git curl wget\
    && apt-get clean

##
##  Create a non-root user.
##
# RUN set -xe && adduser --ingroup root --shell /bin/bash vscode
USER vscode
ENV HOME=/home/vscode
WORKDIR ${HOME}
RUN set -xe && mkdir -p bin
ENV PATH="${HOME}/bin:${PATH}"
ENV LC_ALL="C.utf8"

##
## Install TLA+ and TLAPS.
##
USER root
RUN set -xe \
    && apt-get update \
    && apt-get install -y opam zlib1g-dev gawk time pkg-config fontconfig openjdk-21-jdk \
    && apt-get clean
USER vscode

RUN set -xe \
    && opam init --disable-sandboxing --yes --shell-setup \
    && opam switch create 5.4.0

RUN set -xe \
    && eval $(opam env --switch=5.4.0) \
    && git clone https://github.com/tlaplus/tlapm /tmp/tlapm \
    && cd /tmp/tlapm \
    && make opam-update \
    && make opam-deps \
    && make opam-deps-opt \
    && make \
    && make install \
    && cd $HOME \
    && rm -rf /tmp/tlapm
