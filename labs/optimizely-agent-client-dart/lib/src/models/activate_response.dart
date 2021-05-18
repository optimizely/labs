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

class OptimizelyDecision {
  OptimizelyDecision(this.userId, this.experimentKey, this.error);

  String userId;
  String experimentKey;
  String featureKey;
  String variationKey;
  String type;
  Map<String, dynamic> variables;
  bool enabled;
  String error;

  factory OptimizelyDecision.fromJson(Map<String, dynamic> json) {
    return OptimizelyDecision(
      json['userId'] as String,
      json['experimentKey'] as String,
      json['error'] as String ?? '',
    )
    ..featureKey = json['featureKey'] as String
    ..variationKey = json['variationKey'] as String
    ..type = json['type'] as String
    ..variables = json['variables'] as Map<String, dynamic> ?? {}
    ..enabled = json['enabled'] as bool;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic> {
      'userId': this.userId,
      'experimentKey': this.experimentKey,
      'featureKey': this.featureKey,
      'variationKey': this.variationKey,
      'type': this.type,
      'variables': this.variables,
      'enabled': this.enabled,
      'error': this.error,
    };
  }
}
