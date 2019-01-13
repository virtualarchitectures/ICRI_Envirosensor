#!bin/bash
#setup script for Envirosensor platform

#Setting to GB time - This can be changed to watever time zone is required
echo "setting timezone to GB"
timedatectl set-timezone GB
echo "setting timezone to GB...complete"

#Turning off internal logging to reserve memory
echo "configuring logging..."
sed -i -e "s/\(Storage=\).*/\1none/" /etc/systemd/journald.conf
rm -rf /var/log/journal/*
echo -e "configuring logging...complete"

#Updating package management repositories
echo "updating opkg conf"
> /etc/opkg/base-feeds.conf
echo 'src/gz all http://repo.opkg.net/edison/repo/all' >> /etc/opkg/base-feeds.conf
echo 'src/gz edison http://repo.opkg.net/edison/repo/edison' >> /etc/opkg/base-feeds.conf
echo 'src/gz core2-32 http://repo.opkg.net/edison/repo/core2-32' >> /etc/opkg/base-feeds.conf
opkg update
echo -e "updating opkg conf...complete"

#Updating tar package to open tar directories
echo "upgrading tar..."
#opkg install ./tar/tar_1.27.1-r0_core2-32.ipk
opkg upgrade tar
echo -e "upgrading tar...complete"

#Installing miniconda environment to run python scripts and handle dependencies
echo "installing miniconda..."
wget http://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86.sh -O ./miniconda2.sh
bash ./miniconda2.sh -b -p $HOME/miniconda2
export PATH="$HOME/miniconda2/bin:$PATH"
rm ./miniconda2.sh
echo -e "installing miniconda...complete"

#Installing required python packages into Miniconda environment
echo "installing python packages..."
echo "installing mraa..."
$HOME/miniconda2/bin/conda install -y -c malev mraa=0.9.3
echo "installing requests..."
$HOME/miniconda2/bin/conda install -y requests  #for http requests
echo "installing configparser..."
$HOME/miniconda2/bin/conda install -y configparser  #to reference config files
source deactivate
echo -e "installing python packages...complete"

#Removing tarballs after python installs
echo "cleaning conda tarballs..."
$HOME/miniconda2/bin/conda clean --tarballs -y
echo "cleaning conda tarballs...complete"

#Create systemd service to autostart on boot
echo "installing environmental sensor service..."
cp ./service/envirosensor.sh /usr/bin/
chmod +x /usr/bin/envirosensor.sh
cp ./service/envirosensor.service /etc/systemd/system/
systemctl enable envirosensor.service
systemctl daemon-reload
echo -e "installing enviromental sensor service...complete"

#CODE FOR CONFIGURATION FILE CREATION

echo "set config parameters for envirosensor.config..."
echo "STEP 1: Please enter the six character IBM Watson Organization ID:"
echo "(found on your IBM Watson IoT Platform settings page)"
read orgID
echo "STEP 2: Please enter the IBM Watson Device Type:"
echo "(found on your IBM Watson IoT Platform devices list)"
read deviceType
echo "STEP 3: Please enter the IBM Watson Device ID:"
echo "(found on your IBM Watson IoT Platform devices list)"
read deviceID
echo "STEP 4: Please enter the device's Authentication Token:"
echo "(assigned when you first registered the device the Watson IoT Platform)"
read authToken
echo "STEP 5: Please enter the Event Type for this device:"
echo "(This is the type of event or topic that is shown in the Watson IoT Platform)"
read eventType
echo ""
echo ""

#store variables in config file
file="/home/root/envirosensor.config"
echo '[settings]' >> $file
echo 'orgID: '$orgID >> $file
echo 'deviceType: '$deviceType >> $file
echo 'deviceID: '$deviceID >> $file
echo 'authToken: '$authToken >> $file
echo 'eventType: '$eventType >> $file

echo "Thanks! config file created at $HOME/envirosensor.config"
echo ""
echo ""

echo "***************************************"
echo "Setup Complete!"
echo "***************************************"
echo "Please reboot your device to start envirosensor service"
echo ""
echo ""