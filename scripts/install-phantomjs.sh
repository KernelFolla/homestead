while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

# Check If Maria Has Been Installed
if [ ! $(dpkg-query -W -f='${Status}' mongodb-org 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
    echo "MongoDB already installed."
    exit 0
fi

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

fuser -k /var/lib/dpkg/lock /var/lib/apt/lists/lock
apt-get update -qq

apt-get install -y mongodb-org -qq  > /dev/null

block="
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target

[Service]
User=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target
"
echo "$block" > "/etc/systemd/system/mongodb.service"
systemctl daemon-reload
systemctl start mongodb
systemctl enable mongodb

echo "MongoDB installed with success."
