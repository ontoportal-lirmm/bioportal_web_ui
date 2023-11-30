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

  test "go admin page and create an agent person and edit it" do
    visit admin_index_url
    click_on "Persons & organizations"
    wait_for_text "Create New Agent"

    # Creation test
    create_agent_flow(@new_person, person_count: 1, organization_count: 2)

    # Edition test
    @new_person2 = fixtures(:agents)[:agent2]
    wait_for_text  @new_person.name
    edit_link = find("a[data-show-modal-title-value=\"Edit agent #{@new_person.name}\"]")
    @new_person2.id = edit_link['href'].split('/')[-2]
    edit_link.click

    edit_agent_flow(@new_person2, person_count: 1, organization_count: 3)

  end

  test "go admin page and create an agent organization and edit it" do
    visit admin_index_url
    click_on "Persons & organizations"

    # Creation test
    create_agent_flow(@new_organization, person_count: 0, organization_count: 3)

    # Edition test
    @new_organization2 = fixtures(:agents)[:organization2]
    wait_for_text  @new_organization.name
    edit_link = find("a[data-show-modal-title-value=\"Edit agent #{@new_organization.name}\"]")
    @new_organization2.id = edit_link['href'].split('/')[-2]
    edit_link.click

    edit_agent_flow(@new_organization2, person_count: 0, organization_count: 5)
  end


  private
  def create_agent_flow(new_agent, person_count: , organization_count:)
    wait_for_text "Create New Agent"

    # Creation test
    click_on "Create New Agent"
    wait_for_text "TYPE"
    agent_fill(new_agent)
    sleep 1
    assert_text "New Agent added successfully"
    find('.close').click
    within "table#adminAgents" do
      assert_selector '.human',  count: person_count + organization_count #  all created  agents
      assert_text new_agent.name
      new_agent.identifiers.map{|x| "https://orcid.org/#{x["notation"]}"}.each do |orcid|
        assert_text orcid
      end

      assert_text 'person', count: person_count
      assert_text 'organization', count: organization_count

      new_agent.affiliations.map do |aff|
        aff["identifiers"] = aff["identifiers"].each{|x| x["schemaAgency"] = 'ORCID'}
        assert_text display_agent(OpenStruct.new(aff), link: false)
      end
    end
  end

  def edit_agent_flow(agent, person_count: , organization_count: )
    wait_for_text "TYPE"
    agent_fill(agent, parent_id: agent.id)
    # assert_text "New Agent added successfully"
    find('.close').click
    within "table#adminAgents" do
      assert_selector '.human',  count: person_count + organization_count # all created  agents
      assert_text agent.name
      agent.identifiers.map{|x| "https://orcid.org/#{x["notation"]}"}.each do |orcid|
        assert_text orcid
      end
      assert_text 'person', count: person_count
      assert_text 'organization', count: organization_count

      agent.affiliations.map do |aff|
        aff["identifiers"] = aff["identifiers"].each{|x| x["schemaAgency"] = 'ORCID'}
        assert_text display_agent(OpenStruct.new(aff), link: false)
      end
    end
  end
end
