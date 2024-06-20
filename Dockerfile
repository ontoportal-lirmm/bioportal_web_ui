# Make sure it matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.0
FROM ruby:${RUBY_VERSION}-alpine

# Install libvips for Active Storage preview support
RUN apk add --no-cache build-base \
                       libxml2-dev \
                       libxslt-dev \
                       mariadb-dev \
                       git \
                       tzdata \
                       nodejs yarn \
                       less \
                       bash \
                       docker \
                       docker-compose \
    && mkdir /node_modules

# Rails app lives here
WORKDIR /app

# Set production environment
ARG RAILS_ENV="production"
ARG BUNDLE_WITHOUT="development test"

ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_ENV="${RAILS_ENV}" \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="${BUNDLE_WITHOUT}"

RUN gem update --system 3.4.22 # the 3.4.22 can be removed if we support Ruby version > 3.0

COPY . .

RUN bundle install
RUN yarn install && yarn build



RUN cp config/bioportal_config_env.rb.sample config/bioportal_config_production.rb
RUN cp config/bioportal_config_env.rb.sample config/bioportal_config_development.rb
RUN cp config/database.yml.sample config/database.yml

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

RUN SECRET_KEY_BASE_DUMMY="1" ./bin/rails assets:precompile

ENV BINDING="0.0.0.0"
EXPOSE 3000

CMD ["bash"]