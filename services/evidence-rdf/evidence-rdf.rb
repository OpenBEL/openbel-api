#!/usr/bin/env ruby

require 'bel'
require 'multi_json'
require 'optparse'
require 'hermann'
require 'hermann/consumer'
require 'hermann/producer'

require 'rdf'

$: << File.expand_path('../../../lib', __FILE__)
$: << File.expand_path('../lib', __FILE__)

options = {
  consumer: {
    kafka_broker:            "#{ENV['KAFKA_HOST']}:#{ENV['KAFKA_PORT']}",
    kafka_topic:             "#{ENV['KAFKA_TOPIC_PROCESSED']}",
    kafka_consumer_group:    'evidence-rdf',
    kafka_partition:         0,
    kafka_rewind:            false
  },
  producer: {
    kafka_broker:            "#{ENV['KAFKA_HOST']}:#{ENV['KAFKA_PORT']}",
    kafka_topic:             "#{ENV['KAFKA_TOPIC_RDF']}",
  }
}
OptionParser.new do |opts|
  opts.banner = 'usage: evidence-rdf.rb [KAFKA CONSUME] [KAFKA PRODUCE]'

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

count      = 0
writer     = StringIO.new
namespaces = Hash[
  DEFAULT_NAMESPACES.map { |ns|
    [ns.prefix, ns]
  }
]

consumer.consume do |msg, _key, _offset|
  event = MultiJson.load(msg, :symbolize_keys => true)
  event_obj = event[:event]
  next unless event_obj

  if event_obj[:type] == 'evidence'
    data             = event_obj[:data]
    uuid             = data[:uuid]
    evidence_context = RDF::URI.new("http://www.openbel.org/bel/evidence/#{uuid}")

    case event_obj[:action]
    when 'create', 'update'
      evidence_obj  = data[:evidence]
      bel_statement = evidence_obj[:bel_statement]

      bel_statement = BEL::Script.parse(
        evidence_obj[:bel_statement], namespaces
      ).select { |x|
        x.is_a?(BEL::Model::Statement)
      }.first

      rdf_quads = RDF::NQuads::Writer.buffer do |writer|
        bel_statement.to_rdf[1].each do |trpl|
          writer.write_statement(
            RDF::Statement(
              *trpl,
              :context => evidence_context
            )
          )
        end
      end

      producer.push rdf_quads
    end

    count += 1
  end
end

puts "consumed #{count} evidence from #{options[:consumer][:kafka_topic]}"
puts "produced #{count} evidence to #{options[:producer][:kafka_topic]}"

