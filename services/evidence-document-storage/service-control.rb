require 'daemons'

Daemons.run('evidence-document-storage.rb',
  :app_name => 'evidence-document-storage',
  :mode     => :exec,
  :monitor  => true,
  :multiple => true,
)
