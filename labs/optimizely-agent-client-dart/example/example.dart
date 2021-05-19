import 'package:optimizely_agent_client/optimizely_agent.dart';

void main() async {
  OptimizelyAgent agent = new OptimizelyAgent('JY3jkLmiQiAqHd866edA3', 'http://127.0.0.1:8080', new UserContext('zee'));
  
  await agent.loadAndCacheDecisions();

  print('---- Calling DecideAll API ----');
  var decisions = await agent.decideAll(    
    [
      OptimizelyDecideOption.DISABLE_DECISION_EVENT,
      OptimizelyDecideOption.INCLUDE_REASONS
    ],
  );
  decisions?.forEach((decision) {
    print(decision.toJson());
  });
  print('');

  var decision = await agent.decide('product_sort', [
      OptimizelyDecideOption.DISABLE_DECISION_EVENT,
      OptimizelyDecideOption.INCLUDE_REASONS
    ]);
  print(decision.toJson());

  print('---- Calling OptimizelyConfig API ----');
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
    
    config.featuresMap.forEach((String key, OptimizelyFeature feature) {      
      print('Feature Key: $key');
    });
  }
  print('');

  print('---- Calling Activate API ----');
  List<OptimizelyDecisionLegacy> optimizelyDecisionsLegacy = await agent.activate(userId: 'user1', type: DecisionType.experiment, enabled: true);
  if (optimizelyDecisionsLegacy != null) {
    print('Total Decisions ${optimizelyDecisionsLegacy.length}');
    optimizelyDecisionsLegacy.forEach((OptimizelyDecisionLegacy decision) {
      print(decision.toJson());
    });
  }
  print('');

  print('---- Calling Track API ----');
  await agent.track(eventKey: 'button1_click', userId: 'user1');
  print('');

  print('---- Calling Override API ----');
  OverrideResponse overrideResponse = await agent.overrideDecision(userId: 'user1', experimentKey: 'playground-test', variationKey: 'variation_5');
  if (overrideResponse != null) {        
    print('Previous Variation: ${overrideResponse.prevVariationKey}');
    print('New Variation: ${overrideResponse.variationKey}');
    overrideResponse.messages.forEach((String message) => print('Message: $message'));
  }
  print('');
}
