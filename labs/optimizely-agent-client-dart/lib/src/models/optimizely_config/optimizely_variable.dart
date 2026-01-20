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

class OptimizelyVariable {
  String id;
  String key;
  String type;
  String value;

  OptimizelyVariable(this.id, this.key, this.type, this.value);

  factory OptimizelyVariable.fromJson(Map<String, dynamic> json) =>
      _$OptimizelyVariableFromJson(json);

  Map<String, dynamic> toJson() => _$OptimizelyVariableToJson(this);
}

OptimizelyVariable _$OptimizelyVariableFromJson(Map<String, dynamic> json) {
  return OptimizelyVariable(
    json['id'] as String,
    json['key'] as String,
    json['type'] as String,
    json['value'] as String,
  );
}

Map<String, dynamic> _$OptimizelyVariableToJson(OptimizelyVariable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'type': instance.type,
      'value': instance.value,
    };
