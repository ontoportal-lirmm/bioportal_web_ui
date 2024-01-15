# frozen_string_literal: true

class Display::SearchResultComponentPreview < ViewComponent::Preview


    def default()
      render Display::SearchResultComponent.new(title:'height - INRAE Thesaurus (INRAETHES)' , uri: 'http://opendata.inrae.fr/thesaurusINRAE/c_17053', text: 'Height of plant from ground to top of spike, excluding awns.')
    end
  end
  