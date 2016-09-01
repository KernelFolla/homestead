while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

if [ ! $(dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get remove -y --purge mysql-server mysql-client mysql-common -qq > /dev/null
  apt-get autoremove -y -qq > /dev/null
  apt-get autoclean -qq > /dev/null

  rm -rf /var/lib/mysql
  rm -rf /var/log/mysql
  rm -rf /etc/mysql
  echo "mysql removed with success"
else
  echo "mysql already removed"
fi
