while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

if [ -f /etc/init.d/nginx ]
then
    echo "nginx already installed."
    exit 0
fi

if [ -f "/etc/init.d/apache2" ];  then
    apt-get purge -y apache2 -qq
    apt-get autoremove -y -qq
    rm /etc/init.d/apache2
    echo "apache removed with success."
else
    echo "apache already removed"
fi

apt-get install -y nginx -qq
service nginx restart
echo "nginx installed with success."
