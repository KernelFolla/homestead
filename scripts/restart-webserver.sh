if [ -f /etc/init.d/nginx ];
then
  service nginx restart
  echo "nginx restarted"
fi

if [ -f /etc/init.d/apache2 ];
then
  service apache2 restart
  echo "apache restarted"
fi

service php7.0-fpm restart
echo "php7.0-fpm restarted"
