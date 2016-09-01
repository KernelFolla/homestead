while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

if [ -f "/etc/init.d/nginx" ];  then
    apt-get purge -y nginx -qq > /dev/null
    apt-get autoremove -y -qq > /dev/null
		apt-get autoclean -qq > /dev/null
    rm /etc/init.d/nginx
    echo "nginx removed with success."
else
    echo "nginx already removed"
fi
