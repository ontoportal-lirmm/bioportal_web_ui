# frozen_string_literal: true

require 'cgi'
require 'ostruct'
require 'json'
require 'open-uri'

class BPIDResolver
  require "#{Rails.root}/lib/resolver/acronym_from_virtual"
  require "#{Rails.root}/lib/resolver/virtual_from_acronym"
  require "#{Rails.root}/lib/resolver/virtual_from_version"

  def self.id_to_acronym(id)
    acronym_from_virtual_id(id) or acronym_from_version_id(id)
  end

  def self.acronym_to_virtual_id(acronym)
    virtual_id_from_acronym(acronym)
  end

  class << self
    private

    def acronym_from_id(id)
      acronym_from_virtual_id(id) or acronym_from_version_id(id)
    end

    def acronym_from_virtual_id(virtual_id)
      ACRONYM_FROM_VIRTUAL["old:acronym_from_virtual:#{virtual_id}"]
    end

    def acronym_from_version_id(version_id)
      virtual = virtual_id_from_version_id(version_id)
      acronym_from_virtual_id(virtual)
    end

    def virtual_id_from_version_id(version_id)
      VIRTUAL_FROM_VERSION["old:virtual_from_version:#{version_id}"]
    end

    def virtual_id_from_acronym(acronym)
      VIRTUAL_FROM_ACRONYM["old:virtual_from_acronym:#{acronym}"]
    end
  end
end
