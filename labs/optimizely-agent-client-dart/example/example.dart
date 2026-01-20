import 'package:optimizely_agent_client/optimizely_agent.dart';

void main() async {
  OptimizelyAgent agent = new OptimizelyAgent('{SDK_KEY}', '{AGENT_URL}', UserContext('{USER_ID}'));
  
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

  var decision = await agent.decide('{FLAG_KEY}', [
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
  List<OptimizelyDecisionLegacy> optimizelyDecisionsLegacy = await agent.activate(type: DecisionType.experiment, enabled: true);
  if (optimizelyDecisionsLegacy != null) {
    print('Total Decisions ${optimizelyDecisionsLegacy.length}');
    optimizelyDecisionsLegacy.forEach((OptimizelyDecisionLegacy decision) {
      print(decision.toJson());
    });
  }
  print('');

  print('---- Calling Track API ----');
  await agent.track(eventKey: '{EVENT_NAME}');
  print('Done!');
}
