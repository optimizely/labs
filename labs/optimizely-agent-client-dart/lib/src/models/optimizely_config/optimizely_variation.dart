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

import './optimizely_variable.dart';

class OptimizelyVariation {
  String id;
  String key;
  bool featureEnabled;
  Map<String, OptimizelyVariable> variablesMap;

  OptimizelyVariation(
      this.id, this.key, this.featureEnabled, this.variablesMap);

  factory OptimizelyVariation.fromJson(Map<String, dynamic> json) =>
      _$OptimizelyVariationFromJson(json);

  Map<String, dynamic> toJson() => _$OptimizelyVariationToJson(this);
}

OptimizelyVariation _$OptimizelyVariationFromJson(Map<String, dynamic> json) {
  return OptimizelyVariation(
    json['id'] as String,
    json['key'] as String,
    json['featureEnabled'] as bool,
    (json['variablesMap'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          k,
          e == null
              ? null
              : OptimizelyVariable.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$OptimizelyVariationToJson(
        OptimizelyVariation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'featureEnabled': instance.featureEnabled,
      'variablesMap': instance.variablesMap,
    };
