# The build-stage image:
FROM continuumio/miniconda3:24.3.0-0 AS build

SHELL ["/bin/bash", "-c"]

# Install necessary packages
RUN conda config --set always_yes yes --set changeps1 no && \
    conda update -n base -c defaults conda && \
    conda config --add channels conda-forge && \
    conda install -c conda-forge conda-pack

# Install libmamba and set it as default solver
RUN conda install -n base conda-libmamba-solver && \
    conda config --set solver libmamba

# Copy environment definition
COPY environment.yml .

# Extract environment name from the YAML
ARG ENV_NAME
RUN ENV_NAME=$(head -1 environment.yml | cut -d ':' -f2 | xargs) && \
    conda env create -f environment.yml && \
    conda-pack -n "$ENV_NAME" -o /tmp/env.tar && \
    conda clean --all --force-pkgs-dirs -y && \
    mkdir /env && cd /env && tar xf /tmp/env.tar && \
    rm /tmp/env.tar

# Fix paths in packed conda env
RUN /env/bin/conda-unpack

# Runtime stage
FROM debian:bookworm-slim AS runtime

# Set shell
SHELL ["/bin/bash", "-c"]

# Copy prebuilt env
COPY --from=build /env /env

# Install basic packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends git wget curl ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose HTTP port
EXPOSE 80

# Add entrypoint script
ADD setup_run_server.sh .

# Run the startup script
ENTRYPOINT ["/bin/bash", "setup_run_server.sh"]
