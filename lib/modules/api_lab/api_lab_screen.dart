import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_server/core/storage/module_config_repository.dart';

enum ApiBodyType { none, raw, json, formUrlEncoded }

class ApiKeyValue {
  const ApiKeyValue({
    required this.key,
    required this.value,
    this.enabled = true,
    this.secret = false,
  });

  factory ApiKeyValue.fromJson(Map<String, dynamic> json) {
    return ApiKeyValue(
      key: (json['key'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      enabled: json['enabled'] != false,
      secret: json['secret'] == true,
    );
  }

  final String key;
  final String value;
  final bool enabled;
  final bool secret;

  Map<String, dynamic> toJson() {
    return {'key': key, 'value': value, 'enabled': enabled, 'secret': secret};
  }

  ApiKeyValue copyWith({
    String? key,
    String? value,
    bool? enabled,
    bool? secret,
  }) {
    return ApiKeyValue(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      secret: secret ?? this.secret,
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
      headers: const [],
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
    String? folderId,
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
      folderId: folderId ?? this.folderId,
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

class ApiLabScreen extends StatefulWidget {
  const ApiLabScreen({super.key});

  @override
  State<ApiLabScreen> createState() => _ApiLabScreenState();
}

class _ApiLabScreenState extends State<ApiLabScreen> {
  final _repository = ModuleConfigRepository();
  final _dio = Dio();
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _body = TextEditingController();
  final _search = TextEditingController();
  final _authToken = TextEditingController();
  final _authUsername = TextEditingController();
  final _authPassword = TextEditingController();

  List<ApiCollection> _collections = [];
  List<ApiEnvironment> _environments = [];
  List<ApiHistoryEntry> _history = [];
  final _globalVariables = <ApiKeyValue>[
    const ApiKeyValue(key: 'baseUrl', value: 'https://httpbin.org'),
  ];

  String? _selectedCollectionId;
  String? _selectedRequestId;
  String? _selectedEnvironmentId;
  String _method = 'GET';
  ApiBodyType _bodyType = ApiBodyType.none;
  String _authType = 'none';
  int _requestTab = 0;
  int _responseTab = 0;
  bool _prettyResponse = true;
  bool _loading = true;
  bool _sending = false;
  bool _runnerActive = false;
  String? _status;
  ApiResponseSnapshot? _response;

  ApiCollection? get _selectedCollection {
    return _collections
        .where((collection) => collection.id == _selectedCollectionId)
        .firstOrNull;
  }

  ApiRequest? get _selectedRequest {
    final collection = _selectedCollection;
    if (collection == null) return null;
    return collection.requests
        .where((request) => request.id == _selectedRequestId)
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _body.dispose();
    _search.dispose();
    _authToken.dispose();
    _authUsername.dispose();
    _authPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        _topBar(),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1050) {
                return ListView(
                  children: [
                    SizedBox(height: 360, child: _collectionPanel()),
                    const Divider(height: 1),
                    SizedBox(height: 520, child: _requestBuilder()),
                    const Divider(height: 1),
                    SizedBox(height: 420, child: _responsePanel()),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 300, child: _collectionPanel()),
                  const VerticalDivider(width: 1),
                  Expanded(flex: 5, child: _requestBuilder()),
                  const VerticalDivider(width: 1),
                  Expanded(flex: 4, child: _responsePanel()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              initialValue: _selectedEnvironmentId,
              isDense: true,
              decoration: const InputDecoration(labelText: 'Environment'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No environment'),
                ),
                for (final env in _environments)
                  DropdownMenuItem(value: env.id, child: Text(env.name)),
              ],
              onChanged:
                  (value) => setState(() => _selectedEnvironmentId = value),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _showEnvironmentDialog,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Variables'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _importDialog,
            icon: const Icon(Icons.file_upload, size: 18),
            label: const Text('Import'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _exportDialog,
            icon: const Icon(Icons.file_download, size: 18),
            label: const Text('Export'),
          ),
          const Spacer(),
          if (_status != null)
            Flexible(child: Text(_status!, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _collectionPanel() {
    final query = _search.text.trim().toLowerCase();
    final collection = _selectedCollection;
    final requests =
        (collection?.requests ?? const <ApiRequest>[])
            .where(
              (request) =>
                  query.isEmpty ||
                  '${request.name} ${request.url}'.toLowerCase().contains(
                    query,
                  ),
            )
            .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 18),
                    hintText: 'Search requests',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                tooltip: 'Create collection',
                onPressed: _createCollection,
                icon: const Icon(Icons.create_new_folder),
              ),
            ],
          ),
        ),
        if (_collections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCollectionId,
              isExpanded: true,
              items: [
                for (final item in _collections)
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
              ],
              onChanged: (value) => _selectCollection(value),
              decoration: const InputDecoration(labelText: 'Collection'),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _createRequest,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Request'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _runCollection,
                icon: const Icon(Icons.playlist_play, size: 18),
                label: Text(_runnerActive ? 'Stop' : 'Run all'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                selected: request.id == _selectedRequestId,
                dense: true,
                leading: Text(
                  request.method,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                title: Text(request.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(request.url, overflow: TextOverflow.ellipsis),
                onTap: () => _selectRequest(request.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _requestBuilder() {
    final request = _selectedRequest;
    if (request == null) {
      return const Center(child: Text('Create or select a request.'));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 112,
                child: DropdownButtonFormField<String>(
                  initialValue: _method,
                  items:
                      const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']
                          .map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => _method = value ?? _method),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _url,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _sending ? null : _sendSelectedRequest,
                icon: const Icon(Icons.send, size: 18),
                label: Text(_sending ? 'Sending' : 'Send'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _saveRequest,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Request name'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Duplicate request',
                onPressed: _duplicateRequest,
                icon: const Icon(Icons.copy),
              ),
              IconButton(
                tooltip: 'Delete request',
                onPressed: _deleteRequest,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Params')),
              ButtonSegment(value: 1, label: Text('Headers')),
              ButtonSegment(value: 2, label: Text('Body')),
              ButtonSegment(value: 3, label: Text('Auth')),
            ],
            selected: {_requestTab},
            onSelectionChanged:
                (value) => setState(() => _requestTab = value.first),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_requestTab) {
              0 => _keyValueEditor(
                'Query params',
                request.queryParams,
                (values) => _updateSelectedRequest(
                  request.copyWith(queryParams: values),
                ),
              ),
              1 => _keyValueEditor(
                'Headers',
                request.headers,
                (values) =>
                    _updateSelectedRequest(request.copyWith(headers: values)),
              ),
              2 => _bodyEditor(),
              _ => _authEditor(),
            },
          ),
        ],
      ),
    );
  }

  Widget _keyValueEditor(
    String title,
    List<ApiKeyValue> values,
    ValueChanged<List<ApiKeyValue>> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            OutlinedButton.icon(
              onPressed:
                  () => onChanged([
                    ...values,
                    const ApiKeyValue(key: '', value: ''),
                  ]),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: values.length,
            itemBuilder: (context, index) {
              final item = values[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Checkbox(
                      value: item.enabled,
                      onChanged:
                          (value) => onChanged(
                            _replace(
                              values,
                              index,
                              item.copyWith(enabled: value ?? true),
                            ),
                          ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: item.key,
                        decoration: const InputDecoration(labelText: 'Key'),
                        onChanged:
                            (value) => onChanged(
                              _replace(
                                values,
                                index,
                                item.copyWith(key: value),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextFormField(
                        initialValue: item.value,
                        decoration: const InputDecoration(labelText: 'Value'),
                        onChanged:
                            (value) => onChanged(
                              _replace(
                                values,
                                index,
                                item.copyWith(value: value),
                              ),
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onChanged(_removeAt(values, index)),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bodyEditor() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 220,
            child: DropdownButtonFormField<ApiBodyType>(
              initialValue: _bodyType,
              items:
                  ApiBodyType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        ),
                      )
                      .toList(),
              onChanged:
                  (value) => setState(() => _bodyType = value ?? _bodyType),
              decoration: const InputDecoration(labelText: 'Body type'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TextField(
            controller: _body,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              labelText: 'Body',
              alignLabelWithHint: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _authEditor() {
    return ListView(
      children: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String>(
            initialValue: _authType,
            items: const [
              DropdownMenuItem(value: 'none', child: Text('None')),
              DropdownMenuItem(value: 'bearer', child: Text('Bearer Token')),
              DropdownMenuItem(value: 'basic', child: Text('Basic Auth')),
            ],
            onChanged: (value) => setState(() => _authType = value ?? 'none'),
            decoration: const InputDecoration(labelText: 'Auth type'),
          ),
        ),
        const SizedBox(height: 8),
        if (_authType == 'bearer')
          TextField(
            controller: _authToken,
            decoration: const InputDecoration(labelText: 'Token'),
          ),
        if (_authType == 'basic') ...[
          TextField(
            controller: _authUsername,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _authPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ],
        const SizedBox(height: 12),
        const Text('Secrets are stored in local app storage for this MVP.'),
      ],
    );
  }

  Widget _responsePanel() {
    final response = _response;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Response', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (response != null) ...[
                Chip(
                  label: Text(
                    '${response.statusCode ?? '-'} ${response.reasonPhrase}',
                  ),
                ),
                const SizedBox(width: 6),
                Chip(label: Text('${response.durationMs} ms')),
                const SizedBox(width: 6),
                Chip(label: Text('${response.sizeBytes} bytes')),
                IconButton(
                  onPressed:
                      () => Clipboard.setData(
                        ClipboardData(text: response.bodyText),
                      ),
                  icon: const Icon(Icons.copy),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Body')),
              ButtonSegment(value: 1, label: Text('Headers')),
              ButtonSegment(value: 2, label: Text('History')),
            ],
            selected: {_responseTab},
            onSelectionChanged:
                (value) => setState(() => _responseTab = value.first),
          ),
          const SizedBox(height: 8),
          if (_responseTab == 0)
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Pretty JSON'),
                selected: _prettyResponse,
                onSelected: (value) => setState(() => _prettyResponse = value),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_responseTab) {
              0 => _responseBody(response),
              1 => _responseHeaders(response),
              _ => _historyList(),
            },
          ),
        ],
      ),
    );
  }

  Widget _responseBody(ApiResponseSnapshot? response) {
    final text =
        response == null
            ? 'No response yet.'
            : (_prettyResponse
                ? _prettyJson(response.bodyText)
                : response.bodyText);
    return SingleChildScrollView(
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }

  Widget _responseHeaders(ApiResponseSnapshot? response) {
    if (response == null) return const Text('No response headers yet.');
    return ListView(
      children: [
        for (final entry in response.responseHeaders.entries)
          ListTile(
            dense: true,
            title: Text(entry.key),
            subtitle: Text(entry.value.join(', ')),
          ),
      ],
    );
  }

  Widget _historyList() {
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return ListTile(
          dense: true,
          title: Text(
            '${item.requestSnapshot.method} ${item.requestSnapshot.name}',
          ),
          subtitle: Text(
            '${item.responseSnapshot.statusCode ?? '-'} • ${item.responseSnapshot.durationMs} ms • ${item.responseSnapshot.receivedAt.toLocal()}',
          ),
          onTap: () => setState(() => _response = item.responseSnapshot),
        );
      },
    );
  }

  Future<void> _load() async {
    final json = await _repository.read('api_lab_config');
    if (json == null) {
      final collection = ApiCollection.defaults();
      _collections = [collection];
      _environments = [
        const ApiEnvironment(
          id: 'default_env',
          name: 'Local',
          variables: [ApiKeyValue(key: 'host', value: 'https://httpbin.org')],
        ),
      ];
      _selectedCollectionId = collection.id;
      _selectedRequestId = collection.requests.first.id;
    } else {
      _collections =
          _maps(json['collections']).map(ApiCollection.fromJson).toList();
      _environments =
          _maps(json['environments']).map(ApiEnvironment.fromJson).toList();
      _history = _maps(json['history']).map(ApiHistoryEntry.fromJson).toList();
      if (_collections.isEmpty) _collections = [ApiCollection.defaults()];
      _selectedCollectionId =
          (json['selectedCollectionId'] ?? _collections.first.id).toString();
      _selectedRequestId =
          (json['selectedRequestId'] ??
                  _collections.first.requests.firstOrNull?.id ??
                  '')
              .toString();
      _selectedEnvironmentId = json['selectedEnvironmentId']?.toString();
    }
    _syncEditors();
    setState(() => _loading = false);
  }

  Future<void> _saveWorkspace() {
    return _repository.write('api_lab_config', {
      'collections': _collections.map((item) => item.toJson()).toList(),
      'environments': _environments.map((item) => item.toJson()).toList(),
      'history': _history.take(200).map((item) => item.toJson()).toList(),
      'selectedCollectionId': _selectedCollectionId,
      'selectedRequestId': _selectedRequestId,
      'selectedEnvironmentId': _selectedEnvironmentId,
    });
  }

  void _syncEditors() {
    final request = _selectedRequest;
    if (request == null) return;
    _name.text = request.name;
    _url.text = request.url;
    _body.text = request.body;
    _method = request.method;
    _bodyType = request.bodyType;
    _authType = request.authType;
    _authToken.text = request.authToken;
    _authUsername.text = request.authUsername;
    _authPassword.text = request.authPassword;
  }

  ApiRequest _draftRequest(ApiRequest request) {
    return request.copyWith(
      name: _name.text.trim().isEmpty ? request.name : _name.text.trim(),
      method: _method,
      url: _url.text.trim(),
      bodyType: _bodyType,
      body: _body.text,
      authType: _authType,
      authToken: _authToken.text,
      authUsername: _authUsername.text,
      authPassword: _authPassword.text,
      updatedAt: DateTime.now(),
    );
  }

  void _updateSelectedRequest(ApiRequest request) {
    final collection = _selectedCollection;
    if (collection == null) return;
    final requests = [
      for (final item in collection.requests)
        if (item.id == request.id) request else item,
    ];
    _collections = [
      for (final item in _collections)
        if (item.id == collection.id)
          collection.copyWith(requests: requests, updatedAt: DateTime.now())
        else
          item,
    ];
    setState(() {});
  }

  Future<void> _saveRequest() async {
    final request = _selectedRequest;
    if (request == null) return;
    _updateSelectedRequest(_draftRequest(request));
    await _saveWorkspace();
    setState(() => _status = 'Request saved.');
  }

  Future<void> _sendSelectedRequest() async {
    final request = _selectedRequest;
    if (request == null) return;
    final draft = _draftRequest(request);
    _updateSelectedRequest(draft);
    await _sendRequest(draft);
  }

  Future<ApiResponseSnapshot?> _sendRequest(ApiRequest request) async {
    setState(() {
      _sending = true;
      _status = 'Sending ${request.name}...';
    });
    final started = DateTime.now();
    try {
      final resolved = _resolveRequest(request);
      final response = await _dio.request<dynamic>(
        resolved.url,
        data: resolved.data,
        queryParameters: resolved.queryParameters,
        options: Options(
          method: request.method,
          headers: resolved.headers,
          validateStatus: (_) => true,
        ),
      );
      final bodyText = _responseText(response.data);
      final snapshot = ApiResponseSnapshot(
        statusCode: response.statusCode,
        reasonPhrase: response.statusMessage ?? '',
        durationMs: DateTime.now().difference(started).inMilliseconds,
        responseHeaders: response.headers.map,
        bodyText: bodyText,
        sizeBytes: utf8.encode(bodyText).length,
        receivedAt: DateTime.now(),
      );
      _response = snapshot;
      _history.insert(
        0,
        ApiHistoryEntry(
          id: _newId('history'),
          requestId: request.id,
          requestSnapshot: request,
          responseSnapshot: snapshot,
        ),
      );
      await _saveWorkspace();
      setState(
        () =>
            _status =
                'Response ${snapshot.statusCode ?? '-'} in ${snapshot.durationMs} ms.',
      );
      return snapshot;
    } catch (error) {
      final snapshot = ApiResponseSnapshot(
        statusCode: null,
        reasonPhrase: 'Error',
        durationMs: DateTime.now().difference(started).inMilliseconds,
        responseHeaders: const {},
        bodyText: error.toString(),
        sizeBytes: error.toString().length,
        receivedAt: DateTime.now(),
      );
      _response = snapshot;
      _history.insert(
        0,
        ApiHistoryEntry(
          id: _newId('history'),
          requestId: request.id,
          requestSnapshot: request,
          responseSnapshot: snapshot,
        ),
      );
      await _saveWorkspace();
      setState(() => _status = error.toString());
      return snapshot;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  _ResolvedRequest _resolveRequest(ApiRequest request) {
    final variables = _variables();
    final headers = <String, String>{};
    for (final header in request.headers.where(
      (item) => item.enabled && item.key.trim().isNotEmpty,
    )) {
      headers[_substitute(header.key, variables)] = _substitute(
        header.value,
        variables,
      );
    }
    if (request.authType == 'bearer' && request.authToken.trim().isNotEmpty) {
      headers['Authorization'] =
          'Bearer ${_substitute(request.authToken, variables)}';
    } else if (request.authType == 'basic' && request.authUsername.isNotEmpty) {
      final raw =
          '${_substitute(request.authUsername, variables)}:${_substitute(request.authPassword, variables)}';
      headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(raw))}';
    }
    Object? data;
    if (request.bodyType == ApiBodyType.raw) {
      data = _substitute(request.body, variables);
    } else if (request.bodyType == ApiBodyType.json) {
      headers.putIfAbsent('Content-Type', () => 'application/json');
      data = _substitute(request.body, variables);
    } else if (request.bodyType == ApiBodyType.formUrlEncoded) {
      headers.putIfAbsent(
        'Content-Type',
        () => 'application/x-www-form-urlencoded',
      );
      data = Map.fromEntries(
        request.body.split('&').where((part) => part.contains('=')).map((part) {
          final index = part.indexOf('=');
          return MapEntry(
            _substitute(part.substring(0, index), variables),
            _substitute(part.substring(index + 1), variables),
          );
        }),
      );
    }
    return _ResolvedRequest(
      url: _substitute(request.url, variables),
      queryParameters: {
        for (final item in request.queryParams.where(
          (item) => item.enabled && item.key.trim().isNotEmpty,
        ))
          _substitute(item.key, variables): _substitute(item.value, variables),
      },
      headers: headers,
      data: data,
    );
  }

  Map<String, String> _variables() {
    final now = DateTime.now();
    final selectedEnv =
        _environments
            .where((env) => env.id == _selectedEnvironmentId)
            .firstOrNull;
    return {
      for (final item in _globalVariables.where((item) => item.enabled))
        item.key: item.value,
      if (selectedEnv != null)
        for (final item in selectedEnv.variables.where((item) => item.enabled))
          item.key: item.value,
      r'$timestamp': '${now.millisecondsSinceEpoch ~/ 1000}',
      r'$timestampMs': '${now.millisecondsSinceEpoch}',
      r'$isoTime': now.toIso8601String(),
      r'$uuid': _uuidLike(),
    };
  }

  String _substitute(String input, Map<String, String> variables) {
    return input.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (match) {
      final key = match.group(1)?.trim() ?? '';
      return variables[key] ?? match.group(0)!;
    });
  }

  void _createCollection() {
    final collection = ApiCollection.defaults();
    setState(() {
      _collections = [..._collections, collection];
      _selectedCollectionId = collection.id;
      _selectedRequestId = collection.requests.first.id;
      _syncEditors();
    });
    unawaited(_saveWorkspace());
  }

  void _selectCollection(String? id) {
    final collection = _collections.where((item) => item.id == id).firstOrNull;
    if (collection == null) return;
    setState(() {
      _selectedCollectionId = collection.id;
      _selectedRequestId = collection.requests.firstOrNull?.id;
      _syncEditors();
    });
  }

  void _createRequest() {
    final collection = _selectedCollection;
    if (collection == null) return;
    final request = ApiRequest.defaults(collection.id);
    _collections = [
      for (final item in _collections)
        if (item.id == collection.id)
          collection.copyWith(
            requests: [...collection.requests, request],
            updatedAt: DateTime.now(),
          )
        else
          item,
    ];
    setState(() {
      _selectedRequestId = request.id;
      _syncEditors();
    });
    unawaited(_saveWorkspace());
  }

  void _selectRequest(String id) {
    setState(() {
      _selectedRequestId = id;
      _syncEditors();
    });
  }

  void _duplicateRequest() {
    final request = _selectedRequest;
    final collection = _selectedCollection;
    if (request == null || collection == null) return;
    final copy = request.copyWith(
      id: _newId('request'),
      name: '${request.name} Copy',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _collections = [
      for (final item in _collections)
        if (item.id == collection.id)
          collection.copyWith(
            requests: [...collection.requests, copy],
            updatedAt: DateTime.now(),
          )
        else
          item,
    ];
    setState(() {
      _selectedRequestId = copy.id;
      _syncEditors();
    });
    unawaited(_saveWorkspace());
  }

  void _deleteRequest() {
    final request = _selectedRequest;
    final collection = _selectedCollection;
    if (request == null || collection == null) return;
    final requests =
        collection.requests.where((item) => item.id != request.id).toList();
    _collections = [
      for (final item in _collections)
        if (item.id == collection.id)
          collection.copyWith(requests: requests, updatedAt: DateTime.now())
        else
          item,
    ];
    setState(() {
      _selectedRequestId = requests.firstOrNull?.id;
      _syncEditors();
    });
    unawaited(_saveWorkspace());
  }

  Future<void> _runCollection() async {
    if (_runnerActive) {
      setState(() => _runnerActive = false);
      return;
    }
    final collection = _selectedCollection;
    if (collection == null) return;
    setState(() => _runnerActive = true);
    for (final request in collection.requests) {
      if (!_runnerActive) break;
      await _sendRequest(request);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (mounted) setState(() => _runnerActive = false);
  }

  Future<void> _showEnvironmentDialog() async {
    final env =
        _environments.firstOrNull ??
        const ApiEnvironment(id: 'default_env', name: 'Local', variables: []);
    var variables = [...env.variables];
    await showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Environment variables'),
                  content: SizedBox(
                    width: 640,
                    height: 420,
                    child: Column(
                      children: [
                        Expanded(
                          child: _keyValueEditor(
                            'Variables',
                            variables,
                            (value) => setDialogState(() => variables = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        _environments = [
                          ApiEnvironment(
                            id: env.id,
                            name: env.name,
                            variables: variables,
                          ),
                        ];
                        _selectedEnvironmentId = env.id;
                        unawaited(_saveWorkspace());
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _importDialog() async {
    final controller = TextEditingController();
    var mode = 'postman_collection';
    String? errorText;
    await showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Import'),
                  content: SizedBox(
                    width: 720,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: mode,
                          items: const [
                            DropdownMenuItem(
                              value: 'postman_collection',
                              child: Text('Postman Collection v2.1 JSON'),
                            ),
                            DropdownMenuItem(
                              value: 'postman_environment',
                              child: Text('Postman Environment JSON'),
                            ),
                            DropdownMenuItem(
                              value: 'csv',
                              child: Text('CSV preview'),
                            ),
                          ],
                          onChanged:
                              (value) =>
                                  setDialogState(() => mode = value ?? mode),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          minLines: 10,
                          maxLines: 16,
                          decoration: InputDecoration(
                            errorText: errorText,
                            hintText: 'Paste JSON or CSV here',
                          ),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        try {
                          if (mode == 'postman_collection') {
                            _importPostmanCollection(controller.text);
                          }
                          if (mode == 'postman_environment') {
                            _importPostmanEnvironment(controller.text);
                          }
                          if (mode == 'csv') {
                            Navigator.pop(context);
                            _showCsvPreview(controller.text);
                            return;
                          }
                          Navigator.pop(context);
                        } catch (error) {
                          setDialogState(() => errorText = error.toString());
                        }
                      },
                      child: const Text('Import'),
                    ),
                  ],
                ),
          ),
    );
    controller.dispose();
  }

  void _importPostmanCollection(String text) {
    final json = jsonDecode(text);
    if (json is! Map) {
      throw const FormatException('Expected Postman collection object.');
    }
    final collectionId = _newId('collection');
    final requests = <ApiRequest>[];
    void visit(List items, String? folderName) {
      for (final item in items.whereType<Map>()) {
        if (item['request'] is Map) {
          requests.add(
            _postmanRequest(
              Map<String, dynamic>.from(item),
              collectionId,
              folderName,
            ),
          );
        } else if (item['item'] is List) {
          visit(
            item['item'] as List,
            (item['name'] ?? folderName ?? 'Folder').toString(),
          );
        }
      }
    }

    visit((json['item'] as List?) ?? const [], null);
    final now = DateTime.now();
    final collection = ApiCollection(
      id: collectionId,
      name:
          (_map(json['info'])['name'] ?? 'Imported Postman Collection')
              .toString(),
      folders: const [],
      requests:
          requests.isEmpty ? [ApiRequest.defaults(collectionId)] : requests,
      createdAt: now,
      updatedAt: now,
    );
    setState(() {
      _collections = [..._collections, collection];
      _selectedCollectionId = collection.id;
      _selectedRequestId = collection.requests.first.id;
      _syncEditors();
      _status = 'Imported ${collection.requests.length} request(s).';
    });
    unawaited(_saveWorkspace());
  }

  ApiRequest _postmanRequest(
    Map<String, dynamic> item,
    String collectionId,
    String? folderName,
  ) {
    final request = _map(item['request']);
    final body = _map(request['body']);
    final mode = (body['mode'] ?? 'none').toString();
    final rawUrl =
        request['url'] is Map
            ? (_map(request['url'])['raw'] ?? '').toString()
            : (request['url'] ?? '').toString();
    final now = DateTime.now();
    return ApiRequest(
      id: _newId('request'),
      collectionId: collectionId,
      name:
          folderName == null
              ? (item['name'] ?? 'Request').toString()
              : '$folderName / ${(item['name'] ?? 'Request')}',
      method: (request['method'] ?? 'GET').toString(),
      url: rawUrl,
      headers:
          _maps(request['header'])
              .map(
                (header) => ApiKeyValue(
                  key: (header['key'] ?? '').toString(),
                  value: (header['value'] ?? '').toString(),
                  enabled: header['disabled'] != true,
                ),
              )
              .toList(),
      queryParams:
          _maps(_map(request['url'])['query'])
              .map(
                (param) => ApiKeyValue(
                  key: (param['key'] ?? '').toString(),
                  value: (param['value'] ?? '').toString(),
                  enabled: param['disabled'] != true,
                ),
              )
              .toList(),
      bodyType:
          mode == 'raw'
              ? ApiBodyType.json
              : (mode == 'urlencoded'
                  ? ApiBodyType.formUrlEncoded
                  : ApiBodyType.none),
      body:
          mode == 'urlencoded'
              ? _maps(
                body['urlencoded'],
              ).map((item) => '${item['key']}=${item['value']}').join('&')
              : (body['raw'] ?? '').toString(),
      createdAt: now,
      updatedAt: now,
    );
  }

  void _importPostmanEnvironment(String text) {
    final json = jsonDecode(text);
    if (json is! Map) {
      throw const FormatException('Expected Postman environment object.');
    }
    final env = ApiEnvironment(
      id: _newId('env'),
      name: (json['name'] ?? 'Imported Environment').toString(),
      variables:
          _maps(json['values'])
              .map(
                (item) => ApiKeyValue(
                  key: (item['key'] ?? '').toString(),
                  value: (item['value'] ?? '').toString(),
                  enabled: item['enabled'] != false,
                ),
              )
              .toList(),
    );
    setState(() {
      _environments = [..._environments, env];
      _selectedEnvironmentId = env.id;
      _status = 'Imported environment ${env.name}.';
    });
    unawaited(_saveWorkspace());
  }

  Future<void> _showCsvPreview(String text) async {
    final rows =
        text
            .trim()
            .split(RegExp(r'\r?\n'))
            .map((line) => line.split(','))
            .toList();
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('CSV preview'),
            content: SizedBox(
              width: 720,
              height: 360,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    for (final cell in rows.firstOrNull ?? const <String>[])
                      DataColumn(label: Text(cell)),
                  ],
                  rows: [
                    for (final row in rows.skip(1).take(20))
                      DataRow(
                        cells: [for (final cell in row) DataCell(Text(cell))],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _exportDialog() async {
    final collection = _selectedCollection;
    if (collection == null) return;
    final internal = const JsonEncoder.withIndent(
      '  ',
    ).convert(collection.toJson());
    final postman = const JsonEncoder.withIndent(
      '  ',
    ).convert(_postmanExport(collection));
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export collection'),
            content: const Text(
              'Copy the selected collection as internal JSON or Postman-like JSON.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              OutlinedButton(
                onPressed:
                    () => Clipboard.setData(ClipboardData(text: internal)),
                child: const Text('Copy internal JSON'),
              ),
              FilledButton(
                onPressed:
                    () => Clipboard.setData(ClipboardData(text: postman)),
                child: const Text('Copy Postman JSON'),
              ),
            ],
          ),
    );
  }

  Map<String, dynamic> _postmanExport(ApiCollection collection) {
    return {
      'info': {
        'name': collection.name,
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
      },
      'item': [
        for (final request in collection.requests)
          {
            'name': request.name,
            'request': {
              'method': request.method,
              'header':
                  request.headers
                      .map(
                        (item) => {
                          'key': item.key,
                          'value': item.value,
                          'disabled': !item.enabled,
                        },
                      )
                      .toList(),
              'url': {'raw': request.url},
              'body': {
                'mode':
                    request.bodyType == ApiBodyType.formUrlEncoded
                        ? 'urlencoded'
                        : 'raw',
                'raw': request.body,
              },
            },
          },
      ],
    };
  }

  List<ApiKeyValue> _replace(
    List<ApiKeyValue> values,
    int index,
    ApiKeyValue value,
  ) {
    return [
      for (var i = 0; i < values.length; i++)
        if (i == index) value else values[i],
    ];
  }

  List<ApiKeyValue> _removeAt(List<ApiKeyValue> values, int index) {
    return [
      for (var i = 0; i < values.length; i++)
        if (i != index) values[i],
    ];
  }
}

class _ResolvedRequest {
  const _ResolvedRequest({
    required this.url,
    required this.queryParameters,
    required this.headers,
    required this.data,
  });

  final String url;
  final Map<String, String> queryParameters;
  final Map<String, String> headers;
  final Object? data;
}

String _newId(String prefix) {
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
}

int _intValue(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  return _intValue(value, 0);
}

ApiBodyType _bodyType(Object? value) {
  return ApiBodyType.values
          .where((type) => type.name == value?.toString())
          .firstOrNull ??
      ApiBodyType.none;
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<ApiKeyValue> _keyValues(Object? value) {
  return _maps(value).map(ApiKeyValue.fromJson).toList();
}

Map<String, List<String>> _headersMap(Object? value) {
  final map = _map(value);
  return {
    for (final entry in map.entries)
      entry.key:
          (entry.value is List
              ? (entry.value as List).map((item) => item.toString()).toList()
              : [entry.value.toString()]),
  };
}

String _responseText(Object? data) {
  if (data == null) return '';
  if (data is String) return data;
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data.toString();
  }
}

String _prettyJson(String text) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
  } catch (_) {
    return text;
  }
}

String _uuidLike() {
  final random = Random();
  String hex(int length) =>
      List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
