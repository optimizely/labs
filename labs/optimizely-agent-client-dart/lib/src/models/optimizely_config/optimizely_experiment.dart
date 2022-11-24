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

import './optimizely_variation.dart';

class OptimizelyExperiment {
  String id;
  String key;
  Map<String, OptimizelyVariation> variationsMap;

  OptimizelyExperiment(this.id, this.key, this.variationsMap);

  factory OptimizelyExperiment.fromJson(Map<String, dynamic> json) =>
      _$OptimizelyExperimentFromJson(json);

  Map<String, dynamic> toJson() => _$OptimizelyExperimentToJson(this);
}

OptimizelyExperiment _$OptimizelyExperimentFromJson(Map<String, dynamic> json) {
  return OptimizelyExperiment(
    json['id'] as String,
    json['key'] as String,
    (json['variationsMap'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          k,
          e == null
              ? null
              : OptimizelyVariation.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$OptimizelyExperimentToJson(
        OptimizelyExperiment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'variationsMap': instance.variationsMap,
    };
