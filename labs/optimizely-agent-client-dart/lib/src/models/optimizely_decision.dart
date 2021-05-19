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

import './user_context.dart';

class OptimizelyDecision {
  Map<String, dynamic> variables;
  String variationKey;
  bool enabled;
  String ruleKey;
  String flagKey;
  UserContext userContext;
  List<String> reasons;

  OptimizelyDecision.fromJson(Map<String, dynamic> json)
    : variables = json['variables'] as Map<String, dynamic> ?? {},
      variationKey = json['variationKey'],
      enabled = json['enabled'],
      ruleKey = json['ruleKey'],
      flagKey = json['flagKey'],
      userContext = UserContext.fromJson(json['userContext']),
      reasons = (json['reasons'] as List<dynamic>).map((r) => r.toString()).toList();

  Map<String, dynamic> toJson() {
    return <String, dynamic> {
      'userContext': this.userContext.toJson(),
      'ruleKey': this.ruleKey,
      'flagKey': this.flagKey,
      'variationKey': this.variationKey,      
      'variables': this.variables,
      'enabled': this.enabled,
      'reasons': this.reasons,
    };
  }
}
