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

    login_in_as(@logged_user)
  end

  teardown do
    delete_user(@user_bob)
    delete_user(@logged_user)
    delete_ontologies([@new_ontology])
    delete_groups
    delete_categories
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

    @new_ontology.group.each do |group|
      assert_text group.name
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
  end

  test "click on button edit submission and change all the fields and save" do
    submission_2 = fixtures(:submissions)[:submission2]
    ontology_2 = fixtures(:ontologies)[:ontology2]
    create_ontology(@new_ontology, @new_submission)
    visit ontology_path(@new_ontology.acronym)

    # click edit button
    find("a.rounded-button[href=\"#{edit_ontology_path(@new_ontology.acronym)}\"]").click

    # General tab
    wait_for_text 'Acronym'

    assert_text 'Acronym'
    assert_selector 'input[name="ontology[acronym]"][disabled="disabled"]'
    fill_in 'ontology[name]', with: ontology_2.name
    tom_select 'submission[hasOntologyLanguage]', submission_2.hasOntologyLanguage

    selected_categories = @categories[3..4]
    selected_groups = Array(@groups[2])

    list_checks selected_categories.map(&:acronym), @categories.map(&:acronym)
    list_checks selected_groups.map(&:acronym), @groups.map(&:acronym)

    tom_select 'ontology[administeredBy][]', [@user_bob.username]

    fill_in 'submission[URI]', with: submission_2.URI
    fill_in 'submission[versionIRI]', with: submission_2.versionIRI
    fill_in 'submission[version]', with: submission_2.version
    tom_select 'submission[status]', submission_2.status

    # TODO test deprecated

    tom_select 'submission[hasFormalityLevel]', submission_2.hasFormalityLevel
    tom_select 'submission[hasOntologySyntax]', submission_2.hasOntologySyntax
    tom_select 'submission[naturalLanguage][]', submission_2.naturalLanguage
    tom_select 'submission[isOfType]', submission_2.isOfType

    list_inputs "#submissionidentifier_from_group_input",
                "submission[identifier]",
                submission_2.identifier




    # Description tab
    click_on "Description"
    wait_for_text "Description"

    fill_in 'submission[description]', with: submission_2.description
    fill_in 'submission[abstract]', with: submission_2.abstract
    fill_in 'submission[homepage]', with: submission_2.homepage
    fill_in 'submission[documentation]', with: submission_2.documentation

    list_inputs "#submissionnotes_from_group_input",
                "submission[notes]", submission_2.notes

    list_inputs "#submissionkeywords_from_group_input",
                "submission[keywords]", submission_2.keywords

    list_inputs "#submissionhiddenLabel_from_group_input",
                "submission[hiddenLabel]", submission_2.hiddenLabel

    list_inputs "#submissionalternative_from_group_input",
                "submission[alternative]", submission_2.alternative

    list_inputs "#submissionpublication_from_group_input",
                "submission[publication]", submission_2.publication


    # Dates tab
    click_on "Dates"
    wait_for_text "Submission date"

    date_picker_fill_in 'submission[released]', submission_2.released
    date_picker_fill_in 'submission[valid]', submission_2.valid
    #date_picker_fill_in 'submission[curatedOn]', submission_2.valid TODO fix curatedOn
    date_picker_fill_in 'submission[creationDate]', submission_2.creationDate
    date_picker_fill_in 'submission[modificationDate]', submission_2.modificationDate


    # Licencing tab
    click_on "Licensing"
    wait_for_text "Visibility"

    tom_select 'ontology[viewingRestriction]', ontology_2.viewingRestriction
    tom_select 'submission[hasLicense]', 'CC Attribution 3.0'
    fill_in 'submission[useGuidelines]', with: submission_2.useGuidelines
    fill_in 'submission[morePermissions]',with:  submission_2.morePermissions
    # search_input
    # Persons and organizations tab
    click_on "Persons and organizations"
    sleep 1
    # TODO agents test

    # Links tab
    click_on "Links"
    wait_for_text "Location"

    choose 'submission[isRemote]', option: '1'
    fill_in 'submission[pullLocation]', with: submission_2.pullLocation
    list_inputs "#submissionsource_from_group_input",
                "submission[source]", submission_2.source
    list_inputs "#submissionendpoint_from_group_input",
                "submission[endpoint]", submission_2.endpoint
    #tom_select 'submission[includedInDataCatalog][]', submission_2.includedInDataCatalog #TODO

    # Media tab
    click_on "Media"
    wait_for_text "Depiction"

    list_inputs "#submissionassociatedMedia_from_group_input",
                "submission[associatedMedia]", submission_2.associatedMedia

    list_inputs "#submissiondepiction_from_group_input",
                "submission[depiction]", submission_2.depiction

    fill_in 'submission[logo]', with: submission_2.logo

    # Community tab
    click_on "Community"
    wait_for_text "Audience"

    fill_in 'submission[audience]',  with: submission_2.audience
    fill_in 'submission[repository]',  with: submission_2.repository
    fill_in 'submission[bugDatabase]',  with: submission_2.bugDatabase
    fill_in 'submission[mailingList]',  with: submission_2.mailingList

    list_inputs "#submissiontoDoList_from_group_input",
                "submission[toDoList]", submission_2.toDoList
    list_inputs "#submissionaward_from_group_input",
                "submission[award]", submission_2.award

    # Usage tab
    click_on "Usage"
    wait_for_text "Known usage"
    list_inputs "#submissionknownUsage_from_group_input",
                "submission[knownUsage]", submission_2.knownUsage

    tom_select 'submission[designedForOntologyTask][]', submission_2.designedForOntologyTask

    list_inputs "#submissionhasDomain_from_group_input",
                "submission[hasDomain]", submission_2.hasDomain

    fill_in 'submission[coverage]',  with: submission_2.coverage

    list_inputs "#submissionexample_from_group_input",
                  "submission[example]", submission_2.example

    # Relation tab
    click_on "Relation"
    wait_for_text "Prior version"

    # TODO ontology view check in

    fill_in "submission[hasPriorVersion]", with: submission_2.hasPriorVersion
    relations = [:hasPart, :ontologyRelatedTo, :similarTo, :comesFromTheSameDomain,
                 :isAlignedTo, :isBackwardCompatibleWith, :isIncompatibleWith,
                 :hasDisparateModelling, :hasDisjunctionsWith, :generalizes]

    relations.each do |key|
      list_inputs "#submission#{key}_from_group_input",
                  "submission[#{key}]", 2.times.map{|id| "https://#{key}.2.#{id}.com"}
    end

    # Content tab
    click_on "Content"
    wait_for_text "Root of obsolete branch"

    fill_in "submission[obsoleteParent]", with: submission_2.obsoleteParent
    fill_in "submission[uriRegexPattern]", with: submission_2.uriRegexPattern
    fill_in "submission[preferredNamespaceUri]", with: submission_2.preferredNamespaceUri
    fill_in "submission[preferredNamespacePrefix]", with: submission_2.preferredNamespacePrefix
    fill_in "submission[exampleIdentifier]", with: submission_2.exampleIdentifier
    list_inputs "#submissionkeyClasses_from_group_input",
                "submission[keyClasses]", submission_2.keyClasses
    tom_select "submission[metadataVoc][]", submission_2.metadataVoc

    # Methodology tab
    click_on "Methodology"
    wait_for_text "Knowledge representation paradigm"

    fill_in "submission[conformsToKnowledgeRepresentationParadigm]", with: submission_2.conformsToKnowledgeRepresentationParadigm
    fill_in "submission[usedOntologyEngineeringMethodology]", with: submission_2.usedOntologyEngineeringMethodology
    tom_select "submission[usedOntologyEngineeringTool][]", submission_2.usedOntologyEngineeringTool

    list_inputs "#submissionaccrualMethod_from_group_input",
                  "submission[accrualMethod]", submission_2.accrualMethod

    tom_select "submission[accrualPeriodicity]", submission_2.accrualPeriodicity

    fill_in "submission[accrualPolicy]", with: submission_2.accrualPolicy

    [:competencyQuestion, :wasGeneratedBy, :wasInvalidatedBy].each do |key|
      list_inputs "#submission#{key}_from_group_input",
                  "submission[#{key}]", 2.times.map{|i| "#{key}-#{i}"}
    end


    click_button 'save-button'
    #sleep 60
    wait_for '.notification', 10
    assert_selector '.notification', text: "Submission updated successfully"
    assert_text "#{ontology_2.name} (#{@new_ontology.acronym})"

    selected_categories.each do |cat|
      assert_text cat.name
    end

    selected_groups.each do |group|
      assert_text group.name
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

    submission_2.alternative.each do |alt|
      assert_text alt
    end

    submission_2.hiddenLabel.each do |alt|
      assert_text alt
    end


    open_dropdown "#dates"
    assert_date submission_2.released
    assert_date submission_2.valid
    # assert_date submission_2.curatedOn # TODO fix
    assert_date submission_2.creationDate
    assert_date submission_2.modificationDate

    # Assert media
    open_dropdown "#link"
    submission_2.associatedMedia.each do |media|
      assert_text media
    end

    submission_2.depiction.map do |d|
      assert_selector "img[src=\"#{d}\"]"
    end

    assert_selector "img[src=\"#{submission_2.logo}\"]"

    # Assert links
    assert_selector "a[href=\"#{submission_2.repository}\"]"

    assert_text submission_2.bugDatabase
    assert_text submission_2.mailingList



    # Assert usage
    open_dropdown "#projects_section"
    usage_properties = [
      :coverage, :knownUsage,
      :hasDomain, :example,
      :award
    ]
    usage_properties.each do |property|
      Array(submission_2[property]).each { |v|  assert_text v} # check
    end

    submission_2.designedForOntologyTask.each do |task|
      assert_text task.delete(' ') # TODO fix in the UI the disaply of taskes
    end

    # Assert relations
    # TODO test hasPriorVersion, not showed in summary page
    # TODO tests the relations

    # Assert Content
    # TODO fix configuration tests
    #open_dropdown "#configuration"
    #assert_text submission_2.obsoleteParent # check
    assert_text submission_2.uriRegexPattern
    assert_text submission_2.exampleIdentifier

    submission_2.metadataVoc.each do |voc|
      assert_text voc
    end

    assert_text submission_2.preferredNamespaceUri
    assert_text submission_2.preferredNamespacePrefix

    submission_2.keyClasses.each do |key|
      assert_text key
    end

    # Assert Methodology
    open_dropdown "#methodology"
    methodology_properties = [
      :conformsToKnowledgeRepresentationParadigm,
      :usedOntologyEngineeringMethodology,
      :accrualPolicy,
      :toDoList,
      :notes,
    ]

    methodology_properties.each do |key|
      Array(submission_2[key]).map{|x| assert_text x}
    end

    [:competencyQuestion, :wasGeneratedBy, :wasInvalidatedBy].each do |key|
      2.times.map{|i| assert_text "#{key}-#{i}" }
    end

    assert_text submission_2.accrualPeriodicity.split('/').last.downcase
  end


  private
  def open_dropdown(target)
    find(".dropdown-container .dropdown-title-bar[data-target=\"#{target}\"]").click
    sleep 1
  end
end