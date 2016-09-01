while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

if [ -f /etc/init.d/apache2 ]
then
    echo "apache already installed."
    exit 0
fi

# remove nginx
if [ -f "/etc/init.d/nginx" ];  then
    apt-get purge -y nginx -qq > /dev/null
    apt-get autoremove -y -qq > /dev/null
    rm /etc/init.d/nginx
    echo "nginx removed with success."
else
    echo "nginx already removed"
fi

apt-get install -y apache2 -qq > /dev/null

a2enmod rewrite > /dev/null
a2enmod headers > /dev/null
a2enconf php7.0-fpm > /dev/null
a2enmod proxy_fcgi > /dev/null

service apache2 restart

echo "apache installed with success."
