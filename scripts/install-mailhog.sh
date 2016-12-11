#!/usr/bin/env bash

if [ -f /usr/local/bin/mhsendmail ]
then
    echo "mailhog already installed."
    exit 0
else
    echo "installing mailhog"

    # Download binary from github
    wget --quiet -O /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v0.2.1/MailHog_linux_amd64
    wget --quiet -O /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64

    # Make it executable
    chmod +x /usr/local/bin/mailhog
    chmod +x /usr/local/bin/mhsendmail

    # Make it start on reboot
    tee /etc/systemd/system/mailhog.service <<EOL
[Unit]
Description=MailHog Service
After=network.service vagrant.mount

[Service]
Type=simple
ExecStart=/usr/bin/env /usr/local/bin/mailhog > /dev/null 2>&1 &

[Install]
WantedBy=multi-user.target
EOL

    tee /usr/sbin/sendmail <<EOL
#!/bin/sh

theargs=""

for an_arg in "\$@" ; do
   if [ "-t" != "\${an_arg}" ] && [ "-i" != "\${an_arg}" ] ; then
     theargs="\${theargs} \${an_arg}"
   fi
done

/usr/local/bin/mhsendmail \${theargs}
EOL

    chmod +x /usr/sbin/sendmail

    # Start on reboot
    sudo systemctl enable mailhog

    # Start background service now
    sudo systemctl start mailhog
    echo "mailhog installed"
fi