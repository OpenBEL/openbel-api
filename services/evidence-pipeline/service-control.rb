require 'daemons'

Daemons.run('evidence-pipeline.rb',
  :app_name => 'evidence-pipeline',
  :mode     => :exec,
  :monitor  => true,
  :multiple => true,
)
