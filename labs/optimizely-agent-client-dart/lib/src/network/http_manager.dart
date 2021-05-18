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

import 'dart:io';
import 'package:dio/dio.dart';

class HttpManager {
  final String _sdkKey;
  final String _url;
  final _client = Dio();

  HttpManager(this._sdkKey, this._url) {
    _client.options.baseUrl = _url;
    _client.options.headers = {
      "X-Optimizely-SDK-Key": _sdkKey,
      HttpHeaders.contentTypeHeader: "application/json"
    };
  }

  Future<Response> getRequest(String endpoint) {
    return _client.get('$_url$endpoint');
  }

  Future<Response> postRequest(String endpoint, Object body, [Map<String, String> queryParams]) {
    return _client.post(endpoint, data: body, queryParameters: queryParams);
  }
}
