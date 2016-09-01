while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done

if [ ! $(dpkg-query -W -f='${Status}' mariadb-server 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get remove -y --purge mariadb-server -qq > /dev/null
  apt-get autoremove -y -qq > /dev/null
  apt-get autoclean -qq > /dev/null

  rm -rf /var/lib/mysql
  rm -rf /var/log/mysql
  rm -rf /etc/mysql
  echo "mariadb removed with success"
else
  echo "mariadb already removed"
fi
