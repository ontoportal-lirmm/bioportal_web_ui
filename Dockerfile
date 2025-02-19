# Make sure it matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=2.7.8
FROM ruby:${RUBY_VERSION}-alpine

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
                       cmake \
                       g++ \
                       make \
                       libc6-compat \
                       libstdc++ \
                       ruby-dev \
                       libffi-dev \
                       openssl-dev \
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

# Update RubyGems and Bundler
RUN gem update --system 3.4.22 && \
    gem install bundler:2.4.22

# Copy Gemfile and Gemfile.lock first
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle config set --local build.nokogiri --use-system-libraries && \
    bundle install --jobs 4 --retry 3

# Copy the rest of the application
COPY . .

# Install yarn packages and build
RUN yarn install && yarn build

# Copy configuration files
RUN cp config/bioportal_config_env.rb.sample config/bioportal_config_production.rb && \
    cp config/bioportal_config_env.rb.sample config/bioportal_config_development.rb && \
    cp config/database.yml.sample config/database.yml

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY="1" ./bin/rails assets:precompile

ENV BINDING="0.0.0.0"
EXPOSE 3000

CMD ["bash"]
