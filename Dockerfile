FROM ruby:alpine

gem install webgen && webgen generate
