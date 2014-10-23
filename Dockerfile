# widget quux

from debian:wheezy

run apt-get update && \
    apt-get install -y curl build-essential

run apt-get install -y ruby1.9.3
run apt-get install -y lsb-release && \
    curl -sL https://deb.nodesource.com/setup | bash
run apt-get install -y nodejs npm
run gem install bundler

add Gemfile /blog/Gemfile
workdir /blog
run bundle install -j16

add . /blog
run rake install['pageburner'] && rake generate
cmd ["bash"]
