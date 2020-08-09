#!/bin/bash -e
source $HOME/drupal/.env
main() {
    sudo add-apt-repository ppa:ondrej/php
    sudo apt-get update
    echo "Installing Drupal-${DRUPAL_VERSION} Dependencies"
    sudo apt-get install -y vim curl nginx  php${PHP_FPM_VERSION}-fpm php${PHP_FPM_VERSION}-common php${PHP_FPM_VERSION}-mysql php${PHP_FPM_VERSION}-xml php${PHP_FPM_VERSION}-xmlrpc \
    php${PHP_FPM_VERSION}-curl php${PHP_FPM_VERSION}-gd php${PHP_FPM_VERSION}-imagick php${PHP_FPM_VERSION}-cli php${PHP_FPM_VERSION}-dev php${PHP_FPM_VERSION}-imap php${PHP_FPM_VERSION}-mbstring php${PHP_FPM_VERSION}-opcache \
    php${PHP_FPM_VERSION}-soap php${PHP_FPM_VERSION}-zip apt-utils -y
    echo "Copy Drupal-${DRUPAL_VERSION} Site Configuration"
    sudo cp -pR ${WORKING_DIR}/conf/php/php.ini /etc/php/${PHP_FPM_VERSION}/fpm/php.ini
    sudo rm /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    sudo cp -pR ${WORKING_DIR}/conf/nginx/custom-phpfpmsock-nonssl.conf /etc/nginx/sites-available/drupal
    sudo ln -s /etc/nginx/sites-available/drupal /etc/nginx/sites-enabled/
    echo "Installing Database"
    sudo -E apt-get -q -y install mysql-server-${MYSQL_SERVER_VERSION}
    sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';"
    echo "Creating User '${DRUPAL_USER}' and Database '${DRUPAL_DATABASE}' for drupal"
    sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE ${DRUPAL_DATABASE};"
    sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "create user ${DRUPAL_USER}@localhost identified by '${DRUPAL_PASSWORD}';"
    sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "grant all privileges on ${DRUPAL_DATABASE}.* to ${DRUPAL_USER}@localhost identified by '${DRUPAL_PASSWORD}';"
    sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "flush privileges;"
    echo "Creating Self Signed SSL Certificates"
    sudo mkdir -p /etc/nginx/ssl && cd /etc/nginx/ssl
    sudo openssl req -x509 -nodes -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${DOMAIN_NAME}" -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/drupal.key -out /etc/nginx/ssl/drupal.crt
    sudo chmod 600 /etc/nginx/ssl/drupal.key
    echo "Nginx and PHP-FPM Configuration validation.."
    sudo nginx -t
    sudo php-fpm${PHP_FPM_VERSION} -tt
    echo "Sarting Services..."
    sudo systemctl restart nginx && sudo service php${PHP_FPM_VERSION}-fpm restart
    echo "Installing Drush and Composer"
    sudo apt install curl git unzip drush -y
    sudo curl -sS https://getcomposer.org/installer -o composer-setup.php
    #echo "Validating the Composer"
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    echo "Downloading Sample Drupal-${DRUPAL_VERSION}"
    sudo mkdir -p /var/www/drupal
    cd /var/www/drupal && sudo git clone --single-branch --branch ${DRUPAL_VERSION} http://git.drupal.org/project/drupal.git 
    echo "Configuring Drupal-${DRUPAL_VERSION} Setup"
    sudo  mv drupal/* /var/www/drupal/ &&\
    cd sites/default && sudo cp default.settings.php settings.php && \
    sudo cp default.services.yml services.yml && sudo mkdir files/ && \
    sudo chmod a+w * && sudo chmod 777 settings.php services.yml
    sudo  chown -R ${DRUPAL_SSH_USER}.${DRUPAL_SSH_USER} /var/www/drupal && \
    sudo chown -R ${DRUPAL_SSH_USER}.${DRUPAL_SSH_USER} /run && \
    sudo chown -R ${DRUPAL_SSH_USER}.${DRUPAL_SSH_USER} /var/lib/nginx && \
    sudo chown -R ${DRUPAL_SSH_USER}.${DRUPAL_SSH_USER} /var/log/nginx
}

main