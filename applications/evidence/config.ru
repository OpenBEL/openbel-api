require_relative 'app'

puts ENV.inspect

em_run(
  :server => 'thin',
  :app    => OpenBEL::Apps::Evidence.new({
    :brokers => [
      "#{ENV['KAFKA_HOST']}:#{ENV['KAFKA_PORT']}"
    ],
    :topic   => ENV['KAFKA_TOPIC_RAW']
  }),
  :port   => ENV['EV_APP_PORT']
)
