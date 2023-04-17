# frozen_string_literal: true

require_relative '../../config/initializers/graphql_client'

namespace :schema do
  desc 'Update GitHub GraphQL schema'
  task :update do
    GraphQL::Client.dump_schema(GitHub::HTTPAdapter, 'data/schema.json')
  end
end
