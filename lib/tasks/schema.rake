# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

namespace :schema do
  desc 'Update GitHub GraphQL schema'
  task :update do
    http_adapter = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
      def headers(_context)
        { 'Authorization': "Bearer #{Rails.application.credentials[:kgcl][:github_access_token]}" }
      end
    end

    GraphQL::Client.dump_schema(http_adapter, 'data/schema.json')
  end
end
