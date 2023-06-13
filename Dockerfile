# The build-stage image:
FROM continuumio/miniconda3:22.11.1 AS build

# Install mamba and other necessary packages
RUN conda config --set always_yes yes --set changeps1 no && \
    conda update --all -y && \
    conda config --add channels conda-forge && \
    conda install -c conda-forge mamba libarchive && \
    conda install -c conda-forge conda-pack

# Install the package as normal:
# the environment.yml file is downloaded from the git repo by the azure pipeline. 
# If this fails, then the repo is specified before this build doesn't have the environment.yml at its top level
COPY environment.yml .
RUN mamba env create -f environment.yml && \
    mamba install -c conda-forge conda-pack &&\
    conda clean --all --force-pkgs-dirs -y && \
    conda-pack -n $(head -1 environment.yml | cut -f 2 -d ":" | sed -e 's/^[[:space:]]*//' -) -o /tmp/env.tar && \
    mkdir /env && cd /env && tar xf /tmp/env.tar && \
    rm /tmp/env.tar

# We've put env in same path it'll be in final image,
# so now fix up paths:
RUN /env/bin/conda-unpack

# The runtime-stage image; we can use Alpine as the
# base image since the Conda env also includes Python
# for us.
#FROM alpine:3.14 AS runtime
FROM debian:buster-slim AS runtime

# Copy /env from the previous stage:
COPY --from=build /env /env
# Install git, wget
#RUN apk add --no-cache bash git wget curl && \
#    rm -rf /var/cache/apk/*
# Install git, wget 
RUN apt-get update && \
       apt-get -y install git wget curl &&\
       apt-get clean all && \
       apt-get purge && \
       rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Open 80 for http
EXPOSE 80
# When image is run, run the code with the environment
# activated env and git clone repo provided as first argument to setup_run_server.sh and cd to it
# and source run_server.sh there expecting it to start server listening to port 80
# Use bash instead of sh
ADD setup_run_server.sh .
ENTRYPOINT ["/bin/bash", "setup_run_server.sh"]
