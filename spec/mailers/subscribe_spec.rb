require "rails_helper"

RSpec.describe SubscribeMailer, type: :mailer do
  
  describe "register for announce list" do
    let(:mail) { SubscribeMailer.register_for_announce_list("user@lirmm.fr","user_fn","user_ln") }

    it "renders the headers" do
      expect(mail.subject).to eq("subscribe #{$ANNOUNCE_LIST} user_fn user_ln")
      expect(mail.to).to eq([$ANNOUNCE_SERVICE_HOST])
      expect(mail.from).to eq(["user@lirmm.fr"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("")
    end

  end

  describe "unregister for announce list" do
    let(:mail) { SubscribeMailer.unregister_for_announce_list("user@lirmm.fr") }

    it "renders the headers" do
      expect(mail.subject).to eq("unsubscribe #{$ANNOUNCE_LIST}")
      expect(mail.to).to eq([$ANNOUNCE_SERVICE_HOST])
      expect(mail.from).to eq(["user@lirmm.fr"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("")
    end

  end

end
