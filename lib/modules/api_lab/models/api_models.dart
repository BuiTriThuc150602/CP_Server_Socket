part of '../api_lab_screen.dart';

enum ApiBodyType { none, raw, json, formUrlEncoded }

class ApiKeyValue {
  const ApiKeyValue({
    required this.key,
    required this.value,
    this.enabled = true,
    this.secret = false,
    this.description = '',
  });

  factory ApiKeyValue.fromJson(Map<String, dynamic> json) {
    return ApiKeyValue(
      key: (json['key'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      enabled: json['enabled'] != false,
      secret: json['secret'] == true,
      description: (json['description'] ?? '').toString(),
    );
  }

  final String key;
  final String value;
  final bool enabled;
  final bool secret;
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'enabled': enabled,
      'secret': secret,
      'description': description,
    };
  }

  ApiKeyValue copyWith({
    String? key,
    String? value,
    bool? enabled,
    bool? secret,
    String? description,
  }) {
    return ApiKeyValue(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      secret: secret ?? this.secret,
      description: description ?? this.description,
    );
  }
}

class ApiFolder {
  const ApiFolder({
    required this.id,
    required this.collectionId,
    this.parentId,
    required this.name,
    required this.sortOrder,
  });

  factory ApiFolder.fromJson(Map<String, dynamic> json) {
    return ApiFolder(
      id: (json['id'] ?? _newId('folder')).toString(),
      collectionId: (json['collectionId'] ?? '').toString(),
      parentId: json['parentId']?.toString(),
      name: (json['name'] ?? 'Folder').toString(),
      sortOrder: _intValue(json['sortOrder'], 0),
    );
  }

