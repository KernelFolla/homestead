while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

if [ -f "/etc/init.d/beanstalkd" ];  then
	apt-get purge -y beanstalkd > /dev/null
	apt-get autoremove -y -qq > /dev/null
	apt-get autoclean -qq > /dev/null
  echo "beanstalkd removed with success"
else
  echo "beanstalkd already removed"
fi
