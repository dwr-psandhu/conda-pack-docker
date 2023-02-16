# The build-stage image:
FROM continuumio/miniconda3 AS build

# Use a smaller base image for faster build times
FROM alpine:3.14 AS build-alpine

# Install mamba and other necessary packages
RUN apk update && apk add --no-cache ca-certificates openssl gnupg && \
    wget https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc && \
    gpg --import anaconda.asc && \
    conda config --set always_yes yes --set changeps1 no && \
    conda config --add channels conda-forge && \
    conda install -c conda-forge mamba && \
    conda install -c conda-forge conda-pack && \
    rm -rf /root/.gnupg anaconda.asc

# Install the package as normal:
# the environment.yml file is downloaded from the git repo by the azure pipeline. 
# If this fails, then the repo is specified before this build doesn't have the environment.yml at its top level
COPY environment.yml .
RUN mamba env create -f environment.yml && \
    /venv/bin/conda clean --all --force-pkgs-dirs -y && \
    /venv/bin/conda-pack -n $(head -1 environment.yml | cut -f 2 -d ":" | sed -e 's/^[[:space:]]*//' -) -o /tmp/env.tar && \
    mkdir /env && cd /env && tar xf /tmp/env.tar && \
    rm /tmp/env.tar

# We've put env in same path it'll be in final image,
# so now fix up paths:
RUN /env/bin/conda-unpack

# The runtime-stage image; we can use Alpine as the
# base image since the Conda env also includes Python
# for us.
FROM alpine:3.14 AS runtime

# Copy /env from the previous stage:
COPY --from=build-alpine /env /env
# Install git, wget, and libgl (for vtk)
RUN apk add --no-cache git wget curl libgl && \
    rm -rf /var/cache/apk/*

# Open 80 for http
EXPOSE 80
# When image is run, run the code with the environment
# activated env and git clone repo provided as first argument to setup_run_server.sh and cd to it
# and source run_server.sh there expecting it to start server listening to port 80
# Use bash instead of sh
ADD setup_run_server.sh .
ENTRYPOINT ["/bin/bash", "setup_run_server.sh"]
