while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

if [ -f "/etc/init.d/postgresql" ]; then
	apt-get purge -y postgresql-* -qq > /dev/null
	apt-get autoremove -y -qq > /dev/null
	apt-get autoclean -qq > /dev/null
  echo "postgresql removed with success"
else
  echo "postgresql already removed"
fi
