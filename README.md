# Conda Pack Docker

The primary aim of this repo is to support running python applications that listen to port 80 and be deployed with ease to Azure WebApps

This repo defines an azure pipelines that creates a docker image from a conda enviornment.yml file with an initialization script of setup_run_server.sh. The Azure pipeline creates the docker container and deploys to Azure Container Repository with the name of the environment (environment.yml name field) prefixed by "conda-"

## Azure webapps

Azure webapps provide support for running python applications that listen to port 80. However it is limited to the python environments and package supported by Azure. The more generic way is supported here by using Docker

## Example demo app

A simple demo app that hosts a sample dashboard that showcases a minimal setup to work with the above docker image

https://github.com/dwr-psandhu/demo-stocks-dash


The two requirements for the github repo being deployed are :-
 * an [environment.yml](https://github.com/dwr-psandhu/demo-stocks-dash/blob/master/environment.yml) file that can build the environment
 * a [run_server.sh](https://github.com/dwr-psandhu/demo-stocks-dash/blob/master/run_server.sh) that does setup and start the server (in this case panel serve command). 
 
You can find an example of both in the demo repo above


## Setup Azure pipeline

Use the packaged azure-pipelines.yml as a template. You will need to setup your own using [Azure pipeline](https://learn.microsoft.com/en-us/azure/devops/pipelines/?view=azure-devops)

A [service connection setup](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml ) is also needed.
