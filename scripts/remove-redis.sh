while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

if [ -f "/etc/init/redis-server.conf" ]; then
	apt-get purge -y redis-server -qq > /dev/null
	apt-get autoremove -y -qq > /dev/null
  echo "redis removed with success"
else
  echo "redis already removed"
fi
