from node

run apt-get update && \
    apt-get install -y curl
run curl -L https://get.rvm.io | bash
run gpasswd -a root rvm
run /etc/profile.d/rvm.sh

env PATH $PATH:/usr/local/rvm/bin

run /bin/bash -l -c "rvm install 1.9.3"
run /bin/bash -l -c "rvm use 1.9.3"
run /bin/bash -l -c "gem install bundler"

add Gemfile /blog/Gemfile
workdir /blog
run /bin/bash -l -c "bundle install -j4"
run npm install -g http-server

add . /blog

run /bin/bash -l -c "rake install['pageburner'] && rake generate"

cmd []
entrypoint ["http-server"]
