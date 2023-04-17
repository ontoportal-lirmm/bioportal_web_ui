# frozen_string_literal: true

class IssueCreatorService < ApplicationService
  class QueryError < StandardError; end

  FindRepoQuery = GitHub::Client.parse <<-'GRAPHQL'
    query ($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        id
      }
    }
  GRAPHQL

  CreateIssueMutation = GitHub::Client.parse <<-'GRAPHQL'
    mutation ($repositoryId: ID!, $title: String!, $body: String) {
      createIssue(input: {repositoryId: $repositoryId, title: $title, body: $body}) {
        issue {
          bodyText,
          createdAt,
          id,
          number,
          repository {
            nameWithOwner
          },
          title,
          url
        }
      }
    }
  GRAPHQL

  def initialize(params)
    @title = params[:content][:title]
    @body = params[:content][:body]
    @repo = Rails.configuration.change_request.dig(:ontologies, params[:ont_acronym].to_sym, :repository)
  end

  def call
    data = query(FindRepoQuery, variables: { owner: repo_owner, name: repo_name })
    data = query(CreateIssueMutation, variables: { repositoryId: data.repository.id, title: @title, body: @body })
    data.to_h.dig('createIssue', 'issue')
  end

  private

  def query(definition, variables: {})
    response = GitHub::Client.query(definition, variables: variables)
    raise QueryError, response.errors[:data].join(', ') if response.errors.any?

    response.data
  end

  def repo_name
    @repo[%r{/(.*)}, 1]
  end

  def repo_owner
    @repo[%r{(.*)/}, 1]
  end
end
