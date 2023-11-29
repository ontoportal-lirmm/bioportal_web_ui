require "application_system_test_case"

class SubmissionFlowsTest < ApplicationSystemTestCase

  setup do
    @logged_user = fixtures(:users)[:john]
    @user_bob = fixtures(:users)[:bob]
    @new_ontology = fixtures(:ontologies)[:ontology1]
    @new_submission = fixtures(:submissions)[:submission1]
    teardown
    @groups = create_groups
    @categories = create_categories
    @user_bob = create_user(@user_bob)
    @new_ontology[:administeredBy] = [@logged_user.username, @user_bob.username]
    @new_ontology[:hasDomain] = @categories[0..3]
    @new_ontology[:group] = @groups[0..3]
    @new_submission[:isRemote] = '1'

    login_in_as(@logged_user, admin: true)
  end

  teardown do
    delete_user(@user_bob)
    delete_user(@logged_user)
    delete_ontologies([@new_ontology])
    delete_groups
    delete_categories
    delete_agents
  end

  test "create a new ontology and go to it's summary page" do
    visit new_ontology_url

    assert_selector ".Upload-ontology-title > div", text: 'Submit new ontology', wait: 10

    within 'form#ontologyForm' do
      # Page 1
      fill_in 'ontology[name]', with: @new_ontology.name
      fill_in 'ontology[acronym]', with: @new_ontology.acronym

      tom_select 'ontology[viewingRestriction]', @new_ontology.viewingRestriction
      tom_select 'ontology[administeredBy][]', @new_ontology.administeredBy

      @new_ontology.hasDomain.each do |cat|
        check cat.acronym, allow_label_click: true
      end

      @new_ontology.group.each do |group|
        check group.acronym, allow_label_click: true
      end

      click_button 'Next'

      # Page 2

      fill_in 'submission[URI]', with: @new_submission.URI
      fill_in 'submission[description]', with: @new_submission.description

      tom_select 'submission[hasOntologyLanguage]', @new_submission.hasOntologyLanguage
      tom_select 'submission[status]', @new_submission.status

      choose 'submission[isRemote]', option: @new_submission.isRemote
      fill_in 'submission[pullLocation]', with: @new_submission.pullLocation

      click_button 'Next'

      # Page 3
      date_picker_fill_in 'submission[released]', @new_submission.released

      @new_submission.contact.each do |contact|
        all("[name^='submission[contact]'][name$='[name]']").last.set(contact["name"])
        all("[name^='submission[contact]'][name$='[email]']").last.set(contact["email"])
        find('.add-another-object', text: 'Add another contact').click
      end

      click_button 'Finish'
    end

    assert_selector 'h2', text: 'Ontology submitted successfully!'
    click_on current_url.gsub("/ontologies/success/#{@new_ontology.acronym}", '') + ontology_path(@new_ontology.acronym)

    assert_text "#{@new_ontology.name} (#{@new_ontology.acronym})"
    assert_selector '.alert-message', text: "The ontology is processing."

    @new_ontology.hasDomain.each do |cat|
      assert_text cat.name
    end


    assert_text @new_submission.URI
    assert_text @new_submission.description
    assert_text @new_submission.pullLocation
    assert_date @new_submission.released

    # check
    assert_selector '.fas.fa-key' if @new_submission.status.eql?('private')

    # check
    assert_selector '.chip_button_container.chip_button_small', text: @new_submission.hasOntologyLanguage

    @new_submission.contact.each do |contact|
      assert_text contact["name"]
      assert_text contact["email"]
    end

    # Assert relations
    open_dropdown "#community"

    @new_ontology.group.each do |group|
      assert_text group.name
    end




  end

  test "click on button edit submission and change all the fields and save" do
    submission_2 = fixtures(:submissions)[:submission2]
    ontology_2 = fixtures(:ontologies)[:ontology2]
    create_ontology(@new_ontology, @new_submission)
    visit ontology_path(@new_ontology.acronym)

    # click edit button
    find("a.rounded-button[href=\"#{edit_ontology_path(@new_ontology.acronym)}\"]").click
    sleep 1

    selected_categories = @categories[3..4]
    selected_groups = Array(@groups[2])

    within 'form#ontology_submission_form' do

      # General tab
      submission_general_edit_fill(ontology_2, submission_2,
                                   selected_groups: selected_groups,
                                   selected_categories: selected_categories)
      # Description tab
      click_on "Description"
      submission_description_edit_fill(submission_2)

      # Dates tab
      click_on "Dates"
      submission_date_edit_fill(submission_2)

      # Licencing tab
      click_on "Licensing"
      submission_licensing_edit_fill(ontology_2, submission_2)


      # Persons and organizations tab
      click_on "Persons and organizations"
      submission_agent_edit_fill(submission_2)

      # Links tab
      click_on "Links"
      submission_links_edit_fill(submission_2)
      # Media tab
      click_on "Media"
      submission_media_edit_fill(submission_2)

      # Community tab
      click_on "Community"
      submission_community_edit_fill(submission_2)

      # Usage tab
      click_on "Usage"
      submission_usage_edit_fill(submission_2)

      # Relation tab
      click_on "Relation"
      submission_relations_edit_fill(submission_2)

      # Content tab
      click_on "Content"
      submission_content_edit_fill(submission_2)

      # Methodology tab
      click_on "Methodology"
      submission_methodology_fill(submission_2)

      click_button 'save-button'
    end
    sleep 1
    wait_for '.notification'
    assert_selector '.notification', text: "Submission updated successfully"
    assert_text "#{ontology_2.name} (#{@new_ontology.acronym})"

    selected_categories.each do |cat|
      assert_text cat.name
    end

    assert_text submission_2.URI
    assert_text submission_2.versionIRI
    assert_selector '#submission-status', text: submission_2.version
    assert_selector ".flag-icon-fr" # todo fix this
    submission_2.identifier.each do |id|
      assert_text id
    end

    assert_text submission_2.description

    submission_2.keywords.each do |key|
      assert_text key
    end

    assert_selector "a[href=\"#{submission_2.homepage}\"]"
    assert_selector "a[href=\"#{submission_2.documentation}\"]"
    assert_selector "a[href=\"#{Array(submission_2.publication).last}\"]" # TODO the publication display is an array can't be an Icon
    assert_text submission_2.abstract

    open_dropdown "#dates"
    assert_date submission_2.released
    assert_date submission_2.valid
    submission_2.curatedOn.each do |date|
      assert_date date
    end
    assert_date submission_2.creationDate
    assert_date submission_2.modificationDate

    # Assert media
    open_dropdown "#link"
    # associatedMedia not displayed for now
    # submission_2.associatedMedia.each do |media|
    #  assert_text media
    # end

    submission_2.depiction.map do |d|
      assert_selector "img[src=\"#{d}\"]"
    end

    assert_selector "img[src=\"#{submission_2.logo}\"]"

    # Assert links
    assert_selector "a[href=\"#{submission_2.repository}\"]"

    # Assert persons and organizations
    open_dropdown "#person_and_organization"

    agent1 = fixtures(:agents)[:agent1]
    agent2 = fixtures(:agents)[:agent2]

    assert_text agent1.name, count: 3
    assert_text agent2.name, count: 3

    # Assert usage
    open_dropdown "#projects_section"
    usage_properties = [
      :coverage, :knownUsage,
      :hasDomain, :example
    ]
    usage_properties.each do |property|
      Array(submission_2[property]).each { |v| assert_text v } # check
    end

    submission_2.designedForOntologyTask.each do |task|
      assert_text task.delete(' ') # TODO fix in the UI the disaply of taskes
    end

    # Assert Methodology
    open_dropdown "#methodology"
    methodology_properties = [
      :conformsToKnowledgeRepresentationParadigm,
      :usedOntologyEngineeringMethodology,
      :accrualPolicy
    ]

    methodology_properties.each do |key|
      Array(submission_2[key]).map { |x| assert_text x }
    end

    [:competencyQuestion, :wasGeneratedBy, :wasInvalidatedBy].each do |key|
      2.times.map { |i| assert_text "#{key}-#{i}" }
    end

    assert_text submission_2.accrualPeriodicity.split('/').last.downcase

    # Assert Community
    open_dropdown "#community"
    assert_text submission_2.bugDatabase
    assert_text submission_2.mailingList
    [:toDoList, :notes, :award].each do |key|
      Array(submission_2[key]).map { |x| assert_text x }
    end

    selected_groups.each do |group|
      assert_text group.name
    end

    # Assert Content
    open_dropdown "#content"
    assert_text submission_2.obsoleteParent
    assert_text submission_2.exampleIdentifier
    assert_text submission_2.uriRegexPattern
    assert_text submission_2.preferredNamespaceUri
    assert_text submission_2.preferredNamespacePrefix

    submission_2.metadataVoc.each do |voc|
      assert_text voc
    end

    open_dropdown "#configuration"

    submission_2.keyClasses.each do |key|
      assert_text key
    end

    # Assert relations
    click_on "See all metadata"
    sleep 1
    within "#application_modal_content" do
      wait_for 'input[type="search"]'
      find('input').set('hasPriorVersion')
      assert_text submission_2.hasPriorVersion

      submission_2.alternative.each do |alt|
        find('input').set('alternative')
        assert_text alt
      end

      submission_2.hiddenLabel.each do |alt|
        find('input').set('hiddenLabel')
        assert_text alt
      end

      relations = [:hasPart, :ontologyRelatedTo, :similarTo, :comesFromTheSameDomain,
                   :isAlignedTo, :isBackwardCompatibleWith, :isIncompatibleWith,
                   :hasDisparateModelling, :hasDisjunctionsWith, :generalizes,
                   :explanationEvolution, :useImports,
                   :usedBy, :workTranslation, :translationOfWork
      ]
      relations.each do |key|
        find('input').set(key)
        2.times.each { |id| assert_text "https://#{key}.2.#{id}.com" }
      end
    end

  end

  private

  def submission_general_edit_fill(ontology, submission, selected_categories:, selected_groups:)
    wait_for_text 'Acronym'

    assert_text 'Acronym'
    assert_selector 'input[name="ontology[acronym]"][disabled="disabled"]'
    fill_in 'ontology[name]', with: ontology.name
    tom_select 'submission[hasOntologyLanguage]', submission.hasOntologyLanguage

    list_checks selected_categories.map(&:acronym), @categories.map(&:acronym)
    list_checks selected_groups.map(&:acronym), @groups.map(&:acronym)

    tom_select 'ontology[administeredBy][]', [@user_bob.username]

    fill_in 'submission[URI]', with: submission.URI
    fill_in 'submission[versionIRI]', with: submission.versionIRI
    fill_in 'submission[version]', with: submission.version
    tom_select 'submission[status]', submission.status

    # TODO test deprecated

    tom_select 'submission[hasFormalityLevel]', submission.hasFormalityLevel
    tom_select 'submission[hasOntologySyntax]', submission.hasOntologySyntax
    tom_select 'submission[naturalLanguage][]', submission.naturalLanguage
    tom_select 'submission[isOfType]', submission.isOfType

    list_inputs "#submissionidentifier_from_group_input",
                "submission[identifier]",
                submission.identifier
  end

  def submission_description_edit_fill(submission)
    wait_for '[name="submission[description]"]'

    fill_in 'submission[description]', with: submission.description
    fill_in 'submission[abstract]', with: submission.abstract
    fill_in 'submission[homepage]', with: submission.homepage
    fill_in 'submission[documentation]', with: submission.documentation

    list_inputs "#submissionnotes_from_group_input",
                "submission[notes]", submission.notes

    list_inputs "#submissionkeywords_from_group_input",
                "submission[keywords]", submission.keywords

    list_inputs "#submissionhiddenLabel_from_group_input",
                "submission[hiddenLabel]", submission.hiddenLabel

    list_inputs "#submissionalternative_from_group_input",
                "submission[alternative]", submission.alternative

    list_inputs "#submissionpublication_from_group_input",
                "submission[publication]", submission.publication

  end

  def submission_date_edit_fill(submission)
    wait_for_text "Submission date"

    date_picker_fill_in 'submission[released]', submission.released
    date_picker_fill_in 'submission[valid]', submission.valid
    list_inputs "#submissioncuratedOn_from_group_input",
                "submission[curatedOn]", submission.curatedOn do |selector, value, index|
      date_picker_fill_in selector, value, index + 1
    end

    date_picker_fill_in 'submission[creationDate]', submission.creationDate
    date_picker_fill_in 'submission[modificationDate]', submission.modificationDate

  end

  def submission_licensing_edit_fill(ontology, submission)
    wait_for_text "Visibility"

    tom_select 'ontology[viewingRestriction]', ontology.viewingRestriction
    tom_select 'submission[hasLicense]', 'CC Attribution 3.0'
    fill_in 'submission[useGuidelines]', with: submission.useGuidelines
    fill_in 'submission[morePermissions]', with: submission.morePermissions

    within "#submissioncopyrightHolder_from_group_input" do
      new_agent = fixtures(:agents)[:agent1]
      agent_id = agent_search(new_agent.name)
      agent_fill(new_agent, parent_id: agent_id)
    end

  end

  def submission_agent_edit_fill(submission)
    # TODO use list_inputs
    submission.contact.each do |contact|
      all("[name^='submission[contact]'][name$='[name]']").last.set(contact["name"])
      all("[name^='submission[contact]'][name$='[email]']").last.set(contact["email"])
      find('.add-another-object', text: 'Add another contact').click
    end

    agent1 = fixtures(:agents)[:agent1]
    agent2 = fixtures(:agents)[:agent2]

    [:hasCreator, :hasContributor, :curatedBy].each do |key|
      list_inputs "#submission#{key}_from_group_input", "submission[#{key}]", [agent1, agent2] do |selector, value, index|
        element = all("turbo-frame:last-of-type").last
        within element do
          agent_id = agent_search(value.name)
          agent_fill(value, parent_id: agent_id) if agent_id
        end
      end
    end

    # TODO agents test
  end

  def submission_links_edit_fill(submission)
    wait_for_text "Location"

    choose 'submission[isRemote]', option: '1'
    fill_in 'submission[pullLocation]', with: submission.pullLocation
    list_inputs "#submissionsource_from_group_input",
                "submission[source]", submission.source
    list_inputs "#submissionendpoint_from_group_input",
                "submission[endpoint]", submission.endpoint
    tom_select 'submission[includedInDataCatalog][]', submission.includedInDataCatalog
  end

  def submission_media_edit_fill(submission)
    wait_for_text "Depiction"

    list_inputs "#submissionassociatedMedia_from_group_input",
                "submission[associatedMedia]", submission.associatedMedia

    list_inputs "#submissiondepiction_from_group_input",
                "submission[depiction]", submission.depiction

    fill_in 'submission[logo]', with: submission.logo
  end

  def submission_community_edit_fill(submission)
    wait_for_text "Audience"

    fill_in 'submission[audience]', with: submission.audience
    fill_in 'submission[repository]', with: submission.repository
    fill_in 'submission[bugDatabase]', with: submission.bugDatabase
    fill_in 'submission[mailingList]', with: submission.mailingList

    list_inputs "#submissiontoDoList_from_group_input",
                "submission[toDoList]", submission.toDoList
    list_inputs "#submissionaward_from_group_input",
                "submission[award]", submission.award

  end

  def submission_usage_edit_fill(submission)
    wait_for_text "Known usage"
    list_inputs "#submissionknownUsage_from_group_input",
                "submission[knownUsage]", submission.knownUsage

    tom_select 'submission[designedForOntologyTask][]', submission.designedForOntologyTask

    list_inputs "#submissionhasDomain_from_group_input",
                "submission[hasDomain]", submission.hasDomain

    fill_in 'submission[coverage]', with: submission.coverage

    list_inputs "#submissionexample_from_group_input",
                "submission[example]", submission.example
  end

  def submission_content_edit_fill(submission)
    wait_for_text "Root of obsolete branch"

    fill_in "submission[obsoleteParent]", with: submission.obsoleteParent
    fill_in "submission[uriRegexPattern]", with: submission.uriRegexPattern
    fill_in "submission[preferredNamespaceUri]", with: submission.preferredNamespaceUri
    fill_in "submission[preferredNamespacePrefix]", with: submission.preferredNamespacePrefix
    fill_in "submission[exampleIdentifier]", with: submission.exampleIdentifier
    list_inputs "#submissionkeyClasses_from_group_input",
                "submission[keyClasses]", submission.keyClasses
    tom_select "submission[metadataVoc][]", submission.metadataVoc

  end

  def submission_relations_edit_fill(submission)
    wait_for_text "Prior version"

    # TODO ontology view check in

    fill_in "submission[hasPriorVersion]", with: submission.hasPriorVersion
    relations = [:hasPart, :ontologyRelatedTo, :similarTo, :comesFromTheSameDomain,
                 :isAlignedTo, :isBackwardCompatibleWith, :isIncompatibleWith,
                 :hasDisparateModelling, :hasDisjunctionsWith, :generalizes,
                 :explanationEvolution, :useImports,
                 :usedBy, :workTranslation, :translationOfWork
    ]

    relations.each do |key|
      tom_select "submission[#{key}][]", 2.times.map { |id| "https://#{key}.2.#{id}.com" }, open_to_add: true
    end
  end

  def submission_methodology_fill(submission)
    wait_for_text "Knowledge representation paradigm"

    fill_in "submission[conformsToKnowledgeRepresentationParadigm]", with: submission.conformsToKnowledgeRepresentationParadigm
    fill_in "submission[usedOntologyEngineeringMethodology]", with: submission.usedOntologyEngineeringMethodology
    tom_select "submission[usedOntologyEngineeringTool][]", submission.usedOntologyEngineeringTool

    list_inputs "#submissionaccrualMethod_from_group_input",
                "submission[accrualMethod]", submission.accrualMethod

    tom_select "submission[accrualPeriodicity]", submission.accrualPeriodicity

    fill_in "submission[accrualPolicy]", with: submission.accrualPolicy

    [:competencyQuestion, :wasGeneratedBy, :wasInvalidatedBy].each do |key|
      list_inputs "#submission#{key}_from_group_input",
                  "submission[#{key}]", 2.times.map { |i| "#{key}-#{i}" }
    end
  end

  def open_dropdown(target)
    find(".dropdown-container .dropdown-title-bar[data-target=\"#{target}\"]").click
    sleep 1
  end
end