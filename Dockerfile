FROM ruby:latest

RUN gem update --system && gem install bundler

WORKDIR /code

RUN mkdir -p /code/lib/mindex

COPY Gemfile .
COPY mindex.gemspec .
COPY lib/mindex/version.rb /code/lib/mindex

RUN bundle install

ADD . /code

CMD ["bundle", "exec", "rspec"]
