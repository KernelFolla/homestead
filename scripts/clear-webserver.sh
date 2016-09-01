if [ -f /etc/init.d/nginx ];
then
  rm -f /etc/nginx/sites-enabled/*
  rm -f /etc/nginx/sites-available/*
  echo "cleared nginx websites"
fi

if [ -f /etc/init.d/apache2 ];
then
  rm -f /etc/apache2/sites-enabled/*
  rm -f /etc/apache2/sites-available/*
  echo "cleared apache websites"
fi
