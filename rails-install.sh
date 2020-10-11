# Install rbenv
echo $NEWPASS | sudo -S apt update
echo $NEWPASS | sudo -S apt install -y libssl-dev libreadline-dev zlib1g-dev build-essential curl nodejs yarn libsqlite3-dev sqlite3
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
source ~/.bash_profile

# Get ruby and bundler
rbenv install 2.7.2
rbenv global 2.7.2
gem install bundler
rbenv rehash

curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

gem update --system --no-ri --no-rdoc
gem install rails
