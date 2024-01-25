# frozen_string_literal: true

$SITE = 'Testportal'
$HOSTNAME = 'testportal'
$UI_HOSTNAME = 'localhost'
$UI_URL = "http://#{$UI_HOSTNAME}:3000"

$API_KEY = ENV['API_KEY']
$REST_URL = ENV['API_URL']
$BIOMIXER_URL = ENV['BIOMIXER_URL']
$ANNOTATOR_URL = $PROXY_URL = ENV['ANNOTATOR_URL']
$FAIRNESS_URL = ENV['FAIRNESS_URL']

# config/initializers/omniauth_providers.rb
$OMNIAUTH_PROVIDERS = {
  github: {
    client_id: 'CLIENT_ID',
    client_secret: 'CLIENT_SECRET',
    icon: 'github.svg',
    enable: true
  },
  google: {
    strategy: :google_oauth2,
    client_id: 'CLIENT_ID',
    client_secret: 'CLIENT_SECRET',
    icon: 'google.svg',
    enable: true
  },
  orcid: {
    client_id: 'CLIENT_SECRET',
    client_secret: 'CLIENT_SECRET',
    icon: 'orcid.svg',
    enable: false
  },
  keycloak: {
    strategy: :keycloak_openid,
    client_id: 'YOUR_KEYCLOAK_CLIENT_ID',
    client_secret: 'YOUR_KEYCLOAK_CLIENT_SECRET',
    client_options: { site: 'KEYCLOAK_SITE', realm: 'KEYCLOAK_REALM' },
    name: 'keycloak',
    icon: 'keycloak.svg',
    enable: false
  }
}.freeze

$INTERPORTAL_HASH = {}

# If your BioPortal installation includes Fairness score set this to true
$FAIRNESS_DISABLED = false

# Pairing a name with an array of ontology virtual ids will allow you to filter ontologies based on a subdomain.
# If your main UI is hosted at example.org and you add custom.example.org pointing to the same Rails installation
# you could filter the ontologies visible at custom.example.org by adding this to the hash: "custom" => { :name => "Custom Slice", :ontologies => [1032, 1054, 1099] }
# Any number of slices can be added. Groups are added automatically using the group acronym as the subdomain.
$ENABLE_SLICES = true
$ONTOLOGY_SLICES = {}

# Cube metrics reporting
$ENABLE_CUBE = false

$NOT_DOWNLOADABLE = {}
# Enable client request caching
$CLIENT_REQUEST_CACHING = true

# If you don't use Airbrake you can have exceptions emailed to the $ERROR_EMAIL address by setting this to 'true'
$EMAIL_EXCEPTIONS = false

# Announcements mailman mailing list REQUEST address, EX: list-request@lists.example.org
# NOTE: You must use the REQUEST address for the mailing list. ONLY WORKS WITH MAILMAN LISTS.
$ANNOUNCE_LIST ||= 'appliance-users-request@localhost'

# Email addresses used for sending notifications (errors, feedback, support)
$SUPPORT_EMAIL ||= 'support@localhost'
$ADMIN_EMAIL ||= 'admin@localhost'
$ERROR_EMAIL ||= 'errors@localhost'

# Custom BioPortal logging
require 'log'
$REMOTE_LOGGING = false

##
# Custom Ontology Details
# Custom details can be added on a per ontology basis using a key/value pair as columns of the details table
#
# Example:
# $ADDITIONAL_ONTOLOGY_DETAILS = { 1000 => { "Additional Detail" => "Text to be shown in the right-hand column." } }
##
$ADDITIONAL_ONTOLOGY_DETAILS = {}

# Site notice appears on all pages and remains closed indefinitely. Stored below as a hash with a unique key and a
#  EX: $SITE_NOTICE = { :unique_key => 'Put your message here (can include <a href="/link">html</a> if you use
$SITE_NOTICE = {}
################################
## AUTO-GENERATED DO NOT MODIFY
#################################

# Full string for site, EX: "NCBO BioPortal"
$ORG_SITE = $ORG.nil? || $ORG.empty? ? $SITE : "#{$ORG} #{$SITE}"

$HOME_PAGE_LOGOS = [
  {
    img_src: 'logos/supports/numev.png',
    url: 'http://www.lirmm.fr/numev',
    target: '_blank'
  },
  {
    img_src: 'logos/supports/anr.png',
    url: 'https://anr.fr/en',
    target: '_blank'
  },
  {
    img_src: 'logos/supports/eu.png',
    url: 'https://commission.europa.eu/research-and-innovation_en',
    target: '_blank'
  },
  {
    img_src: 'logos/collaboration/d2kab.png',
    url: 'http://d2kab.mystrikingly.com',
    target: '_blank'
  },
  {
    img_src: 'logos/collaboration/lirmm.png',
    url: 'http://www.lirmm.fr',
    target: '_blank'
  },
  {
    img_src: 'logos/collaboration/inrae.png',
    url: 'https://www.inrae.fr/enm',
    target: '_blank'
  },
  {
    img_src: 'logos/collaboration/stanford.png',
    url: 'https://www.stanford.edu',
    target: '_blank'
  }
]

$FOOTER_LINKS = {
  social: [
    { logo: 'social/people.svg', link: 'https://github.com/orgs/agroportal/people' },
    { logo: 'social/github.svg', link: 'https://github.com/agroportal' },
    { logo: 'social/twitter.svg', link: 'https://twitter.com/lagroportal' }
  ],
  sections: {
    products: {
      ontoportal: 'https://ontoportal.org/',
      release_notes: 'https://doc.jonquetlab.lirmm.fr/share/e6158eda-c109-4385-852c-51a42de9a412/doc/release-notes-btKjZk5tU2',
      api: 'https://data.agroportal.lirmm.fr/',
      sparql: 'https://sparql.agroportal.lirmm.fr/test/'
    },
    support: {
      contact_us: 'https://agroportal.lirmm.fr/feedback',
      wiki: 'https://www.bioontology.org/wiki/',
      documentation: 'https://ontoportal.github.io/documentation/'
    },
    agreements: {
      terms: '',
      privacy_policy: '',
      cite_us: '',
      acknowledgments: ''
    },
    about: {
      about_us: 'https://github.com/agroportal/project-management',
      projects: 'https://d2kab.mystrikingly.com/',
      team: 'https://github.com/orgs/agroportal/people'
    }
  }
}

$UI_THEME = :stageportal
if File.exist?('config/bioportal_config_development_testportal.lirmm.fr.rb')
  require_relative 'bioportal_config_development_testportal.lirmm.fr' # local credentials
end
