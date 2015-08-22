package org.openbel.service.knowledge_graph;

import kafka.consumer.ConsumerConfig;
import kafka.consumer.ConsumerIterator;
import kafka.consumer.KafkaStream;
import kafka.javaapi.consumer.ConsumerConnector;
import kafka.message.MessageAndMetadata;
import org.apache.jena.atlas.lib.Sink;
import org.apache.jena.graph.Triple;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.riot.out.SinkTripleOutput;
import org.apache.jena.riot.system.SyntaxLabels;
import org.apache.jena.tdb.sys.SystemTDB;
import org.apache.jena.update.UpdateExecutionFactory;
import org.apache.jena.update.UpdateProcessor;
import org.apache.jena.update.UpdateRequest;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static java.lang.String.format;

public class EvidenceRDFConsumerGroup {
    private final ConsumerConnector consumer;
    private final String topic;
    private final AtomicInteger msgCount;
    private ExecutorService executor;

    public EvidenceRDFConsumerGroup(String a_zookeeper, String a_groupId, String a_topic, AtomicInteger msgCount) {
        consumer      = kafka.consumer.Consumer.createJavaConsumerConnector(
                createConsumerConfig(a_zookeeper, a_groupId));

        this.topic    = a_topic;
        this.msgCount = msgCount;
    }

    public void shutdown() {
        if (consumer != null) consumer.shutdown();
        if (executor != null) executor.shutdown();
        try {
            if (!executor.awaitTermination(5000, TimeUnit.MILLISECONDS)) {
                System.out.println("Timed out waiting for consumer threads to shut down, exiting uncleanly");
            }
        } catch (InterruptedException e) {
            System.out.println("Interrupted during shutdown, exiting uncleanly");
        }
    }

    public void run(int a_numThreads) {
        Map<String, Integer> topicCountMap = new HashMap<>();
        topicCountMap.put(topic, a_numThreads);
        Map<String, List<KafkaStream<byte[], byte[]>>> consumerMap = consumer.createMessageStreams(topicCountMap);
        List<KafkaStream<byte[], byte[]>> streams = consumerMap.get(topic);

        // now launch all the threads
        //
        System.out.println(format("Setting up thread pool of size %d.", a_numThreads));
        executor = Executors.newFixedThreadPool(a_numThreads);

        // now create an object to consume the messages
        //
        int threadNumber = 0;
        StringBuilder queryBuilder = new StringBuilder();
        InputStream sparqlResourceStream = getClass().getResourceAsStream("/upsert-graph.sparql");
        String graphTemplate = new Scanner(sparqlResourceStream, "UTF-8").useDelimiter("\\A").next();
        for (final KafkaStream stream : streams) {
            executor.submit(() -> {
                int batchSize = 40;
                int countInBatch = 0;
                ConsumerIterator<byte[], byte[]> iterator = stream.iterator();
                while(iterator.hasNext()) {
                    MessageAndMetadata<byte[], byte[]> msg = iterator.next();

                    ByteArrayInputStream quadsMessageBytes = new ByteArrayInputStream(msg.message());

                    ByteArrayOutputStream byteStream = new ByteArrayOutputStream();
                    Sink<Triple> captureTriples = new SinkTripleOutput(byteStream, null, SyntaxLabels.createNodeToLabel());
                    GraphCapture rdfProcessor = new GraphCapture(captureTriples);

                    RDFDataMgr.parse(rdfProcessor, quadsMessageBytes, Lang.NQUADS);

                    String graphSparql = graphTemplate.
                            replace("$GRAPH_URI", rdfProcessor.getGraphContextNode().getURI()).
                            replace("$TRIPLES", byteStream.toString());
                    queryBuilder.append(graphSparql);
                    countInBatch++;

                    if (countInBatch == batchSize) {
                        UpdateRequest updateRequest = new UpdateRequest();
                        updateRequest.add(queryBuilder.toString());

                        UpdateProcessor updateProcessor = UpdateExecutionFactory.createRemote(updateRequest, "http://localhost:3030/knowledge-graph/update");
                        updateProcessor.execute();
                        System.out.println(format("Executed batch of %d.", batchSize));

                        countInBatch = 0;
                        queryBuilder.delete(0, queryBuilder.length());
                    }

                    msgCount.incrementAndGet();
                }

                if (countInBatch > 0) {
                    UpdateRequest updateRequest = new UpdateRequest();
                    updateRequest.add(queryBuilder.toString());

                    UpdateProcessor updateProcessor = UpdateExecutionFactory.createRemote(updateRequest, "http://localhost:3030/knowledge-graph/update");
                    updateProcessor.execute();
                    System.out.println(format("Executed batch of %d.", countInBatch));
                }
            });
            threadNumber++;
        }
    }

    private static ConsumerConfig createConsumerConfig(String a_zookeeper, String a_groupId) {
        Properties props = new Properties();
        props.put("zookeeper.connect", a_zookeeper);
        props.put("group.id", a_groupId);
        props.put("auto.offset.reset", "smallest");
        props.put("zookeeper.session.timeout.ms", "400");
        props.put("zookeeper.sync.time.ms", "200");
        props.put("auto.commit.interval.ms", "1000");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

        return new ConsumerConfig(props);
    }

    public static void main(String[] args) {
        String zooKeeper = "localhost:9010";
        String groupId   = "knowledge-graph";
        String topic     = "evidence-rdf-events";
        int threads      = 1;

        final long start = System.currentTimeMillis();
        AtomicInteger msgCount = new AtomicInteger(0);

        EvidenceRDFConsumerGroup rdfConsumers = new EvidenceRDFConsumerGroup(zooKeeper, groupId, topic, msgCount);
        rdfConsumers.run(threads);

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println(format("Consumed %s messages.", msgCount.toString()));
            rdfConsumers.shutdown();

            final long end = System.currentTimeMillis();
            System.out.println(format("Completed in %s seconds.", ((float) (end - start)) / 1000f));
        }));
    }
}
