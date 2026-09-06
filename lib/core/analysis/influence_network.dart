class InfluenceEdge {
  const InfluenceEdge(this.source, this.target, this.weight);

  final String source;
  final String target;
  final double weight;
}

class InfluenceNetwork {
  InfluenceNetwork({
    required Iterable<String> nodes,
    required Iterable<InfluenceEdge> edges,
  }) : nodes = Set.unmodifiable(nodes),
       edges = List.unmodifiable(edges) {
    if (this.nodes.isEmpty ||
        this.edges.any((edge) {
          return !this.nodes.contains(edge.source) ||
              !this.nodes.contains(edge.target) ||
              !edge.weight.isFinite ||
              edge.weight < 0;
        })) {
      throw ArgumentError(
        'Edges must reference known nodes and have non-negative weights',
      );
    }
  }

  final Set<String> nodes;
  final List<InfluenceEdge> edges;

  Map<String, double> weightedInDegree() {
    final scores = {for (final node in nodes) node: 0.0};
    for (final edge in edges) {
      scores[edge.target] = scores[edge.target]! + edge.weight;
    }
    return Map.unmodifiable(scores);
  }

  Map<String, double> propagate({
    required String source,
    int steps = 1,
    double decay = 1,
  }) {
    if (!nodes.contains(source)) {
      throw ArgumentError.value(source, 'source', 'must be a known node');
    }
    if (steps < 0 || decay < 0 || !decay.isFinite) {
      throw ArgumentError(
        'Steps must be non-negative and decay must be finite',
      );
    }
    var influence = {for (final node in nodes) node: 0.0};
    influence[source] = 1.0;
    for (var step = 0; step < steps; step++) {
      final next = {for (final node in nodes) node: 0.0};
      for (final edge in edges) {
        next[edge.target] =
            next[edge.target]! + influence[edge.source]! * edge.weight * decay;
      }
      influence = next;
    }
    return Map.unmodifiable(influence);
  }
}