  final String id;
  final String collectionId;
  final String? parentId;
  final String name;
  final int sortOrder;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'parentId': parentId,
      'name': name,
      'sortOrder': sortOrder,
    };
  }

  ApiFolder copyWith({
    String? id,
    String? collectionId,
    Object? parentId = _notSet,
    String? name,
    int? sortOrder,
  }) {
    return ApiFolder(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      parentId:
          identical(parentId, _notSet) ? this.parentId : parentId as String?,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class ApiRequest {
  const ApiRequest({
    required this.id,
    required this.collectionId,
    this.folderId,
    required this.name,
    required this.method,
    required this.url,
    required this.headers,
    required this.queryParams,
    required this.bodyType,
    required this.body,
    this.authType = 'none',
    this.authToken = '',
    this.authUsername = '',
    this.authPassword = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiRequest.defaults(String collectionId) {
    final now = DateTime.now();
    return ApiRequest(
      id: _newId('request'),
      collectionId: collectionId,
      name: 'New request',
      method: 'GET',
      url: 'https://httpbin.org/get',
      headers: _defaultRequestHeaders(),
      queryParams: const [],
      bodyType: ApiBodyType.none,
      body: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ApiRequest.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ApiRequest(
      id: (json['id'] ?? _newId('request')).toString(),
      collectionId: (json['collectionId'] ?? '').toString(),
      folderId: json['folderId']?.toString(),
      name: (json['name'] ?? 'Request').toString(),
      method: (json['method'] ?? 'GET').toString().toUpperCase(),
      url: (json['url'] ?? '').toString(),
      headers: _keyValues(json['headers']),
      queryParams: _keyValues(json['queryParams']),
      bodyType: _bodyType(json['bodyType']),
      body: (json['body'] ?? '').toString(),
      authType: (json['authType'] ?? 'none').toString(),
      authToken: (json['authToken'] ?? '').toString(),
      authUsername: (json['authUsername'] ?? '').toString(),
      authPassword: (json['authPassword'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? now,
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ?? now,
    );
  }

  final String id;
  final String collectionId;
  final String? folderId;
  final String name;
  final String method;
  final String url;
  final List<ApiKeyValue> headers;
  final List<ApiKeyValue> queryParams;
  final ApiBodyType bodyType;
  final String body;
  final String authType;
  final String authToken;
  final String authUsername;
  final String authPassword;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'folderId': folderId,
      'name': name,
      'method': method,
      'url': url,
      'headers': headers.map((item) => item.toJson()).toList(),
      'queryParams': queryParams.map((item) => item.toJson()).toList(),
      'bodyType': bodyType.name,
      'body': body,
      'authType': authType,
      'authToken': authToken,
      'authUsername': authUsername,
      'authPassword': authPassword,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ApiRequest copyWith({
    String? id,
    String? collectionId,
    Object? folderId = _notSet,
    String? name,
    String? method,
    String? url,
    List<ApiKeyValue>? headers,
    List<ApiKeyValue>? queryParams,
    ApiBodyType? bodyType,
    String? body,
    String? authType,
    String? authToken,
    String? authUsername,
    String? authPassword,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiRequest(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      folderId:
          identical(folderId, _notSet) ? this.folderId : folderId as String?,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyType: bodyType ?? this.bodyType,
      body: body ?? this.body,
      authType: authType ?? this.authType,
      authToken: authToken ?? this.authToken,
      authUsername: authUsername ?? this.authUsername,
      authPassword: authPassword ?? this.authPassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ApiCollection {
  const ApiCollection({
    required this.id,
    required this.name,
    required this.folders,
    required this.requests,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiCollection.defaults() {
    final now = DateTime.now();
    final id = _newId('collection');
    return ApiCollection(
      id: id,
      name: 'Local API Collection',
      folders: const [],
      requests: [ApiRequest.defaults(id)],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ApiCollection.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final id = (json['id'] ?? _newId('collection')).toString();
    return ApiCollection(
      id: id,
      name: (json['name'] ?? 'Collection').toString(),
      folders: _maps(json['folders']).map(ApiFolder.fromJson).toList(),
      requests:
          _maps(json['requests'])
              .map(ApiRequest.fromJson)
              .map(
                (request) =>
                    request.collectionId.isEmpty
                        ? request.copyWith(collectionId: id)
                        : request,
              )
              .toList(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? now,
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ?? now,
    );
  }

  final String id;
  final String name;
  final List<ApiFolder> folders;
  final List<ApiRequest> requests;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'folders': folders.map((folder) => folder.toJson()).toList(),
      'requests': requests.map((request) => request.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ApiCollection copyWith({
    String? id,
    String? name,
    List<ApiFolder>? folders,
    List<ApiRequest>? requests,
    DateTime? updatedAt,
  }) {
    return ApiCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      folders: folders ?? this.folders,
      requests: requests ?? this.requests,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ApiEnvironment {
  const ApiEnvironment({
    required this.id,
    required this.name,
    required this.variables,
  });

  factory ApiEnvironment.fromJson(Map<String, dynamic> json) {
    return ApiEnvironment(
      id: (json['id'] ?? _newId('env')).toString(),
      name: (json['name'] ?? 'Environment').toString(),
      variables: _keyValues(json['variables']),
    );
  }

  final String id;
  final String name;
  final List<ApiKeyValue> variables;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'variables': variables.map((item) => item.toJson()).toList(),
    };
  }
}

class ApiResponseSnapshot {
  const ApiResponseSnapshot({
    required this.statusCode,
    required this.reasonPhrase,
    required this.durationMs,
    required this.responseHeaders,
    required this.bodyText,
    required this.sizeBytes,
    required this.receivedAt,
  });

  final int? statusCode;
  final String reasonPhrase;
  final int durationMs;
  final Map<String, List<String>> responseHeaders;
  final String bodyText;
  final int sizeBytes;
  final DateTime receivedAt;

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'reasonPhrase': reasonPhrase,
      'durationMs': durationMs,
      'responseHeaders': responseHeaders,
      'bodyText': bodyText,
      'sizeBytes': sizeBytes,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }
}

class ApiHistoryEntry {
  const ApiHistoryEntry({
    required this.id,
    required this.requestId,
    required this.requestSnapshot,
    required this.responseSnapshot,
  });

  factory ApiHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ApiHistoryEntry(
      id: (json['id'] ?? _newId('history')).toString(),
      requestId: (json['requestId'] ?? '').toString(),
      requestSnapshot: ApiRequest.fromJson(_map(json['requestSnapshot'])),
      responseSnapshot: ApiResponseSnapshot(
        statusCode: _nullableInt(_map(json['responseSnapshot'])['statusCode']),
        reasonPhrase:
            (_map(json['responseSnapshot'])['reasonPhrase'] ?? '').toString(),
        durationMs: _intValue(_map(json['responseSnapshot'])['durationMs'], 0),
        responseHeaders: _headersMap(
          _map(json['responseSnapshot'])['responseHeaders'],
        ),
        bodyText: (_map(json['responseSnapshot'])['bodyText'] ?? '').toString(),
        sizeBytes: _intValue(_map(json['responseSnapshot'])['sizeBytes'], 0),
        receivedAt:
            DateTime.tryParse(
              (_map(json['responseSnapshot'])['receivedAt'] ?? '').toString(),
            ) ??
            DateTime.now(),
      ),
    );
  }

  final String id;
  final String requestId;
  final ApiRequest requestSnapshot;
  final ApiResponseSnapshot responseSnapshot;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'requestSnapshot': requestSnapshot.toJson(),
      'responseSnapshot': responseSnapshot.toJson(),
    };
  }
}
