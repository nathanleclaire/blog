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
run rm -r /usr/share/nginx/www
run cp -r public /usr/share/nginx/www
run echo "daemon off;" >>/etc/nginx/nginx.conf

expose 80

cmd ["service", "nginx", "start"]
