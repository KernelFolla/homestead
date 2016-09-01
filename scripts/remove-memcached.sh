while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

if [ -f "/etc/init.d/memcached" ]; then
	apt-get purge -y memcached > /dev/null
	apt-get autoremove -y -qq > /dev/null
	apt-get autoclean -qq > /dev/null
  echo "memcached removed with success"
else
  echo "memcached already removed"
fi
