#!/bin/bash
exec > /tmp/deployment.log
exec 2>&1
# Ubuntu update.
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get update && sudo apt-get --assume-yes install google-cloud-sdk

# Set Variables
USER_HOME=/home/ubuntu
FORSETI_HOME=$USER_HOME/forseti-security
FORSETI_SOURCE=${FORSETI_SOURCE}
FORSETI_VERSION=${FORSETI_VERSION}
SQL_PORT=${SQL_PORT}
SQL_INSTANCE_CONN_STRING=${SQL_INSTANCE_CONN_STRING}
FORSETI_DB_NAME=${FORSETI_DB_NAME}
FORSETI_SERVER_CONF=$FORSETI_HOME/configs/forseti_server_conf.yaml
FORSETI_STORAGE_BUCKET=${FORSETI_STORAGE_BUCKET}

# Install fluentd if necessary.
FLUENTD=$(ls /usr/sbin/google-fluentd)
if [ -z "$FLUENTD" ]; then
      cd $USER_HOME
      curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
      bash install-logging-agent.sh
fi
# Check whether Cloud SQL proxy is installed.
CLOUD_SQL_PROXY=$(which cloud_sql_proxy)
if [ -z "$CLOUD_SQL_PROXY" ]; then
        cd $USER_HOME
        wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64
        sudo mv cloud_sql_proxy.linux.amd64 /usr/local/bin/cloud_sql_proxy
        chmod +x /usr/local/bin/cloud_sql_proxy
fi
# Install Forseti Security.
cd $USER_HOME
rm -rf *forseti*
# Download Forseti source code
git clone $FORSETI_SOURCE
cd forseti-security
git fetch --all
git checkout $FORSETI_VERSION
# Forseti Host Setup
sudo apt-get install -y git unzip
# Forseti host dependencies
sudo apt-get install -y $(cat install/dependencies/apt_packages.txt | grep -v "#" | xargs)
# Forseti dependencies
pip install --upgrade pip==9.0.3
pip install -q --upgrade setuptools wheel
pip install -q --upgrade -r requirements.txt
# Setup Forseti logging
touch /var/log/forseti.log
chown ubuntu:root /var/log/forseti.log
cp $FORSETI_HOME/configs/logging/fluentd/forseti.conf /etc/google-fluentd/config.d/forseti.conf
cp $FORSETI_HOME/configs/logging/logrotate/forseti /etc/logrotate.d/forseti
chmod 644 /etc/logrotate.d/forseti
service google-fluentd restart
logrotate /etc/logrotate.conf
# Change the access level of configs/ rules/ and run_forseti.sh
chmod -R ug+rwx $FORSETI_HOME/configs $FORSETI_HOME/rules $FORSETI_HOME/install/gcp/scripts/run_forseti.sh
# Install Forseti
python setup.py install

# Export variables required by initialize_forseti_services.sh.
export SQL_PORT=${SQL_PORT}
export FORSETI_STORAGE_BUCKET=${FORSETI_STORAGE_BUCKET}
export SQL_INSTANCE_CONN_STRING=${SQL_INSTANCE_CONN_STRING}
export FORSETI_DB_NAME=${FORSETI_DB_NAME}
export FORSETI_HOME=$FORSETI_HOME
export FORSETI_SERVER_CONF=$FORSETI_HOME/configs/forseti_server_conf.yaml

# Store the variables in /etc/profile.d/forseti_environment.sh 
# so all the users will have access to them
echo -e "export FORSETI_HOME=$FORSETI_HOME\nexport FORSETI_SERVER_CONF=$FORSETI_SERVER_CONF" >> /etc/profile.d/forseti_environment.sh | sudo sh
# Download server configuration from GCS
gsutil cp gs://$FORSETI_STORAGE_BUCKET/configs/forseti_server_conf.yaml $FORSETI_SERVER_CONF
gsutil cp -r gs://$FORSETI_STORAGE_BUCKET/rules $FORSETI_HOME/rules/
# Start Forseti service depends on vars defined above.
bash ./install/gcp/scripts/initialize_forseti_services.sh
echo "Starting services."
systemctl start cloudsqlproxy
sleep 5
systemctl start forseti
echo "Success! The Forseti API server has been started."
# Create a Forseti env script
FORSETI_ENV="$(cat <<EOF
#!/bin/bash
export PATH=$PATH:/usr/local/bin
# Forseti environment variables
export FORSETI_HOME=/home/ubuntu/forseti-security
export FORSETI_SERVER_CONF=$FORSETI_HOME/configs/forseti_server_conf.yaml
export SCANNER_BUCKET=$FORSETI_STORAGE_BUCKET
EOF
)"
echo "$FORSETI_ENV" > $USER_HOME/forseti_env.sh
USER=ubuntu
# Use flock to prevent rerun of the same cron job when the previous job is still running.
# If the lock file does not exist under the tmp directory, it will create the file and put a lock on top of the file.
# When the previous cron job is not finished and the new one is trying to run, it will attempt to acquire the lock
# to the lock file and fail because the file is already locked by the previous process.
# The -n flag in flock will fail the process right away when the process is not able to acquire the lock so we won't
# queue up the jobs.
# If the cron job failed the acquire lock on the process, it will log a warning message to syslog.
(echo "${CRON_SCHEDULE} (/usr/bin/flock -n /home/ubuntu/forseti-security/forseti_cron_runner.lock $FORSETI_HOME/install/gcp/scripts/run_forseti.sh || echo '[forseti-security] Warning: New Forseti cron job will not be started, because previous Forseti job is still running.') 2>&1 | logger") | crontab -u $USER -
echo "Added the run_forseti.sh to crontab under user $USER"
echo "Execution of startup script finished"