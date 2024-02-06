# Use CentOS 7 as the base image
# Have not used this in the cf-template but on how the mediawiki can be dockerized .Tested in local and the mediawiki is up and running
FROM centos:7

WORKDIR /var/www/html
 
# Installing dependencies
RUN yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm && \
    yum -y install yum-utils && \
    yum-config-manager --enable remi-php74 && \
    yum install -y httpd php php-mysqlnd php-gd php-xml php-mbstring php-json mod_ssl php-intl php-apcu wget sudo
 
 
# Download and extract MediaWiki 1.41.0
RUN rm -rf /var/www/html/* && \
    cd /var/www/html && \
    wget --no-check-certificate https://releases.wikimedia.org/mediawiki/1.41/mediawiki-1.41.0.tar.gz && \
    tar -zxvf mediawiki-1.41.0.tar.gz --strip-components=1 && \
    rm mediawiki-1.41.0.tar.gz
 
 
# Expose port 80
EXPOSE 80
 
# Start Apache service
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
