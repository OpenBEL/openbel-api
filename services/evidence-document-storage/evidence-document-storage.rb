#!/usr/bin/env ruby

require 'multi_json'
require 'optparse'
require 'hermann'
require 'hermann/consumer'
require 'hermann/discovery/metadata'

$: << File.expand_path('../../../lib', __FILE__)
$: << File.expand_path('../lib', __FILE__)

options = {
  mongo_host:              'localhost',
  mongo_port:              27017,
  mongo_database:          'openbel',
  kafka_broker:            "#{ENV['KAFKA_HOST']}:#{ENV['KAFKA_PORT']}",
  kafka_topic:             "#{ENV['KAFKA_TOPIC_RAW']}",
  kafka_consumer_group:    'evidence-document-storage',
  kafka_partition:         0,
  kafka_rewind:            false
}
OptionParser.new do |opts|
  opts.banner = 'usage: evidence-document-storage.rb [MONGO] [KAFKA]'

  # Mongo options
  opts.on('-h', '--mongo-host HOST', 'Mongo host.') do |mongo_host|
    options[:mongo_host] = mongo_host
  end
  opts.on('-p', '--mongo-port PORT', 'Mongo port.') do |mongo_port|
    options[:mongo_port] = mongo_port
  end
  opts.on('-d', '--mongo-db DB', 'Mongo database.') do |mongo_database|
    options[:mongo_database] = mongo_database
  end

  # Kafka options
  opts.on(
    '-b',
    '--kafka-broker BROKER',
    'Kafka broker in HOST:PORT style.'
  ) do |kafka_broker|
    options[:kafka_broker] = kafka_broker
  end
  opts.on('-t', '--kafka-topic TOPIC', 'Kafka topic to pull from.') do |kafka_topic|
    options[:kafka_topic] = kafka_topic
  end
  opts.on('-g', '--kafka-consumer-group GROUP', 'Kafka consumer group.') do |kafka_consumer_group|
    options[:kafka_consumer_group] = kafka_consumer_group
  end
  opts.on('-p', '--kafka-partition PARTITION', 'Kafka topic partition.') do |kafka_partition|
    options[:kafka_partition] = Integer(kafka_partition)
  end
  opts.on('-r', '--[no-]kafka-rewind', 'Start from the beginning of the topic.') do |kafka_rewind|
    options[:kafka_rewind] = kafka_rewind
  end
end.parse!

require 'evidence-mongo/mongo'

kafka_config = {
  brokers:   options[:kafka_broker],
  topic:     options[:kafka_topic],
  group_id:  options[:kafka_consumer_group],
  partition: options[:kafka_partition],
}

if options[:kafka_rewind]
  kafka_config.merge!({ offset: :start })
  evidence_storage = OpenBEL::Evidence::Evidence.new(
    :host     => options[:mongo_host],
    :port     => options[:mongo_port],
    :database => options[:mongo_database],
    :rebuild  => true
  )
else
  evidence_storage = OpenBEL::Evidence::Evidence.new(
    :host     => options[:mongo_host],
    :port     => options[:mongo_port],
    :database => options[:mongo_database]
  )
end

count = 0
consumer = Hermann::Consumer.new(options[:kafka_topic], kafka_config)

trap('SIGINT') do
  consumer.shutdown
end
trap('SIGTERM') do
  consumer.shutdown
end

puts "Listening (kafka) for #{options[:kafka_topic]} on: "
puts "  broker:         #{options[:kafka_broker]}"
puts "  topic:          #{options[:kafka_topic]}"
puts "  consumer group: #{options[:kafka_consumer_group]}"
puts "  partition:      #{options[:kafka_partition]}"

consumer.consume do |msg, _key, _offset|
  event = MultiJson.load(msg, :symbolize_keys => true)
  event_obj = event[:event]
  next unless event_obj

  if event_obj[:type] == 'evidence'
    case event_obj[:action]
    when 'create'
      evidence_storage.create_evidence(event_obj[:data][:evidence])
    when 'update'
      data = event_obj[:data]
      evidence_storage.update_evidence_by_uuid(*data.values_at(:uuid, :evidence))
    when 'delete'
      data = event_obj[:data]
      evidence_storage.delete_evidence_by_uuid(data[:uuid])
    end
    count += 1
  end
end

puts "read #{count} messages from #{options[:kafka_topic]} topic"

