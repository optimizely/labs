# Dart Client for Optimizely Agent
This is a dart client to facilitate communication with Optimizely Agent.

## Initialization
```
OptimizelyAgent(String sdkKey, String url)
```
The client can be initialized buy providing `sdkKey` and url where `agent` is deployed.

#### Example
```
OptimizelyAgent agent = new OptimizelyAgent('{sdkKey}', 'http://localhost:8080');
```

## Activate
```
activate({
  @required String userId,
  Map<String, dynamic> userAttributes,
  List<String> featureKey,
  List<String> experimentKey,
  bool disableTracking,
  DecisionType type,
  bool enabled
}) → Future<List<OptimizelyDecision>>
```

Activate takes `userId` as a required argument and a combination of optional arguments and returns a list of decisions represented by `OptimizelyDecision`.

#### Example
```
List<OptimizelyDecision> optimizelyDecisions = await agent.activate(userId: 'user1', type: DecisionType.experiment, enabled: true);
if (optimizelyDecisions != null) {
  print('Total Decisions ${optimizelyDecisions.length}');
  optimizelyDecisions.forEach((OptimizelyDecision decision) {
    print(decision.variationKey);
  });
}
```

## Track
```
track({
  @required String eventKey,
  String userId,
  Map<String, dynamic> eventTags,
  Map<String, dynamic> userAttributes
}) → Future<void>
```

Track takes `eventKey` as a required argument and a combination of optional arguments and returns nothing.

#### Example
```
await agent.track(eventKey: 'button1_click', userId: 'user1');
```

## Optimizely Config
```
getOptimizelyConfig() → Future<OptimizelyConfig>
```

Returns `OptimizelyConfig` object which contains revision, a map of experiments and a map of features.

#### Example
```
OptimizelyConfig config = await agent.getOptimizelyConfig();
if (config != null) {
  print('Revision ${config.revision}');
  config.experimentsMap.forEach((String key, OptimizelyExperiment experiment) {
    print('Experiment Key: $key');
    print('Experiment Id: ${experiment.id}');
    experiment.variationsMap.forEach((String key, OptimizelyVariation variation) {
      print('  Variation Key: $key');
      print('  Variation Id: ${variation.id}');
    });
  });
}
```

## Override Decision
```
overrideDecision({
  @required String userId,
  @required String experimentKey,
  @required String variationKey
}) → Future<OverrideResponse>
```

overrideDecision requires all the parameters and returns on `OverrideResponse` object which contains previous variation, new variation, messages and some more information.

#### Example
```
OverrideResponse overrideResponse = await agent.overrideDecision(userId: 'user1', experimentKey: 'playground-test', variationKey: 'variation_5');
if (overrideResponse != null) {        
  print('Previous Variation: ${overrideResponse.prevVariationKey}');
  print('New Variation: ${overrideResponse.variationKey}');
  overrideResponse.messages.forEach((String message) => print('Message: $message'));
}
```