require "application_system_test_case"

class AgentFlowsTest < ApplicationSystemTestCase
  include AgentHelper

  setup do
    @logged_user = fixtures(:users)[:john]
    @new_person = fixtures(:agents)[:agent1]
    @new_organization = fixtures(:agents)[:organization1]
    login_in_as(@logged_user, admin: true)
  end

  def teardown
    delete_agents
    delete_user(@logged_user)
  end

  test "go admin page and create an agent person" do
    visit admin_index_url
    click_on "Persons & organizations"
    wait_for_text "Create New Agent"
    click_on "Create New Agent"
    wait_for_text "TYPE"
    agent_fill(@new_person)
    assert_text "New Agent added successfully"
    find('.close').click
    within "table#adminAgents" do
      assert_selector '.human',  count: 3 # created 3 agents
      assert_text @new_person.name
      @new_person.identifiers.map{|x| "https://orcid.org/#{x["notation"]}"}.each do |orcid|
        assert_text orcid
      end
      assert_text @new_person.agentType, count: 1
      assert_text 'organization', count: 2

      @new_person.affiliations.map do |aff|
        aff["identifiers"] = aff["identifiers"].each{|x| x["schemaAgency"] = 'ORCID'}
        assert_text display_agent(OpenStruct.new(aff), link: false)
      end
    end
  end

  test "go admin page and create an agent organization" do
    visit admin_index_url
    click_on "Persons & organizations"
    wait_for_text "Create New Agent"
    click_on "Create New Agent"
    wait_for_text "TYPE"
    agent_fill(@new_organization)
    assert_text "New Agent added successfully"
    find('.close').click
    within "table#adminAgents" do
      assert_selector '.human',  count: 3 # created 3 agents
      assert_text @new_organization.name
      @new_organization.identifiers.map{|x| "https://orcid.org/#{x["notation"]}"}.each do |orcid|
        assert_text orcid
      end
      assert_text @new_organization.agentType, count: 3

      @new_organization.affiliations.map do |aff|
        aff["identifiers"] = aff["identifiers"].each{|x| x["schemaAgency"] = 'ORCID'}
        assert_text display_agent(OpenStruct.new(aff), link: false)
      end
    end
  end
end
