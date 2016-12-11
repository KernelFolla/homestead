if [ $(dpkg-query -W -f='${Status}' yarn 2>/dev/null | grep -c "ok installed") -eq 0 ]
then
    echo "Yarn installed"
    apt-key adv --keyserver pgp.mit.edu --recv 9D41F3C3
    echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
    apt-get update && apt-get install -y yarn
else
    echo "Yarn already installed"
fi
