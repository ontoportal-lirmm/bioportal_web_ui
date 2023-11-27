require "application_system_test_case"

class LoginFlowsTest < ApplicationSystemTestCase

  setup do
    @user_john = fixtures(:users)[:john]
    @user_bob = create_user(fixtures(:users)[:bob])
  end

  teardown do
    delete_user(@user_bob)
    delete_user(@user_john)
  end

  test "go to sign up page, save and see account details" do
    visit root_url
    click_on 'Login'

    click_on 'Register'

    new_user = @user_john
    delete_user(new_user)

    LinkedData::Client::Models::User.find_by_username(new_user.username).first&.delete

    fill_in 'user_firstName', with: new_user.first_name
    fill_in 'user_lastName', with: new_user.last_name
    fill_in 'user_username', with: new_user.username
    fill_in 'user_orcidId', with: new_user.orcid_id
    fill_in 'user_githubId', with: new_user.github_id
    fill_in 'user_email', with: new_user.email
    fill_in 'user_password', with: new_user.password
    fill_in 'user_password_confirmation', with: new_user.password

    # Click the save button
    click_button 'Register'


    assert_selector '.notification', text: 'Account was successfully created'

    visit root_url + '/account'

    assert_selector '.account-page-title', text:  'My account'

    assert_selector '.title', text: 'First name:'
    assert_selector '.info', text: new_user.firstName

    assert_selector '.title', text: 'Last name:'
    assert_selector '.info', text: new_user.lastName

    assert_selector '.title', text: 'Email:'
    assert_selector '.info', text: new_user.email

    assert_selector '.title', text: 'Username:'
    assert_selector '.info', text: new_user.username

    assert_selector '.title', text: 'ORCID ID:'
    assert_selector '.info', text: new_user.orcidId

    assert_selector '.title', text: 'GitHub ID:'
    assert_selector '.info', text: new_user.githubId

    assert_selector '.account-page-card-title', text: 'API Key'
    assert_selector '.account-page-card-title', text: 'Subscriptions'
    assert_selector '.account-page-card-title', text: 'Submitted Semantic Resources'
    assert_selector '.account-page-card-title', text: 'Projects Created'

  end

  test "go to login page and click save" do
    login_in_as(@user_bob)

    assert_selector '.notification', text: "Welcome #{@user_bob.username}!", wait: 10
  end
end
