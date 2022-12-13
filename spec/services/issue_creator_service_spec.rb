# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IssueCreatorService do
  describe '#call' do
    it 'creates an issue' do
      params = { ont_acronym: 'STY', content: { title: 'test issue', body: 'lorem ipsum dolor sit amet' } }
      issue = IssueCreatorService.call(params)

      expect(issue).to have_key('id')
      expect(issue['id']).not_to be_empty
      expect(issue).to have_key('createdAt')
      expect(issue['createdAt']).not_to be_empty
      expect(issue['title']).to eq params[:content][:title]
      expect(issue['bodyText']).to eq params[:content][:body]
    end

    context 'when a query fails' do
      params = { ont_acronym: 'STY', content: { title: nil, body: 'lorem ipsum dolor sit amet' } }

      it 'raises an error' do
        expect { IssueCreatorService.call(params) }.to raise_error IssueCreatorService::QueryError
      end
    end
  end

  after :all do
    # TODO: delete test issue
    #   Currently creating test issues in a personal repository:
    #   jvendett/bioportal-nigms-u2. The kgcl-change-request user can't have
    #   access rights to delete issues in a personal repository, even when
    #   when added as a collaborator (per GitHub's documentation). Would need
    #   to move test issue creation to a repository owned by an organization.

    # DeleteIssueMutation = GitHub::Client.parse <<-'GRAPHQL'
    #   mutation ($issueId: ID!) {
    #     deleteIssue(input: {issueId: $issueId}) {
    #       repository {
    #         id
    #       }
    #     }
    #   }
    # GRAPHQL
    # response = GitHub::Client.query(DeleteIssueMutation, variables: { issueId: issue['id'] })
  end
end
