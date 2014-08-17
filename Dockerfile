from debian:wheezy

run apt-get update && \
    apt-get install -y curl build-essential

run apt-get install -y ruby1.9.3
run apt-get install -y lsb-release && \
    curl -sL https://deb.nodesource.com/setup | bash
run apt-get install -y nodejs npm
run apt-get install -y nginx
run gem install bundler

add Gemfile /blog/Gemfile
workdir /blog
run bundle install -j8

add . /blog


run rake install['pageburner'] && rake generate
run rm /etc/nginx/sites-available/default
add nginx/nathanleclaire.com /etc/nginx/sites-available/nathanleclaire.com
run ln -s /etc/nginx/sites-available/nathanleclaire.com /etc/nginx/sites-enabled/nathanleclaire.com

run echo "daemon off;" >>/etc/nginx/nginx.conf

expose 80

cmd ["service", "nginx", "start"]
