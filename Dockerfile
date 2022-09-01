# The build-stage image:
FROM continuumio/miniconda3 AS build

#Install mamba
RUN conda install mamba -n base -c conda-forge

# Install the package as normal:
# the environment.yml file is downloaded from the git repo by the azure pipeline. 
# If this fails, then the repo is specified before this build doesn't have the environment.yml at its top level
COPY environment.yml .
RUN mamba env create -f environment.yml

# Install conda-pack:
RUN mamba install -c conda-forge conda-pack

# Use conda-pack to create a standalone enviornment
# in /venv:
RUN export CONDA_ENV_NAME="$(head -1 environment.yml | cut -f 2 -d ":" | sed -e 's/^[[:space:]]*//' -)" && \
  conda-pack -n ${CONDA_ENV_NAME} -o /tmp/env.tar && \
  mkdir /venv && cd /venv && tar xf /tmp/env.tar && \
  rm /tmp/env.tar

# We've put venv in same path it'll be in final image,
# so now fix up paths:
RUN /venv/bin/conda-unpack

# The runtime-stage image; we can use Debian as the
# base image since the Conda env also includes Python
# for us.
FROM debian:buster-slim AS runtime

# Copy /venv from the previous stage:
COPY --from=build /venv /venv
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
ADD setup_run_server.sh .
ENTRYPOINT ["/bin/bash", "setup_run_server.sh"]
