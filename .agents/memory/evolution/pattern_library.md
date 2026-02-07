---
description: 代码模式库 - 存储可复用的代码模式和模板
version: 1.0
last_updated: 2026-02-08
---

# Pattern Library (代码模式库)

本文件存储从项目中识别出的可复用代码模式。

## 1. 模式索引 (Pattern Index)

| ID | Name | Category | Occurrences | Confidence | Status |
|----|------|----------|-------------|------------|--------|
| P-000 | (示例) Repository Cache Pattern | data-layer | 3 | 0.9 | active |

## 2. 模式分类 (Categories)

| Category | Description | Count |
|----------|-------------|-------|
| data-layer | 数据层模式（Repository, Cache, API） | 0 |
| ui-layer | UI 层模式（Widget, State, Animation） | 0 |
| business-logic | 业务逻辑模式（ViewModel, UseCase） | 0 |
| common | 通用模式（Error Handling, Logging） | 0 |

---

## 3. 模式详情 (Pattern Details)

### P-000: Repository Cache Pattern (示例)

**Category**: data-layer  
**Occurrences**: 0  
**Confidence**: 0.0  
**First Seen**: 2026-02-08  
**Files**: (暂无)

**Description**:
> Repository 层统一缓存模式，避免重复请求。

**Template**:
```dart
class XxxRepository {
  final _cache = <String, dynamic>{};
  
  Future<T> getWithCache<T>(String key, Future<T> Function() fetch) async {
    if (_cache.containsKey(key)) return _cache[key] as T;
    final result = await fetch();
    _cache[key] = result;
    return result;
  }
  
  void invalidateCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }
}
```

**Usage**:
```dart
final data = await repository.getWithCache('user_profile', () => api.fetchProfile());
```

---

## 4. 模式匹配规则 (Detection Rules)

> 定义如何自动检测代码中的模式

### 规则格式
```yaml
pattern_id: P-xxx
triggers:
  - keyword: "getWithCache"
  - structure: "class.*Repository.*_cache"
min_occurrences: 3
```

---

## 5. 待验证模式 (Pending Patterns)

> 出现次数不足，暂未提升为正式模式

| ID | Name | Occurrences | Notes |
|----|------|-------------|-------|
| - | - | - | 暂无 |
