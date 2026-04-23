#!/bin/bash
set -euo pipefail

# Zeta4G Pro — 호스트 데이터를 Docker 볼륨으로 마이그레이션
# 사용법: ./migrate-to-volume.sh /path/to/host/data

CONTAINER_NAME="zeta4g-pro"
VOLUME_NAME="zeta4g-data"
IMAGE="zeta4lab/zeta4g-pro:2.7.7"
DATA_DIR="/data"

HOST_DATA="${1:-$HOME/.zeta4g}"

if [ ! -d "$HOST_DATA" ]; then
  echo "❌ 경로를 찾을 수 없습니다: $HOST_DATA"
  exit 1
fi

echo "=== Zeta4G Pro 마이그레이션 ==="
echo "  호스트 데이터: $HOST_DATA"
echo "  대상 볼륨:    $VOLUME_NAME"
echo "  이미지:       $IMAGE"
echo ""

# 1. 현재 상태 백업
echo "[1/6] 호스트 데이터 백업..."
BACKUP="${HOST_DATA}.backup.$(date +%Y%m%d-%H%M%S)"
cp -a "$HOST_DATA" "$BACKUP"
echo "  → 백업 완료: $BACKUP"

# 2. 실행 중인 컨테이너 정지
echo "[2/6] 기존 컨테이너 정지..."
if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
  docker stop "$CONTAINER_NAME"
  echo "  → 정지 완료"
else
  echo "  → 실행 중인 컨테이너 없음"
fi

# 3. 볼륨 생성 (없으면)
echo "[3/6] 볼륨 확인..."
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
  docker volume create "$VOLUME_NAME"
  echo "  → 볼륨 생성됨"
else
  echo "  → 볼륨 이미 존재"
fi

# 4. 임시 컨테이너로 데이터 복사
echo "[4/6] 호스트 데이터를 볼륨으로 복사..."
# 임시 컨테이너 생성 (볼륨 마운트)
docker run -d --name zeta4g-migrate \
  -v "$VOLUME_NAME":"$DATA_DIR" \
  "$IMAGE" sleep 3600

# 기존 볼륨 데이터 확인
echo "  현재 볼륨 내용:"
docker exec zeta4g-migrate ls -la "$DATA_DIR" || true

# 호스트 데이터를 컨테이너로 복사
docker cp "$HOST_DATA/." "zeta4g-migrate:$DATA_DIR/"
echo "  → 복사 완료"

# 복사 결과 확인
echo "  복사 후 볼륨 내용:"
docker exec zeta4g-migrate ls -la "$DATA_DIR"

# databases 디렉토리 확인
if docker exec zeta4g-migrate test -d "$DATA_DIR/databases"; then
  echo "  ✅ databases 디렉토리 확인됨"
  docker exec zeta4g-migrate ls -la "$DATA_DIR/databases"
else
  echo "  ⚠️  databases 디렉토리 없음 — init이 필요할 수 있습니다"
fi

# 임시 컨테이너 정리
docker rm -f zeta4g-migrate
echo "  → 임시 컨테이너 정리 완료"

# 5. 기존 컨테이너 제거
echo "[5/6] 기존 컨테이너 제거..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# 6. 새 버전으로 시작
echo "[6/6] v2.7.7 컨테이너 시작..."
docker compose pull
docker compose up -d

echo ""
echo "=== 마이그레이션 완료 ==="
echo ""

# 결과 확인
sleep 3
echo "[확인] 컨테이너 상태:"
docker compose ps
echo ""
echo "[확인] 최근 로그:"
docker compose logs --tail=20
echo ""
echo "백업 위치: $BACKUP"
echo "문제 발생 시 백업에서 복원 가능합니다."
