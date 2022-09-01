# activate the conda pack environment
source /venv/bin/activate
# git clone the repo which has the run_server.sh 
url=$1
git clone $url dash_app
cd dash_app
# run_server.sh in the git repo should start a web server listening to port 80
# e.g. with holoviz panel like 
# panel serve my_dash.ipynb --address 0.0.0.0 --port 80 --allow-websocket-origin="*"
source run_server.sh

