#!/bin/bash
#
#  Run this in an ArcGIS container to start the Portal server
#  and configure it with the default admin/password and site
#
# Environment: HOSTNAME AGP_USERNAME AGP_PASSWORD PORTAL_CONTENT

source /app/bashrc
cp /app/bashrc /home/arcgis/.bashrc

PROPERTIES=".ESRI.properties.${HOSTNAME}.${ESRI_VERSION}"

# Clumsily wipe all log files so when we start
# there will only be one.
# TODO find the current logfile instead
# amd remove only old logs
LOGDIR="/home/arcgis/portal/usr/arcgisportal/logs"
rm -rf $LOGDIR/PORTAL.LOCAL/portal/*.l??

# Well, maybe if this file is here then it's installed already?
SCRIPT="/home/arcgis/portal/framework/etc/agsportal.sh"
if [ -f $SCRIPT ]; then 
  echo "Portal for ArcGIS is already installed."
else
  echo "Installing Portal"
  cd /app/PortalForArcGIS && \
  ./Setup -m silent --verbose -l yes
fi

# Is it running already? 
if [ -f ${SCRIPT} ]; then
  echo "Restarting Portal"
  ${SCRIPT} restart
fi

PORTAL_URL="https://${HOSTNAME}:7443/arcgis/home/"
echo -n "Waiting for Portal to start.. "
sleep 10
curl --retry 6 -sS --insecure --head ${PORTAL_URL} > /tmp/apphttp
if [ $? != 0 ]; then
  echo "Portal not responding. $?"
else
  echo "okay!"
  portaldiag
fi

# Instead of spelling out all these options it is also
# possible to feed a properties file, for example see
# ~/portal/tools/createportal/createportal.properties
createportal.sh -fn Sample -ln User -u ${AGP_USERNAME} -p ${AGP_PASSWORD} -d ${PORTAL_CONTENT}
# \
#-lf /app/portal_license.json

CONFIG_STORE="/home/arcgis/portal/framework/etc/config-store-connection.json"
if [ -f $CONFIG_STORE} ]; then
  CreateAdminAccount list
else
  echo "Portal is not configured."
fi

# Site configuration is done by REST
# so really it can be done from any container
# but I am doing it here.
SERVER_URL="https://${AGE_SERVER}:6443/arcgis/"
# Is a site configured?
#if??
# I don't know how to check yet.
  echo -n "Waiting for Server ${AGE_SERVER}.. "
  curl --retry 7 -sS --insecure --head $SERVER_URL > /tmp/dshttp
  if [ $? != 0 ]; then
    echo "Server did not respond: $?"
  else
    echo "okay!"
  fi
  echo "Configuring site." 
  /app/create_new_site.py $AGE_SERVER $AGE_USERNAME $AGE_PASSWORD
#fi

echo "Try reaching me at ${PORTAL_URL}"

tail -f ${LOGDIR}/PORTAL.LOCAL/portal/*.log
