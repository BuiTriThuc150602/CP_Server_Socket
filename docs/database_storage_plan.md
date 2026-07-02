# Database Storage Plan

This project currently persists user data as JSON documents in the application
support directory. The next storage step should keep JSON loading in place while
adding SQLite/Drift tables gradually behind `AppStorage`.

## Goals

- Preserve existing JSON files and CarParking workspace data.
- Add scalable storage for API Lab collections, history, environments, and
  module configs.
- Avoid a risky one-shot migration of every current module.

## Proposed Tables

### `workspaces`

- `id`
- `name`
- `created_at`
- `updated_at`

### `collections`

- `id`
- `workspace_id`
- `name`
- `sort_order`
- `created_at`
- `updated_at`

### `folders`

- `id`
- `collection_id`
- `parent_id`
- `name`
- `sort_order`

### `requests`

- `id`
- `collection_id`
- `folder_id`
- `name`
- `method`
- `url`
- `headers_json`
- `query_params_json`
- `body_type`
- `body`
- `auth_json`
- `created_at`
- `updated_at`

### `environments`

- `id`
- `workspace_id`
- `name`
- `variables_json`
- `created_at`
- `updated_at`

### `variables`

- `id`
- `environment_id`
- `key`
- `value`
- `enabled`
- `secret`

### `history_entries`

- `id`
- `request_id`
- `request_snapshot_json`
- `response_snapshot_json`
- `created_at`

### `binary_assets`

- `id`
- `workspace_id`
- `name`
- `mime_type`
- `relative_path`
- `size_bytes`
- `created_at`

### `module_configs`

- `module_key`
- `value_json`
- `updated_at`

### `terminal_sessions`

- `id`
- `workspace_id`
- `shell`
- `cwd`
- `last_output_path`
- `created_at`
- `updated_at`

### `carparking_workspaces`

- `id`
- `name`
- `value_json`
- `created_at`
- `updated_at`

## Migration Strategy

1. Keep `JsonFileAppStorage` as the default implementation.
2. Add a Drift-backed `AppStorage` implementation later.
3. On first DB launch, copy each known JSON document into `module_configs` or
   the module-specific table while keeping the original JSON file.
4. Read from DB when present; otherwise fall back to JSON.
5. Only delete or archive JSON files after an explicit export/backup workflow
   exists.
