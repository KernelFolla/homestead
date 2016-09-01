while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done
export DEBIAN_FRONTEND=noninteractive

if [ ! $(dpkg-query -W -f='${Status}' postgresql 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
    echo "postgresql already installed."
    exit 0
fi

apt-get install -y postgresql -qq > /dev/null

# Configure Postgres Remote Access
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.5/main/postgresql.conf > /dev/null
echo "host    all             all             10.0.2.2/32               md5" | tee -a /etc/postgresql/9.5/main/pg_hba.conf > /dev/null
sudo -u postgres psql -c "CREATE ROLE homestead LOGIN UNENCRYPTED PASSWORD 'secret' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;" > /dev/null
sudo -u postgres /usr/bin/createdb --echo --owner=homestead homestead > /dev/null
service postgresql restart

echo "postgresql installed with success."
