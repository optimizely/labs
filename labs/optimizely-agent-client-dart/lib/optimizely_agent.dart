/****************************************************************************
 * Copyright 2020, Optimizely, Inc. and contributors                        *
 *                                                                          *
 * Licensed under the Apache License, Version 2.0 (the "License");          *
 * you may not use this file except in compliance with the License.         *
 * You may obtain a copy of the License at                                  *
 *                                                                          *
 *    http://www.apache.org/licenses/LICENSE-2.0                            *
 *                                                                          *
 * Unless required by applicable law or agreed to in writing, software      *
 * distributed under the License is distributed on an "AS IS" BASIS,        *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 * See the License for the specific language governing permissions and      *
 * limitations under the License.                                           *
 ***************************************************************************/

import 'package:meta/meta.dart';
import 'package:dio/dio.dart';

import './src/models/optimizely_decision_legacy.dart';
import './src/models/decision_types.dart';
import './src/models/optimizely_decide_option.dart';
import './src/models/optimizely_decision.dart';
import './src/models/user_context.dart';
import './src/models/optimizely_config/optimizely_config.dart';
import './src/request_manager.dart';
import './src/decision_cache.dart';

// Exporting all the required classes
export './src/models/optimizely_decision.dart';
export './src/models/decision_types.dart';
export './src/models/optimizely_decision_legacy.dart';
export './src/models/optimizely_decide_option.dart';
export './src/models/user_context.dart';

// Exporting all OptimizelyConfig entities
export './src/models/optimizely_config/optimizely_config.dart';
export './src/models/optimizely_config/optimizely_experiment.dart';
export './src/models/optimizely_config/optimizely_feature.dart';
export './src/models/optimizely_config/optimizely_variable.dart';
export './src/models/optimizely_config/optimizely_variation.dart';

class OptimizelyAgent {
  RequestManager _requestmanager;
  UserContext userContext;
  DecisionCache decisionCache = new DecisionCache();

  OptimizelyAgent(String sdkKey, String url, UserContext userContext) {
    _requestmanager = RequestManager(sdkKey, url);
    this.userContext = userContext;
  }

  /// Returns status code and OptimizelyConfig object
  Future<OptimizelyConfig> getOptimizelyConfig() async {
    Response resp = await _requestmanager.getOptimizelyConfig();
    return resp.statusCode == 200 ? OptimizelyConfig.fromJson(resp.data) : null;
  }

  /// Tracks an event and returns nothing.
  Future<void> track({
    @required String eventKey,
    Map<String, dynamic> eventTags,
    UserContext overrideUserContext
  }) {
    UserContext resolvedUserContext = userContext;
    if (overrideUserContext != null) {
      resolvedUserContext = overrideUserContext;
    }
    if (!isUserContextValid(resolvedUserContext)) {
      print('Invalid User Context, Failing `track`');
      return null;
    }
    return _requestmanager.track(
      eventKey: eventKey,
      userId: resolvedUserContext.userId,
      eventTags: eventTags,
      userAttributes: resolvedUserContext.attributes
    );    
  }

  /// Activate makes feature and experiment decisions for the selected query parameters
  /// and returns list of OptimizelyDecision
  Future<List<OptimizelyDecisionLegacy>> activate({
    List<String> featureKey,
    List<String> experimentKey,
    bool disableTracking,
    DecisionType type,
    bool enabled,
    UserContext overrideUserContext
  }) async {
    UserContext resolvedUserContext = userContext;
    if (overrideUserContext != null) {
      resolvedUserContext = overrideUserContext;
    }
    if (!isUserContextValid(resolvedUserContext)) {
      print('Invalid User Context, Failing `activate`');
      return null;
    }
    Response resp = await _requestmanager.activate(
      userId: resolvedUserContext.userId,
      userAttributes: resolvedUserContext.attributes,
      featureKey: featureKey,
      experimentKey: experimentKey,
      disableTracking: disableTracking,
      type: type,
      enabled: enabled
    );
    if (resp.statusCode == 200) {
      List<OptimizelyDecisionLegacy> optimizelyDecisions = [];
      resp.data.forEach((element) {
        optimizelyDecisions.add(OptimizelyDecisionLegacy.fromJson(element));
      });
      return optimizelyDecisions;
    }
    return null;
  }

  Future<OptimizelyDecision> decide(
    String key,
    [
      List<OptimizelyDecideOption> optimizelyDecideOptions = const [],
      UserContext overrideUserContext
    ]
  ) async {
    UserContext resolvedUserContext = userContext;
    if (overrideUserContext != null) {
      resolvedUserContext = overrideUserContext;
    }
    if (!isUserContextValid(resolvedUserContext)) {
      print('Invalid User Context, Failing `decide`');
      return null;
    }
    OptimizelyDecision cachedDecision = decisionCache.getDecision(resolvedUserContext, key);
    if (cachedDecision != null) {
      print('--- Cache Hit!!! Returning Cached decision ---');
      return cachedDecision;
    } else {
      print('--- Cache Miss!!! Making a call to agent ---');
    }

    Response resp = await _requestmanager.decide(userContext: resolvedUserContext, key: key, optimizelyDecideOptions: optimizelyDecideOptions);
    if (resp.statusCode == 200) {
      return OptimizelyDecision.fromJson(resp.data);      
    }
    return null;
  }

  Future<List<OptimizelyDecision>> decideAll(    
    [
      List<OptimizelyDecideOption> optimizelyDecideOptions = const [],
      UserContext overrideUserContext
    ]
  ) async {
    UserContext resolvedUserContext = userContext;
    if (overrideUserContext != null) {
      resolvedUserContext = overrideUserContext;
    }
    if (!isUserContextValid(resolvedUserContext)) {
      print('Invalid User Context, Failing `decideAll`');
      return null;
    }
    Response resp = await _requestmanager.decide(userContext: resolvedUserContext, optimizelyDecideOptions: optimizelyDecideOptions);
    if (resp.statusCode == 200) {      
      List<OptimizelyDecision> optimizelyDecisions = [];
      resp.data.forEach((element) {
        optimizelyDecisions.add(OptimizelyDecision.fromJson(element));
      });
      return optimizelyDecisions;
    }
    return null;
  }

  isUserContextValid(UserContext userContext) => userContext?.userId != null && userContext?.userId != '';

  Future<void> loadAndCacheDecisions([UserContext overrideUserContext]) async {
    UserContext resolvedUserContext = userContext;
    if (overrideUserContext != null) {
      resolvedUserContext = overrideUserContext;
    }
    if (!isUserContextValid(resolvedUserContext)) {
      print('Invalid User Context, Failing `loadAndCacheDecisions`');
      return null;
    }
    List<OptimizelyDecision> decisions = await decideAll([OptimizelyDecideOption.DISABLE_DECISION_EVENT], resolvedUserContext);
    decisions.forEach((decision) => decisionCache.addDecision(resolvedUserContext, decision.flagKey, decision));    
  }

  resetCache() => decisionCache.reset();
}
