# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  autoloader.inflector = Zeitwerk::Inflector.new
  autoloader.inflector.inflect(
    'bpid_resolver' => 'BPIDResolver',
    'kgcl' => 'KGCL'
  )
end
