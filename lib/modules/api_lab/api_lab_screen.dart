import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testdeck/core/storage/module_config_repository.dart';

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
  List<String> _openRequestIds = [];
  final _globalVariables = <ApiKeyValue>[
    const ApiKeyValue(key: 'baseUrl', value: 'https://httpbin.org'),
  ];

  String? _selectedCollectionId;
  String? _selectedRequestId;
  String? _selectedFolderId;
  String? _selectedEnvironmentId;
  String _method = 'GET';
  ApiBodyType _bodyType = ApiBodyType.none;
  String _authType = 'none';
  int _requestTab = 0;
  int _responseTab = 0;
  String _responseBodyMode = 'pretty';
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
                    SizedBox(height: 420, child: _collectionPanel()),
                    const Divider(height: 1),
                    SizedBox(height: 620, child: _requestBuilder()),
                    const Divider(height: 1),
                    SizedBox(height: 420, child: _responsePanel()),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 320, child: _collectionPanel()),
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
              onChanged: (value) {
                setState(() => _selectedEnvironmentId = value);
                unawaited(_saveWorkspace());
              },
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
    final requests = collection?.requests ?? const <ApiRequest>[];
    final filteredRequests =
        requests
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
                  onPressed: () => _createRequest(folderId: _selectedFolderId),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Request'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _createFolder,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Folder'),
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
          child: ListView(
            children: [
              if (query.isNotEmpty)
                for (final request in filteredRequests) _requestTile(request)
              else if (collection != null) ...[
                _rootSection(collection),
                for (final folder in _childFolders(collection, null))
                  _folderTile(collection, folder, depth: 0),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _rootSection(ApiCollection collection) {
    final rootRequests =
        collection.requests
            .where((request) => request.folderId == null)
            .toList();
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.only(left: 12, right: 4),
      leading: const Icon(Icons.source_outlined, size: 18),
      title: const Text('Collection root'),
      trailing: IconButton(
        tooltip: 'Add request at root',
        icon: const Icon(Icons.add, size: 18),
        onPressed: () => _createRequest(folderId: null),
      ),
      onExpansionChanged: (_) => _selectedFolderId = null,
      children: [for (final request in rootRequests) _requestTile(request)],
    );
  }

  Widget _folderTile(
    ApiCollection collection,
    ApiFolder folder, {
    required int depth,
  }) {
    final childFolders = _childFolders(collection, folder.id);
    final childRequests =
        collection.requests
            .where((request) => request.folderId == folder.id)
            .toList();
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.only(left: 12.0 + depth * 14, right: 4),
      leading: const Icon(Icons.folder_outlined, size: 18),
      title: Text(folder.name, overflow: TextOverflow.ellipsis),
      trailing: Wrap(
        spacing: 2,
        children: [
          IconButton(
            tooltip: 'Rename folder',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _renameFolder(folder),
          ),
          IconButton(
            tooltip: 'Add request',
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _createRequest(folderId: folder.id),
          ),
        ],
      ),
      onExpansionChanged: (_) => _selectedFolderId = folder.id,
      children: [
        for (final child in childFolders)
          _folderTile(collection, child, depth: depth + 1),
        for (final request in childRequests) _requestTile(request),
      ],
    );
  }

  Widget _requestTile(ApiRequest request) {
    return ListTile(
      selected: request.id == _selectedRequestId,
      dense: true,
      leading: _methodLabel(request.method),
      title: Text(request.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(request.url, overflow: TextOverflow.ellipsis),
      onTap: () => _selectRequest(request.id),
    );
  }

  Widget _methodLabel(String method) {
    final color = _methodColor(method);
    return SizedBox(
      width: 54,
      child: Text(
        method,
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  List<ApiFolder> _childFolders(ApiCollection collection, String? parentId) {
    return collection.folders
        .where((folder) => folder.parentId == parentId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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
          _openTabs(),
          const SizedBox(height: 8),
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
                              child: Text(
                                method,
                                style: TextStyle(color: _methodColor(method)),
                              ),
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
              ButtonSegment(value: 1, label: Text('Authorization')),
              ButtonSegment(value: 2, label: Text('Headers')),
              ButtonSegment(value: 3, label: Text('Body')),
              ButtonSegment(value: 4, label: Text('Pre-request')),
              ButtonSegment(value: 5, label: Text('Tests')),
              ButtonSegment(value: 6, label: Text('Settings')),
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
              1 => _authEditor(),
              2 => _headersEditor(request),
              3 => _bodyEditor(),
              4 => _placeholderPanel(
                'Pre-request scripts',
                'Pre-request scripting is planned. Variables and built-ins already work in URL, headers, params, and body.',
              ),
              5 => _placeholderPanel(
                'Tests',
                'Response assertions and report export are planned for the runner.',
              ),
              _ => _settingsPanel(),
            },
          ),
        ],
      ),
    );
  }

  Widget _openTabs() {
    final collection = _selectedCollection;
    if (collection == null || _openRequestIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final openRequests = [
      for (final id in _openRequestIds)
        if (collection.requests.where((request) => request.id == id).firstOrNull
            case final request?)
          request,
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: openRequests.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final request = openRequests[index];
          final active = request.id == _selectedRequestId;
          return InputChip(
            selected: active,
            avatar: _methodLabel(request.method),
            label: Text(request.name, overflow: TextOverflow.ellipsis),
            onPressed: () => _selectRequest(request.id),
            onDeleted:
                openRequests.length == 1
                    ? null
                    : () => _closeRequestTab(request.id),
          );
        },
      ),
    );
  }

  Widget _headersEditor(ApiRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showHeaderTemplateMenu(request),
              icon: const Icon(Icons.article_outlined, size: 16),
              label: const Text('Templates'),
            ),
            OutlinedButton.icon(
              onPressed: () => _bulkEditHeaders(request),
              icon: const Icon(Icons.view_headline, size: 16),
              label: const Text('Bulk edit'),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyRequestCurl(request),
              icon: const Icon(Icons.terminal, size: 16),
              label: const Text('Copy cURL'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _keyValueEditor(
            'Headers',
            request.headers,
            (values) =>
                _updateSelectedRequest(request.copyWith(headers: values)),
          ),
        ),
      ],
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
            itemCount: values.length + 1,
            itemBuilder: (context, index) {
              final isNewRow = index == values.length;
              final item =
                  isNewRow
                      ? const ApiKeyValue(key: '', value: '', enabled: true)
                      : values[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Checkbox(
                      value: item.enabled,
                      onChanged:
                          isNewRow
                              ? null
                              : (value) => onChanged(
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
                        onChanged: (value) {
                          if (isNewRow) {
                            if (value.trim().isNotEmpty) {
                              onChanged([...values, item.copyWith(key: value)]);
                            }
                            return;
                          }
                          onChanged(
                            _replace(values, index, item.copyWith(key: value)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextFormField(
                        initialValue: item.value,
                        decoration: const InputDecoration(labelText: 'Value'),
                        onChanged: (value) {
                          if (isNewRow) {
                            if (value.trim().isNotEmpty) {
                              onChanged([
                                ...values,
                                item.copyWith(value: value),
                              ]);
                            }
                            return;
                          }
                          onChanged(
                            _replace(
                              values,
                              index,
                              item.copyWith(value: value),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextFormField(
                        initialValue: item.description,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        onChanged:
                            isNewRow
                                ? null
                                : (value) => onChanged(
                                  _replace(
                                    values,
                                    index,
                                    item.copyWith(description: value),
                                  ),
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Duplicate row',
                      onPressed:
                          isNewRow
                              ? null
                              : () => onChanged([
                                ...values.take(index + 1),
                                item.copyWith(),
                                ...values.skip(index + 1),
                              ]),
                      icon: const Icon(Icons.copy, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Delete row',
                      onPressed:
                          isNewRow
                              ? null
                              : () => onChanged(_removeAt(values, index)),
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
    final statusColor = _statusColor(response?.statusCode);
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
                  backgroundColor: statusColor.withValues(alpha: 0.16),
                  label: Text(
                    '${response.statusCode ?? '-'} ${response.reasonPhrase}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Chip(label: Text('${response.durationMs} ms')),
                const SizedBox(width: 6),
                Chip(label: Text('${response.sizeBytes} bytes')),
                IconButton(
                  tooltip: 'Copy body',
                  onPressed:
                      () => Clipboard.setData(
                        ClipboardData(text: response.bodyText),
                      ),
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  tooltip: 'Copy request as cURL',
                  onPressed:
                      _selectedRequest == null
                          ? null
                          : () => _copyRequestCurl(
                            _draftRequest(_selectedRequest!),
                          ),
                  icon: const Icon(Icons.terminal),
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
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pretty', label: Text('Pretty JSON')),
                  ButtonSegment(value: 'raw', label: Text('Raw')),
                  ButtonSegment(value: 'preview', label: Text('Preview')),
                ],
                selected: {_responseBodyMode},
                showSelectedIcon: false,
                onSelectionChanged:
                    (value) => setState(() {
                      _responseBodyMode = value.first;
                    }),
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
            : switch (_responseBodyMode) {
              'pretty' => _prettyJson(response.bodyText),
              'preview' => _previewText(response.bodyText),
              _ => response.bodyText,
            };
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
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed:
                _history.isEmpty
                    ? null
                    : () {
                      setState(() => _history = []);
                      unawaited(_saveWorkspace());
                    },
            icon: const Icon(Icons.delete_sweep, size: 16),
            label: const Text('Clear history'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final item = _history[index];
              final color = _statusColor(item.responseSnapshot.statusCode);
              return ListTile(
                dense: true,
                leading: _methodLabel(item.requestSnapshot.method),
                title: Text(
                  item.requestSnapshot.url,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item.responseSnapshot.statusCode ?? '-'} • ${item.responseSnapshot.durationMs} ms • ${item.responseSnapshot.receivedAt.toLocal()}',
                ),
                trailing: Icon(Icons.circle, color: color, size: 10),
                onTap:
                    () => setState(() {
                      _response = item.responseSnapshot;
                      _responseTab = 0;
                    }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholderPanel(String title, String message) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _settingsPanel() {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.timer_outlined),
          title: Text('Timeout'),
          subtitle: Text('Requests use a 30 second timeout for this phase.'),
        ),
        ListTile(
          leading: Icon(Icons.alt_route),
          title: Text('Redirects'),
          subtitle: Text(
            'Dio follows redirects by default. Per-request controls are planned.',
          ),
        ),
        ListTile(
          leading: Icon(Icons.security_outlined),
          title: Text('SSL verification'),
          subtitle: Text(
            'Custom SSL verification controls are planned for desktop builds.',
          ),
        ),
      ],
    );
  }

  Future<void> _showHeaderTemplateMenu(ApiRequest request) async {
    final selected = await showMenu<ApiKeyValue>(
      context: context,
      position: const RelativeRect.fromLTRB(360, 180, 24, 24),
      items: [
        for (final template in _headerTemplates())
          PopupMenuItem(
            value: template,
            child: Text('${template.key}: ${template.value}'),
          ),
      ],
    );
    if (selected == null) return;
    _insertHeaderTemplate(request, selected);
  }

  void _insertHeaderTemplate(ApiRequest request, ApiKeyValue template) {
    final existingIndex = request.headers.indexWhere(
      (header) => header.key.toLowerCase() == template.key.toLowerCase(),
    );
    final nextHeaders = [...request.headers];
    if (existingIndex >= 0) {
      nextHeaders[existingIndex] = template;
      _status = 'Header template replaced existing ${template.key}.';
    } else {
      nextHeaders.add(template);
      _status = 'Header template added: ${template.key}.';
    }
    _updateSelectedRequest(request.copyWith(headers: nextHeaders));
  }

  Future<void> _bulkEditHeaders(ApiRequest request) async {
    final controller = TextEditingController(
      text: request.headers
          .where((header) => header.key.trim().isNotEmpty)
          .map((header) => '${header.key}: ${header.value}')
          .join('\n'),
    );
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bulk edit headers'),
            content: SizedBox(
              width: 640,
              child: TextField(
                controller: controller,
                minLines: 10,
                maxLines: 18,
                decoration: const InputDecoration(
                  hintText:
                      r'Accept: application/json'
                      '\n'
                      r'X-Request-Id={{$uuid}}',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  _updateSelectedRequest(
                    request.copyWith(
                      headers: _parseBulkKeyValues(controller.text),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
    controller.dispose();
  }

  Future<void> _copyRequestCurl(ApiRequest request) async {
    final curl = _requestToCurl(_draftRequest(request));
    await Clipboard.setData(ClipboardData(text: curl));
    if (mounted) setState(() => _status = 'Copied request as cURL.');
  }

  Future<String?> _promptText(
    String title,
    String label, {
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: label),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    controller.dispose();
    return value?.trim();
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
      _openRequestIds = [collection.requests.first.id];
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
      _openRequestIds =
          (json['openRequestIds'] as List?)
              ?.map((item) => item.toString())
              .where((id) => id.isNotEmpty)
              .toList() ??
          [
            if (_selectedRequestId != null && _selectedRequestId!.isNotEmpty)
              _selectedRequestId!,
          ];
      _selectedEnvironmentId = json['selectedEnvironmentId']?.toString();
    }
    if (_selectedRequest == null) {
      _selectedRequestId = _collections.first.requests.firstOrNull?.id;
    }
    if (_selectedRequestId != null &&
        !_openRequestIds.contains(_selectedRequestId)) {
      _openRequestIds = [..._openRequestIds, _selectedRequestId!];
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
      'openRequestIds': _openRequestIds,
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
      final uri = Uri.tryParse(resolved.url);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        throw const FormatException('Enter a valid http:// or https:// URL.');
      }
      final response = await _dio.request<dynamic>(
        resolved.url,
        data: resolved.data,
        queryParameters: resolved.queryParameters,
        options: Options(
          method: request.method,
          headers: resolved.headers,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: true,
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
      final body = _substitute(request.body, variables);
      if (body.trim().isNotEmpty) {
        try {
          data = jsonDecode(body);
        } on FormatException {
          throw const FormatException('JSON body is not valid.');
        }
      }
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
      'timestamp': '${now.millisecondsSinceEpoch ~/ 1000}',
      'timestampMs': '${now.millisecondsSinceEpoch}',
      'isoTime': now.toIso8601String(),
      'uuid': _uuidLike(),
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
      _selectedFolderId = null;
      _openRequestIds = [collection.requests.first.id];
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
      _selectedFolderId = null;
      _openRequestIds = [
        if (collection.requests.firstOrNull case final request?) request.id,
      ];
      _syncEditors();
    });
  }

  void _createRequest({String? folderId}) {
    final collection = _selectedCollection;
    if (collection == null) return;
    final request = ApiRequest.defaults(
      collection.id,
    ).copyWith(folderId: folderId);
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
      _selectedFolderId = folderId;
      _openRequestIds = [..._openRequestIds, request.id];
      _syncEditors();
    });
    unawaited(_saveWorkspace());
  }

  void _selectRequest(String id) {
    setState(() {
      _selectedRequestId = id;
      if (!_openRequestIds.contains(id)) {
        _openRequestIds = [..._openRequestIds, id];
      }
      _syncEditors();
    });
    unawaited(_saveWorkspace());
  }

  void _closeRequestTab(String id) {
    final next = _openRequestIds.where((item) => item != id).toList();
    setState(() {
      _openRequestIds = next;
      if (_selectedRequestId == id) {
        _selectedRequestId =
            next.firstOrNull ?? _selectedCollection?.requests.firstOrNull?.id;
        _syncEditors();
      }
    });
    unawaited(_saveWorkspace());
  }

  Future<void> _createFolder() async {
    final collection = _selectedCollection;
    if (collection == null) return;
    final name = await _promptText('Create folder', 'Folder name');
    if (name == null || name.isEmpty) return;
    final folder = ApiFolder(
      id: _newId('folder'),
      collectionId: collection.id,
      parentId: _selectedFolderId,
      name: name,
      sortOrder: collection.folders.length,
    );
    _collections = [
      for (final item in _collections)
        if (item.id == collection.id)
          collection.copyWith(
            folders: [...collection.folders, folder],
            updatedAt: DateTime.now(),
          )
        else
          item,
    ];
    setState(() => _selectedFolderId = folder.id);
    unawaited(_saveWorkspace());
  }

  Future<void> _renameFolder(ApiFolder folder) async {
    final collection = _selectedCollection;
    if (collection == null) return;
    final name = await _promptText(
      'Rename folder',
      'Folder name',
      initial: folder.name,
    );
    if (name == null || name.isEmpty) return;
    _collections = [
      for (final item in _collections)
        if (item.id == collection.id)
          collection.copyWith(
            folders: [
              for (final current in collection.folders)
                if (current.id == folder.id)
                  current.copyWith(name: name)
                else
                  current,
            ],
            updatedAt: DateTime.now(),
          )
        else
          item,
    ];
    setState(() {});
    unawaited(_saveWorkspace());
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
      _openRequestIds = [..._openRequestIds, copy.id];
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
      _openRequestIds =
          _openRequestIds.where((id) => id != request.id).toList();
      if (_selectedRequestId != null &&
          !_openRequestIds.contains(_selectedRequestId)) {
        _openRequestIds = [..._openRequestIds, _selectedRequestId!];
      }
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
    var environments =
        _environments.isEmpty
            ? const [
              ApiEnvironment(id: 'default_env', name: 'Local', variables: []),
            ]
            : [..._environments];
    var selectedId = _selectedEnvironmentId ?? environments.first.id;
    var variables =
        environments
            .where((env) => env.id == selectedId)
            .firstOrNull
            ?.variables
            .toList() ??
        <ApiKeyValue>[];
    await showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Manage environments'),
                  content: SizedBox(
                    width: 820,
                    height: 480,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 240,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ListView(
                                  children: [
                                    for (final env in environments)
                                      ListTile(
                                        selected: env.id == selectedId,
                                        dense: true,
                                        title: Text(env.name),
                                        onTap:
                                            () => setDialogState(() {
                                              selectedId = env.id;
                                              variables = [...env.variables];
                                            }),
                                      ),
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                children: [
                                  IconButton(
                                    tooltip: 'Create environment',
                                    onPressed:
                                        () => setDialogState(() {
                                          final env = ApiEnvironment(
                                            id: _newId('env'),
                                            name:
                                                'Environment ${environments.length + 1}',
                                            variables: const [],
                                          );
                                          environments = [...environments, env];
                                          selectedId = env.id;
                                          variables = [];
                                        }),
                                    icon: const Icon(Icons.add),
                                  ),
                                  IconButton(
                                    tooltip: 'Rename environment',
                                    onPressed: () async {
                                      final env =
                                          environments
                                              .where(
                                                (item) => item.id == selectedId,
                                              )
                                              .firstOrNull;
                                      if (env == null) return;
                                      final name = await _promptText(
                                        'Rename environment',
                                        'Environment name',
                                        initial: env.name,
                                      );
                                      if (name == null || name.isEmpty) return;
                                      setDialogState(() {
                                        environments = [
                                          for (final item in environments)
                                            if (item.id == env.id)
                                              ApiEnvironment(
                                                id: item.id,
                                                name: name,
                                                variables: item.variables,
                                              )
                                            else
                                              item,
                                        ];
                                      });
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Duplicate environment',
                                    onPressed: () {
                                      final env =
                                          environments
                                              .where(
                                                (item) => item.id == selectedId,
                                              )
                                              .firstOrNull;
                                      if (env == null) return;
                                      setDialogState(() {
                                        final copy = ApiEnvironment(
                                          id: _newId('env'),
                                          name: '${env.name} Copy',
                                          variables: [...env.variables],
                                        );
                                        environments = [...environments, copy];
                                        selectedId = copy.id;
                                        variables = [...copy.variables];
                                      });
                                    },
                                    icon: const Icon(Icons.copy),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete environment',
                                    onPressed:
                                        environments.length <= 1
                                            ? null
                                            : () => setDialogState(() {
                                              environments =
                                                  environments
                                                      .where(
                                                        (env) =>
                                                            env.id !=
                                                            selectedId,
                                                      )
                                                      .toList();
                                              selectedId =
                                                  environments.first.id;
                                              variables = [
                                                ...environments.first.variables,
                                              ];
                                            }),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: _keyValueEditor(
                              'Variables',
                              variables,
                              (value) => setDialogState(() {
                                variables = value;
                                environments = [
                                  for (final env in environments)
                                    if (env.id == selectedId)
                                      ApiEnvironment(
                                        id: env.id,
                                        name: env.name,
                                        variables: variables,
                                      )
                                    else
                                      env,
                                ];
                              }),
                            ),
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
                        _environments = environments;
                        _selectedEnvironmentId = selectedId;
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
                            DropdownMenuItem(
                              value: 'curl',
                              child: Text('cURL request'),
                            ),
                            DropdownMenuItem(
                              value: 'bruno',
                              child: Text('Bruno JSON export'),
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
                          if (mode == 'curl') {
                            _importCurl(controller.text);
                          }
                          if (mode == 'bruno') {
                            _importBrunoJson(controller.text);
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
    final folders = <ApiFolder>[];
    void visit(List items, String? parentFolderId) {
      for (final item in items.whereType<Map>()) {
        if (item['request'] is Map) {
          requests.add(
            _postmanRequest(
              Map<String, dynamic>.from(item),
              collectionId,
              parentFolderId,
            ),
          );
        } else if (item['item'] is List) {
          final folder = ApiFolder(
            id: _newId('folder'),
            collectionId: collectionId,
            parentId: parentFolderId,
            name: (item['name'] ?? 'Folder').toString(),
            sortOrder: folders.length,
          );
          folders.add(folder);
          visit(item['item'] as List, folder.id);
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
      folders: folders,
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
    String? folderId,
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
      folderId: folderId,
      name: (item['name'] ?? 'Request').toString(),
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
    final rows = _parseCsv(text);
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

  void _importBrunoJson(String text) {
    final json = jsonDecode(text);
    if (json is! Map) {
      throw const FormatException('Expected Bruno JSON object.');
    }
    final name =
        (json['name'] ?? _map(json['meta'])['name'] ?? 'Imported Bruno Request')
            .toString();
    final collection = _selectedCollection ?? ApiCollection.defaults();
    if (_selectedCollection == null) {
      _collections = [collection];
      _selectedCollectionId = collection.id;
    }
    final request = ApiRequest.defaults(collection.id).copyWith(
      name: name,
      method:
          (json['method'] ?? _map(json['request'])['method'] ?? 'GET')
              .toString()
              .toUpperCase(),
      url: (json['url'] ?? _map(json['request'])['url'] ?? '').toString(),
      body: (json['body'] ?? _map(json['request'])['body'] ?? '').toString(),
      updatedAt: DateTime.now(),
    );
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
      _openRequestIds = [..._openRequestIds, request.id];
      _status = 'Imported Bruno JSON request. Folder import is planned.';
      _syncEditors();
    });
    unawaited(_saveWorkspace());
  }

  void _importCurl(String text) {
    final request = _requestFromCurl(text);
    final collection = _selectedCollection;
    if (collection == null || request == null) {
      throw const FormatException('Could not parse cURL request.');
    }
    final next = request.copyWith(collectionId: collection.id);
    _collections = [
      for (final item in _collections)
        if (item.id == collection.id)
          collection.copyWith(
            requests: [...collection.requests, next],
            updatedAt: DateTime.now(),
          )
        else
          item,
    ];
    setState(() {
      _selectedRequestId = next.id;
      _openRequestIds = [..._openRequestIds, next.id];
      _syncEditors();
      _status = 'Imported cURL request.';
    });
    unawaited(_saveWorkspace());
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
    List<Map<String, dynamic>> folderItems(String? parentId) {
      final items = <Map<String, dynamic>>[];
      for (final folder in _childFolders(collection, parentId)) {
        items.add({'name': folder.name, 'item': folderItems(folder.id)});
      }
      for (final request in collection.requests.where(
        (request) => request.folderId == parentId,
      )) {
        items.add(_postmanRequestExport(request));
      }
      return items;
    }

    return {
      'info': {
        'name': collection.name,
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
      },
      'item': folderItems(null),
    };
  }

  Map<String, dynamic> _postmanRequestExport(ApiRequest request) {
    return {
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
                    if (item.description.isNotEmpty)
                      'description': item.description,
                  },
                )
                .toList(),
        'url': {
          'raw': request.url,
          'query':
              request.queryParams
                  .map(
                    (item) => {
                      'key': item.key,
                      'value': item.value,
                      'disabled': !item.enabled,
                    },
                  )
                  .toList(),
        },
        'body': {
          'mode':
              request.bodyType == ApiBodyType.formUrlEncoded
                  ? 'urlencoded'
                  : 'raw',
          'raw': request.body,
        },
      },
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

  List<ApiKeyValue> _parseBulkKeyValues(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final colon = line.indexOf(':');
          final equals = line.indexOf('=');
          final split =
              colon >= 0 ? colon : (equals >= 0 ? equals : line.length);
          return ApiKeyValue(
            key: line.substring(0, split).trim(),
            value: split >= line.length ? '' : line.substring(split + 1).trim(),
          );
        })
        .where((item) => item.key.isNotEmpty)
        .toList();
  }

  List<ApiKeyValue> _headerTemplates() {
    return const [
      ApiKeyValue(
        key: 'Accept',
        value: 'application/json',
        description: 'Prefer JSON responses.',
      ),
      ApiKeyValue(
        key: 'Content-Type',
        value: 'application/json',
        description: 'Send JSON request body.',
      ),
      ApiKeyValue(
        key: 'Content-Type',
        value: 'application/x-www-form-urlencoded',
        description: 'Send form URL encoded body.',
      ),
      ApiKeyValue(
        key: 'Authorization',
        value: 'Bearer {{token}}',
        description: 'Bearer token variable template.',
      ),
      ApiKeyValue(
        key: 'User-Agent',
        value: 'TestDeck/1.0.0',
        description: 'Identify TestDeck requests.',
      ),
      ApiKeyValue(
        key: 'X-Request-Id',
        value: r'{{$uuid}}',
        description: 'Unique request correlation ID.',
      ),
      ApiKeyValue(
        key: 'Cache-Control',
        value: 'no-cache',
        description: 'Bypass cached responses.',
      ),
    ];
  }

  String _requestToCurl(ApiRequest request) {
    final parts = ['curl', '-X', request.method, _shellQuote(request.url)];
    for (final header in request.headers.where(
      (item) => item.enabled && item.key.trim().isNotEmpty,
    )) {
      parts.addAll(['-H', _shellQuote('${header.key}: ${header.value}')]);
    }
    if (request.body.trim().isNotEmpty &&
        request.bodyType != ApiBodyType.none) {
      parts.addAll(['--data', _shellQuote(request.body)]);
    }
    return parts.join(' ');
  }

  ApiRequest? _requestFromCurl(String text) {
    final tokens = _splitCommandLine(text);
    if (tokens.isEmpty || tokens.first != 'curl') return null;
    var method = 'GET';
    var url = '';
    var body = '';
    final headers = <ApiKeyValue>[];
    for (var i = 1; i < tokens.length; i++) {
      final token = tokens[i];
      if ((token == '-X' || token == '--request') && i + 1 < tokens.length) {
        method = tokens[++i].toUpperCase();
      } else if ((token == '-H' || token == '--header') &&
          i + 1 < tokens.length) {
        final header = tokens[++i];
        final split = header.indexOf(':');
        if (split > 0) {
          headers.add(
            ApiKeyValue(
              key: header.substring(0, split).trim(),
              value: header.substring(split + 1).trim(),
            ),
          );
        }
      } else if ((token == '-d' ||
              token == '--data' ||
              token == '--data-raw' ||
              token == '--data-binary') &&
          i + 1 < tokens.length) {
        body = tokens[++i];
        if (method == 'GET') method = 'POST';
      } else if (!token.startsWith('-')) {
        url = token;
      }
    }
    if (url.isEmpty) return null;
    return ApiRequest.defaults(_selectedCollection?.id ?? '').copyWith(
      id: _newId('request'),
      name: 'Imported cURL',
      method: method,
      url: url,
      headers: headers.isEmpty ? _defaultRequestHeaders() : headers,
      bodyType: body.trim().isEmpty ? ApiBodyType.none : ApiBodyType.raw,
      body: body,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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

const Object _notSet = Object();

List<ApiKeyValue> _defaultRequestHeaders() {
  return const [
    ApiKeyValue(
      key: 'Accept',
      value: 'application/json',
      enabled: true,
      description: 'Default JSON response preference.',
    ),
    ApiKeyValue(
      key: 'Content-Type',
      value: 'application/json',
      enabled: false,
      description: 'Enable for JSON request bodies.',
    ),
    ApiKeyValue(
      key: 'Authorization',
      value: 'Bearer {{token}}',
      enabled: false,
      description: 'Enable and define token in an environment.',
    ),
  ];
}

Color _methodColor(String method) {
  return switch (method.toUpperCase()) {
    'GET' => const Color(0xFF059669),
    'POST' => const Color(0xFF2563EB),
    'PUT' => const Color(0xFFD97706),
    'PATCH' => const Color(0xFF7C3AED),
    'DELETE' => const Color(0xFFDC2626),
    _ => const Color(0xFF475569),
  };
}

Color _statusColor(int? statusCode) {
  if (statusCode == null) return const Color(0xFFDC2626);
  if (statusCode >= 200 && statusCode < 300) return const Color(0xFF059669);
  if (statusCode >= 300 && statusCode < 400) return const Color(0xFF2563EB);
  if (statusCode >= 400 && statusCode < 500) return const Color(0xFFD97706);
  return const Color(0xFFDC2626);
}

String _previewText(String text) {
  final pretty = _prettyJson(text);
  if (pretty.length <= 12000) return pretty;
  return '${pretty.substring(0, 12000)}\n\n...preview truncated...';
}

List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  final current = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    final next = i + 1 < text.length ? text[i + 1] : '';
    if (char == '"' && inQuotes && next == '"') {
      cell.write('"');
      i++;
    } else if (char == '"') {
      inQuotes = !inQuotes;
    } else if (char == ',' && !inQuotes) {
      current.add(cell.toString());
      cell.clear();
    } else if ((char == '\n' || char == '\r') && !inQuotes) {
      if (char == '\r' && next == '\n') i++;
      current.add(cell.toString());
      cell.clear();
      if (current.any((value) => value.trim().isNotEmpty)) {
        rows.add([...current]);
      }
      current.clear();
    } else {
      cell.write(char);
    }
  }
  current.add(cell.toString());
  if (current.any((value) => value.trim().isNotEmpty)) rows.add(current);
  return rows;
}

String _shellQuote(String value) {
  return "'${value.replaceAll("'", r"'\''")}'";
}

List<String> _splitCommandLine(String input) {
  final tokens = <String>[];
  final current = StringBuffer();
  String? quote;
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if ((char == '"' || char == "'") && quote == null) {
      quote = char;
    } else if (char == quote) {
      quote = null;
    } else if (char.trim().isEmpty && quote == null) {
      if (current.isNotEmpty) {
        tokens.add(current.toString());
        current.clear();
      }
    } else if (char == '\\' && i + 1 < input.length) {
      current.write(input[++i]);
    } else {
      current.write(char);
    }
  }
  if (current.isNotEmpty) tokens.add(current.toString());
  return tokens;
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
