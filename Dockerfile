FROM ruby:3.1-alpine

WORKDIR /app

COPY Gemfile Gemfile.lock /app/

RUN bundle install
COPY . /app

ENTRYPOINT ["./exe/jiva_hr_tools"]
CMD []
