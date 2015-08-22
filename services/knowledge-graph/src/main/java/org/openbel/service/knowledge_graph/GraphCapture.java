package org.openbel.service.knowledge_graph;

import org.apache.jena.atlas.lib.Sink;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.Triple;
import org.apache.jena.riot.system.StreamRDFBase;
import org.apache.jena.sparql.core.Quad;

public class GraphCapture extends StreamRDFBase {

    private Node graphContextNode;
    private final Sink<Triple> tripleDestination;

    public GraphCapture(Sink<Triple> tripleDestination) {
        this.tripleDestination = tripleDestination;
    }

    public Node getGraphContextNode() {
        return graphContextNode;
    }

    @Override
    public void quad(Quad quad) {
        if (graphContextNode == null) graphContextNode = quad.getGraph();
        tripleDestination.send(quad.asTriple());
    }

    @Override
    public void finish() {
        tripleDestination.flush();
    }
}
