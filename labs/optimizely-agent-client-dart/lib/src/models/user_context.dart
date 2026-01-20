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

class UserContext {
  String userId;
  Map<String, String> attributes = new Map<String, String>();

  UserContext(userId, [attributes])
    : this.userId = userId,
      this.attributes = attributes;

  UserContext.fromJson(Map<String, dynamic> json)
    : userId = json['userId'],
      attributes = (json['attributes'] as Map<String, dynamic>).map((k, e) => MapEntry(k, e as String));

  Map<String, dynamic> toJson() {
    return <String, dynamic> {
      "userId": this.userId,
      "attributes": this.attributes
    };
  }
}