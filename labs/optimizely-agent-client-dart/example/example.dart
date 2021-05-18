import 'package:optimizely_agent_client/optimizely_agent.dart';

void main() async {
  OptimizelyAgent agent = new OptimizelyAgent('{SDK_KEY}', '{AGENT_URL}');
  
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
  }
  print('');

  print('---- Calling Activate API ----');
  List<OptimizelyDecision> optimizelyDecisions = await agent.activate(userId: 'user1', type: DecisionType.experiment, enabled: true);
  if (optimizelyDecisions != null) {
    print('Total Decisions ${optimizelyDecisions.length}');
    optimizelyDecisions.forEach((OptimizelyDecision decision) {
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
