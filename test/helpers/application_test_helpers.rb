require 'rails/test_help'
module ApplicationTestHelpers
  module Users
    def sign_in_as(username)
      user = fixtures(:users)[username]
      logged_in_user = LinkedData::Client::Models::User.authenticate(user.username, user.password)
      if logged_in_user && !logged_in_user.errors
        logged_in_user = create_user(user)
      end
      session[:user] = logged_in_user
    end

    def create_user(user)
      unless (existent_user = LinkedData::Client::Models::User.find_by_username(user.username).first)
        existent_user = LinkedData::Client::Models::User.new(values: user.to_h).save
      end

      existent_user.password = user.password
      existent_user
    end

    def delete_user(user)
      LinkedData::Client::Models::User.find_by_username(user.username).first&.delete
    end
  end


  module Ontologies
    def create_ontology(ontology)
      LinkedData::Client::Models::Ontology.new(values: ontology.to_h).save
    end
  end

  module Categories
    def create_category(category)
      created = LinkedData::Client::Models::Category.new(values: category.to_h).save
      return category if created.errors
      created
    end
  end

  module Groups
    def create_group(group)
      created = LinkedData::Client::Models::Group.new(values: group.to_h).save
      return group if created.errors
      created
    end
  end
end