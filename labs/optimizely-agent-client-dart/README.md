# Dart / FlutterClient for Optimizely Agent
This is a dart / flutter client to facilitate communication with Optimizely Agent.

## Initialization
```
OptimizelyAgent(String sdkKey, String url, UserContext userContext)
```
The client can be initialized by providing `sdkKey`, url where `agent` is deployed and `userContext` which contains `userId` and `attributes`. The client memoizes the user information and reuses it for subsequent calls.

#### Example
```
OptimizelyAgent agent = new OptimizelyAgent('{sdkKey}', 'http://localhost:8080', UserContext('user1', {'group': 'premium'}));
```

## Decision Caching
By default, the client makes a new http call to the agent for every decision. Optionally, to avoid latency, all decisions can be loaded and cached for a userContext.

```
loadAndCacheDecisions([UserContext overrideUserContext]) → Future<void>
```

When no arguments are provided, it will load decisions for the memoized user. An optional`overrideUserContext` can be provided to load and cache decisions for a different user.

####
```
await agent.loadAndCacheDecisions();
```

## Decide

```
decide(
  String key, 
  [List<OptimizelyDecideOption> optimizelyDecideOptions = const [],
  UserContext overrideUserContext
]) → Future<OptimizelyDecision>
```

`decide` takes flag Key as a required parameter and evaluates the decision for the memoized user. It can also optionally take decide options or override User. `decide` returns a cached decision if available otherwise it makes an API call to the agent.

## Decide All

```
decideAll(
  [List<OptimizelyDecideOption> optimizelyDecideOptions = const [],
  UserContext overrideUserContext
]) → Future<List<OptimizelyDecision>>
```

`decideAll` evaluates all the decisions for the memoized user. It can also optionally take decide options or override User. `decideAll` does not make use of the cache and always makes a new API call to agent.

## Activate (Legacy)
```
activate({
  List<String> featureKey,
  List<String> experimentKey,
  bool disableTracking,
  DecisionType type,
  bool enabled,
  UserContext overrideUserContext
}) → Future<List<OptimizelyDecisionLegacy>>
```

Activate is a Legacy API and should only be used with legacy experiments. I uses memoized user and takes a combination of optional arguments and returns a list of decisions. Activate does not leverage decision caching.

#### Example
```
List<OptimizelyDecisionLegacy> optimizelyDecisions = await agent.activate(type: DecisionType.experiment, enabled: true);
if (optimizelyDecisions != null) {
  print('Total Decisions ${optimizelyDecisions.length}');
  optimizelyDecisions.forEach((OptimizelyDecisionLegacy decision) {
    print(decision.variationKey);
  });
}
```

## Track
```
track({
  @required String eventKey,  
  Map<String, dynamic> eventTags,
  UserContext overrideUserContext
}) → Future<void>
```

Track takes `eventKey` as a required argument and a combination of optional arguments and sends an event.

#### Example
```
await agent.track(eventKey: 'button1_click');
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
