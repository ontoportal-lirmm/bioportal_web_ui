require 'rails_helper'

RSpec.describe Notifier, type: :mailer do
  let(:support_email) { 'agroportal-support@lirmm.fr' }
  let(:site) { 'Agroportal' }

  describe 'error' do
    let(:error) { StandardError.new('Test error message') }
    subject(:error_mail) { Notifier.error(error) }

    it 'sends an error email' do
      expect(error_mail.to).to eq([support_email])
      expect(error_mail.from).to eq([support_email])
      expect(error_mail.subject).to eq("[#{site}] Exception Mailer: #{error.message}")
      expect(error_mail.body.encoded).to include(error.backtrace.join("\n"))
    end
  end

  describe 'feedback' do
    let(:name) { 'John Doe' }
    let(:email) { 'user@lirmm.fr' }
    let(:comment) { 'This is a test comment.' }
    let(:location) { 'Test Location' }
    let(:tags) { 'tag1, tag2' }

    subject(:feedback_mail) { Notifier.feedback(name, email, comment, location, tags) }

    it 'sends a feedback email' do
      expect(feedback_mail.to).to eq(["#{support_email}, #{email}"])
      expect(feedback_mail.from).to eq([support_email])
      expect(feedback_mail.subject).to eq("[#{site}] Feedback from #{name}")
      expect(feedback_mail.body.encoded).to include(name, email, comment, location, tags)
    end
  end
end
