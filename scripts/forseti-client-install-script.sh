#!/bin/bash
exec > /tmp/deployment.log
exec 2>&1
# Ubuntu update.
sudo apt-get update -y
sudo apt-get upgrade -y
# Forseti setup.
sudo apt-get install -y git unzip
# Forseti dependencies
sudo apt-get install -y libffi-dev libssl-dev libmysqlclient-dev python-pip python-dev build-essential
#Set Env Variables
USER=ubuntu
USER_HOME=/home/ubuntu
FORSETI_HOME=$USER_HOME/forseti-security
FORSETI_VERSION=${FORSETI_VERSION}
FORSETI_SOURCE=${FORSETI_SOURCE}
FORSETI_CLIENT_CONF=$FORSETI_HOME/configs/forseti_client_conf.yaml
FORSETI_CLIENT_BUCKET=${FORSETI_CLIENT_BUCKET}
# Install fluentd if necessary.
FLUENTD=$(ls /usr/sbin/google-fluentd)
if [ -z "$FLUENTD" ]; then
      cd $USER_HOME
      curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
      bash install-logging-agent.sh
fi
# Install Forseti Security.
cd $USER_HOME
rm -rf *forseti*
# Download Forseti source code
git clone $FORSETI_SOURCE
cd forseti-security
git fetch --all
git checkout $FORSETI_VERSION
# Download server configuration from GCS
gsutil cp gs://$FORSETI_CLIENT_BUCKET/configs/forseti_client_conf.yaml $FORSETI_CLIENT_CONF
# Forseti dependencies
pip install --upgrade pip==9.0.3
pip install -q --upgrade setuptools wheel
pip install -q --upgrade -r requirements.txt
# Install Forseti
python setup.py install
# Set ownership of the forseti project to $USER
chown -R $USER $FORSETI_HOME
#Export Variables
export FORSETI_HOME=$FORSETI_HOME
export FORSETI_CLIENT_CONF=$FORSETI_CLIENT_CONF
# Store the variables in /etc/profile.d/forseti_environment.sh 
# so all the users will have access to them
echo -e "export FORSETI_HOME=$FORSETI_HOME\nexport FORSETI_CLIENT_CONF=$FORSETI_CLIENT_CONF" >> /etc/profile.d/forseti_environment.sh | sudo sh
chomd ugo+r $FORSETI_CLIENT_CONF
echo "Execution of startup script finished"