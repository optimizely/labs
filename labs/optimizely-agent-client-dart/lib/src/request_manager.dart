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

import './models/decision_types.dart';
import './network/http_manager.dart';

class RequestManager {
  HttpManager _manager;

  RequestManager(String sdkKey, url) {
    _manager = HttpManager(sdkKey, url);
  }

  Future<Response> getOptimizelyConfig() async {
    Response resp;
    try {
      resp = await _manager.getRequest("/v1/config");
    } on DioError catch(err) {
      resp = err.response != null ? err.response : new Response(statusCode: 0, statusMessage: err.message);      
    }
    return resp;
  }

  Future<Response> track({
    @required String eventKey,
    String userId,
    Map<String, dynamic> eventTags,
    Map<String, dynamic> userAttributes
  }) async {
    Map<String, dynamic> body = {};

    if (userId != null) {
      body["userId"] = userId;
    }

    if (eventTags != null) {
      body["eventTags"] = eventTags;
    }

    if (userAttributes != null) {
      body["userAttributes"] = userAttributes;
    }

    Response resp;
    try {
      resp = await _manager.postRequest("/v1/track", body, {"eventKey": eventKey});
    } on DioError catch(err) {
      resp = err.response != null ? err.response : new Response(statusCode: 0, statusMessage: err.message);
    }
    return resp;
  }

  Future<Response> overrideDecision({
    @required String userId,
    @required String experimentKey,
    @required String variationKey
  }) async {    
    Map<String, dynamic> body = {
      "userId": userId,
      "experimentKey": experimentKey,
      "variationKey": variationKey
    };
    
    Response resp;
    try {
      resp = await _manager.postRequest("/v1/override", body);
    } on DioError catch(err) {
      print(err.message);
      resp = err.response != null ? err.response : new Response(statusCode: 0, statusMessage: err.message);
    }
    return resp;
  }

  Future<Response> activate({
    @required String userId,
    Map<String, dynamic> userAttributes,
    List<String> featureKey,
    List<String> experimentKey,
    bool disableTracking,
    DecisionType type,
    bool enabled,
  }) async {
    Map<String, dynamic> body = { "userId": userId };
    
    if (userAttributes != null) {
      body["userAttributes"] = userAttributes;
    }

    Map<String, String> queryParams = {};
    
    if (featureKey != null) {
      queryParams["featureKey"] = featureKey.join(',');
    }
    
    if (experimentKey != null) {
      queryParams["experimentKey"] = experimentKey.join(',');
    }
    
    if (disableTracking != null) {
      queryParams["disableTracking"] = disableTracking.toString();
    }
    
    if (type != null) {
      queryParams["type"] = type.toString().split('.').last;
    }
    
    if (enabled != null) {
      queryParams["enabled"] = enabled.toString();
    }
    
    Response resp;
    try {
      resp = await _manager.postRequest("/v1/activate", body, queryParams);
    } on DioError catch(err) {
      resp = err.response != null ? err.response : new Response(statusCode: 0, statusMessage: err.message);
    }
    return resp;
  }
}
