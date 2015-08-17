require_relative 'app'

em_run(
  :server => 'thin',
  :app    => OpenBEL::Apps::Evidence.new,
  :port   => ENV['EV_APP_PORT']
)
