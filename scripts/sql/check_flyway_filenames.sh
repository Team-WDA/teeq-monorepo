#!/usr/bin/env bash
# Flyway 마이그레이션 파일명 규칙 검증: V{yyyyMMdd}_{HHmmss}__{snake_case}.sql
# 사용법: scripts/sql/check_flyway_filenames.sh [마이그레이션 디렉터리]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT="${1:-$REPO_ROOT/backend/src/main/resources/db/migration}"

if [[ ! -d "$ROOT" ]]; then
  echo "❌ 디렉터리를 찾을 수 없습니다: $ROOT"
  exit 2
fi

bad=0
while IFS= read -r -d '' file; do
  base=$(basename "$file")
  if [[ ! "$base" =~ ^V[0-9]{8}_[0-9]{6}__[a-z0-9_]+\.sql$ ]]; then
    echo "❌ 잘못된 파일명: $file"
    bad=1
  fi
done < <(find "$ROOT" -type f -name '*.sql' -print0)

if [[ $bad -eq 0 ]]; then
  echo "✅ 모든 마이그레이션 파일명이 규칙을 따릅니다: $ROOT"
fi
exit $bad
