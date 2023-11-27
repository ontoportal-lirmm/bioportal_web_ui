require "application_system_test_case"

class SubmissionFlowsTest < ApplicationSystemTestCase

  setup do

    @logged_user = fixtures(:users)[:john]
    @user_bob = fixtures(:users)[:bob]
    @new_ontology = fixtures(:ontologies)[:ontology1]
    @new_submission = fixtures(:submissions)[:submission1]

    login_in_as(@logged_user)
    @groups = []
    fixtures(:groups).to_a.each do |name, group|
      @groups << create_group(group)
    end

    @categories = []
    fixtures(:categories).to_a.each do |name, category|
      @categories << create_category(category)
    end
  end

  teardown do
    @groups.each {|g| g.delete}
    @categories.each {|c| c.delete}
    LinkedData::Client::Models::Ontology.find_by_acronym(@new_ontology.acronym).first&.delete
  end


  test "create a new ontology and go to it's summary page" do
    visit new_ontology_url

    assert_selector ".Upload-ontology-title > div", text: 'Submit new ontology', wait: 10
    selected_categories = @categories[0..3]
    selected_groups = @groups[0..3]

    within 'form#ontologyForm' do
      # Page 1
      fill_in 'ontology[name]', with: @new_ontology.name
      fill_in 'ontology[acronym]', with: @new_ontology.acronym

      tom_select 'ontology[viewingRestriction]', @new_ontology.viewingRestriction
      tom_select 'ontology[administeredBy][]', [ @logged_user.username, @user_bob.username]


      selected_categories.each do |cat|
        check cat.acronym, allow_label_click: true
      end

      selected_groups.each do |group|
        check group.acronym, allow_label_click: true
      end

      click_button 'Next'

      # Page 2

      fill_in 'submission[URI]', with: @new_submission.URI
      fill_in 'submission[description]', with: @new_submission.description

      tom_select 'submission[hasOntologyLanguage]', @new_submission.hasOntologyLanguage
      tom_select 'submission[status]', @new_submission.status

      choose 'submission[isRemote]', option: '1'
      fill_in 'submission[pullLocation]', with: @new_submission.pullLocation


      click_button 'Next'

      # Page 3
      date_picker_fill_in 'submission[released]', @new_submission.released


      @new_submission.contact.each do |name, email|
        all("[name^='submission[contact]'][name$='[name]']").last.set(name)
        all("[name^='submission[contact]'][name$='[email]']").last.set(email)
        find('.add-another-object', text: 'Add another contact').click
      end

      click_button 'Finish'
    end

    assert_selector 'h2', text: 'Ontology submitted successfully!'
    click_on current_url.gsub("/ontologies/success/#{@new_ontology.acronym}", '') + ontology_path(@new_ontology.acronym)

    assert_text "#{@new_ontology.name} (#{@new_ontology.acronym})"
    assert_selector '.alert-message', text: "The ontology is processing."

    selected_categories.each do |cat|
      assert_text cat.name
    end

    selected_groups.each do |group|
      assert_text group.name
    end

    assert_text @new_submission.URI
    assert_text @new_submission.description
    assert_text @new_submission.pullLocation
    assert_text I18n.l(DateTime.parse(@new_submission.released), format: '%B %-d, %Y')

    # TODO: status and hasOntologyLanguage are displayed in summary page

    @new_submission.contact.each do |name, email|
      assert_text name
      assert_text email
    end

  end

end