/****************************************************************************
 * Copyright 2021, Optimizely, Inc. and contributors                        *
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

import './models/optimizely_decision.dart';
import './models/user_context.dart';

class DecisionCache {
  Map<String, Map<String, OptimizelyDecision>> cache = {};

  void addDecision(UserContext userContext, String flagKey, OptimizelyDecision decision) {
    String userId = userContext.userId;
    if (cache.containsKey(userId)) {
      cache[userId][flagKey] = decision;
    } else {
      cache[userId] = { flagKey: decision};
    }
  }

  OptimizelyDecision getDecision(UserContext userContext, String flagKey) {
    String userId = userContext.userId;
    if (cache[userId] != null && cache[userId][flagKey] != null) {
      return cache[userId][flagKey];
    }
    return null;
  }

  void reset() => cache = {};
}
