if [ $(composer global show | grep -c "hirak") -eq 0 ]
then
    composer global require "hirak/prestissimo:^0.3"
    echo "Prestissimo installed"
else
    echo "Prestissimo already installed"
fi
