#!/usr/bin/env ruby

require 'bel'
require 'multi_json'
require 'optparse'
require 'hermann'
require 'hermann/consumer'
require 'hermann/producer'

$: << File.expand_path('../../../lib', __FILE__)
$: << File.expand_path('../lib', __FILE__)

require 'storage/redland'
require 'search/sqlite3'
require 'namespace/default'
require 'namespace/model'
require 'annotation/default'
require 'evidence-pipeline/annotation_transform'
require 'evidence-pipeline/annotation_group_transform'
require 'evidence-pipeline/namespace_transform'

options = {
  consumer: {
    kafka_broker:            "#{ENV['KAFKA_HOST']}:#{ENV['KAFKA_PORT']}",
    kafka_topic:             "#{ENV['KAFKA_TOPIC_RAW']}",
    kafka_consumer_group:    'evidence-pipeline',
    kafka_partition:         0,
    kafka_rewind:            false
  },
  producer: {
    kafka_broker:            "#{ENV['KAFKA_HOST']}:#{ENV['KAFKA_PORT']}",
    kafka_topic:             "#{ENV['KAFKA_TOPIC_PROCESSED']}",
  }
}
OptionParser.new do |opts|
  opts.banner = 'usage: evidence-pipeline.rb [KAFKA CONSUME] [KAFKA PRODUCE]'

  # Kafka options

  # consumer
  opts.on(
    '-b',
    '--consumer-kafka-broker BROKER',
    "The consumer's Kafka broker in HOST:PORT style."
  ) do |kafka_broker|
    options[:consumer][:kafka_broker] = kafka_broker
  end
  opts.on('-t', '--consumer-kafka-topic TOPIC', "The consumer's Kafka topic to pull from.") do |kafka_topic|
    options[:consumer][:kafka_topic] = kafka_topic
  end
  opts.on('-g', '--consumer-group GROUP', "The consumer's Kafka consumer group.") do |kafka_consumer_group|
    options[:consumer][:kafka_consumer_group] = kafka_consumer_group
  end
  opts.on('-p', '--consumer-partition PARTITION', "The consumer's topic partition.") do |kafka_partition|
    options[:consumer][:kafka_partition] = Integer(kafka_partition)
  end
  opts.on('-r', '--[no-]kafka-rewind', 'Start from the beginning of the consumed topic.') do |kafka_rewind|
    options[:consumer][:kafka_rewind] = kafka_rewind
  end

  opts.on(
    '-c',
    '--producer-kafka-broker BROKER',
    "The producer's Kafka broker in HOST:PORT style."
  ) do |kafka_broker|
    options[:producer][:kafka_broker] = kafka_broker
  end
  opts.on('-u', '--producer-kafka-topic TOPIC', "The producer's Kafka topic to pull from.") do |kafka_topic|
    options[:producer][:kafka_topic] = kafka_topic
  end
end.parse!

storage = OpenBEL::Storage::StorageRedland.new({
  storage: 'sqlite',
  name:    '/home/tony/projects/openbel/openbel-server/rdf_20150611.db'
})
search  = OpenBEL::Search::Sqlite3FTS.new({
  file:    '/home/tony/projects/openbel/openbel-server/rdf_20150611.db'
})
annotation_api = OpenBEL::Annotation::Annotation.new(
  storage, search
)
namespace_api  = OpenBEL::Namespace::Namespace.new(
  storage, search
)

@normalize_namespace_transform =
  OpenBEL::Transform::NamespaceTransform.new(namespace_api)
@annotation_transform =
  OpenBEL::Transform::AnnotationTransform.new(annotation_api)
@annotation_grouping_transform =
  OpenBEL::Transform::AnnotationGroupingTransform.new

consumer = Hermann::Consumer.new(
  options[:consumer][:kafka_topic], {
    brokers:   options[:consumer][:kafka_broker],
    topic:     options[:consumer][:kafka_topic],
    group_id:  options[:consumer][:kafka_consumer_group],
    partition: options[:consumer][:kafka_partition],
    offset:    options[:consumer][:kafka_rewind] ? :start : :end
  }
)
producer = Hermann::Producer.new(
  options[:producer][:kafka_topic],
  [options[:producer][:kafka_broker]]
)
producer.connect

signal_handler = lambda { |_|
  consumer.shutdown
}
trap('SIGINT',  signal_handler)
trap('SIGTERM', signal_handler)

puts "Consuming #{options[:consumer][:kafka_topic]} with configuration: "
puts "  broker:         #{options[:consumer][:kafka_broker]}"
puts "  topic:          #{options[:consumer][:kafka_topic]}"
puts "  consumer group: #{options[:consumer][:kafka_consumer_group]}"
puts "  partition:      #{options[:consumer][:kafka_partition]}"
puts "Producing #{options[:producer][:kafka_topic]} with configuration: "
puts "  broker:         #{options[:producer][:kafka_broker]}"
puts "  topic:          #{options[:producer][:kafka_topic]}"

count    = 0
base_url = 'http://localhost:8080'
consumer.consume do |msg, _key, _offset|
  event = MultiJson.load(msg, :symbolize_keys => true)
  event_obj = event[:event]
  next unless event_obj

  if event_obj[:type] == 'evidence'
    case event_obj[:action]
    when 'create', 'update'
      evidence_obj = event_obj[:data][:evidence]
      evidence     = BEL::Model::Evidence.create(evidence_obj)

      # normative namespaces
      @normalize_namespace_transform.transform_evidence!(evidence)

      # normative annotations
      @annotation_transform.transform_evidence!(evidence, base_url)
      @annotation_grouping_transform.transform_evidence!(evidence)

      event_obj[:data][:evidence] = evidence.to_h
    end

    producer.push(MultiJson.dump(event_obj))
    count += 1
  end
end

puts "consumed #{count} evidence from #{options[:consumer][:kafka_topic]}"
puts "produced #{count} evidence to #{options[:producer][:kafka_topic]}"

