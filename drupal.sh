#!/bin/bash -e

main() {
    export LC_ALL=C.UTF-8
    sudo add-apt-repository ppa:ondrej/php
    sudo apt-get update
    echo "Installing Drupal Dependencies"
    sudo apt-get install -y vim curl nginx  php7.2-fpm php7.2-common php7.2-mysql php7.2-xml php7.2-xmlrpc \
    php7.2-curl php7.2-gd php7.2-imagick php7.2-cli php7.2-dev php7.2-imap php7.2-mbstring php7.2-opcache \
    php7.2-soap php7.2-zip dialog apt-utils -y
    echo "Copy Drupal Site Configuration"
    sudo cp -pR $HOME/conf/php5/php.ini /etc/php/7.2/fpm/php.ini
    sudo rm /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    sudo cp -pR $HOME/conf/custom-nginx.conf /etc/nginx/sites-available/drupal8
    echo "Installing Database"
    export DEBIAN_FRONTEND=noninteractive
    sudo -E apt-get -q -y install mysql-server-5.7
    sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Lgs0nybelkinm@x';"
    echo "Creating User 'drupaluser' and Database 'drupaldb' for drupal"
    sudo mysql -u root -p'Lgs0nybelkinm@x' -e "CREATE DATABASE drupaldb;"
    sudo mysql -u root -p'Lgs0nybelkinm@x' -e "create user drupaluser@localhost identified by 'drupaluser@';"
    sudo mysql -u root -p'Lgs0nybelkinm@x' -e "grant all privileges on drupaldb.* to drupaluser@localhost identified by 'drupaluser@';"
    sudo mysql -u root -p'Lgs0nybelkinm@x' -e "flush privileges;"
    echo "Creating Self Signed SSL Certificates"
    sudo mkdir -p /etc/nginx/ssl && cd /etc/nginx/ssl
    sudo openssl req -x509 -nodes -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=packerworld.tk" -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/drupal.key -out /etc/nginx/ssl/drupal.crt
    sudo chmod 600 /etc/nginx/ssl/drupal.key
    sudo mkdir -p /var/www/drupal8
    echo "Installing Drupal Site Validation"
    sudo ln -s /etc/nginx/sites-available/drupal8 /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo php-fpm7.2 -t 
    echo "Sarting Services..."
    sudo systemctl restart nginx && sudo service php7.2-fpm restart
    echo "Installing Drush and Composer"
    sudo apt install curl git unzip drush -y
    sudo curl -sS https://getcomposer.org/installer -o composer-setup.php
    export HASH=544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061
    #echo "Validating the Composer"
    #sudo php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    echo "Downloading Sample Drupal8"
    cd /var/www/drupal8 && sudo git clone --single-branch --branch 8.0.x http://git.drupal.org/project/drupal.git 
    echo "Configuring Drupal Setup"
    sudo  mv drupal/* /var/www/drupal8/ &&\
    cd sites/default && sudo cp default.settings.php settings.php && \
    sudo cp default.services.yml services.yml && sudo mkdir files/ && \
    sudo chmod a+w * && sudo chmod 777 settings.php services.yml
}

main