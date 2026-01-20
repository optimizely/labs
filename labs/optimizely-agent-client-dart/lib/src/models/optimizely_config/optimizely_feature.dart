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

import './optimizely_experiment.dart';
import './optimizely_variable.dart';

class OptimizelyFeature {
  String id;
  String key;
  Map<String, OptimizelyExperiment> experimentsMap;
  Map<String, OptimizelyVariable> variablesMap;

  OptimizelyFeature(this.id, this.key, this.experimentsMap, this.variablesMap);

  factory OptimizelyFeature.fromJson(Map<String, dynamic> json) =>
      _$OptimizelyFeatureFromJson(json);

  Map<String, dynamic> toJson() => _$OptimizelyFeatureToJson(this);
}

OptimizelyFeature _$OptimizelyFeatureFromJson(Map<String, dynamic> json) {
  return OptimizelyFeature(
    json['id'] as String,
    json['key'] as String,
    (json['experimentsMap'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          k,
          e == null
              ? null
              : OptimizelyExperiment.fromJson(e as Map<String, dynamic>)),
    ),
    (json['variablesMap'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          k,
          e == null
              ? null
              : OptimizelyVariable.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$OptimizelyFeatureToJson(OptimizelyFeature instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'experimentsMap': instance.experimentsMap,
      'variablesMap': instance.variablesMap,
    };
