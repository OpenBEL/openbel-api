require 'daemons'

Daemons.run('evidence-rdf.rb',
  :app_name => 'evidence-rdf',
  :mode     => :exec,
  :monitor  => true,
  :multiple => true,
)
