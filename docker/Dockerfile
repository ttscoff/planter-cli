FROM ruby:3.0.1
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN mkdir /planter
WORKDIR /planter

RUN gem install bundler:2.2.17
RUN apt-get update -y
RUN apt-get install -y less vim
COPY ./docker/inputrc /root/.inputrc
COPY ./docker/bash_profile /root/.bash_profile
RUN mkdir -p /root/.config/planter/templates/test
CMD ["scripts/runtests.sh"]
