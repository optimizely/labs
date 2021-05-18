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

class OverrideResponse {
  OverrideResponse(this.userId, this.experimentKey, this.variationKey,
      this.prevVariationKey, this.messages);

  String userId;
  String experimentKey;
  String variationKey;
  String prevVariationKey;
  List<String> messages;

  factory OverrideResponse.fromJson(Map<String, dynamic> json) =>
      _$OverrideResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OverrideResponseToJson(this);
}

OverrideResponse _$OverrideResponseFromJson(Map<String, dynamic> json) {
  return OverrideResponse(
    json['userId'] as String,
    json['experimentKey'] as String,
    json['variationKey'] as String,
    json['prevVariationKey'] as String,
    (json['messages'] as List)?.map((e) => e as String)?.toList(),
  );
}

Map<String, dynamic> _$OverrideResponseToJson(OverrideResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'experimentKey': instance.experimentKey,
      'variationKey': instance.variationKey,
      'prevVariationKey': instance.prevVariationKey,
      'messages': instance.messages,
    };
