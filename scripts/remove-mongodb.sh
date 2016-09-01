while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
	echo "Waiting for other software managers to finish..."
	sleep 2
done
export DEBIAN_FRONTEND=noninteractive

if [ ! $(dpkg-query -W -f='${Status}' mongodb-org 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get remove -y --purge mongodb-org -qq > /dev/null
  apt-get autoremove -y -qq > /dev/null
  apt-get autoclean -qq > /dev/null

  echo "MongoDB removed with success"
else
  echo "MongoDB already removed"
fi
