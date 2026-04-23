#!/bin/bash
set -euo pipefail

# Zeta4G Pro — 호스트 데이터를 Docker 볼륨으로 마이그레이션
# 사용법: ./migrate-to-volume.sh [호스트_데이터_경로]

CONTAINER_NAME="zeta4g-pro"
VOLUME_NAME="zeta4g-data"
IMAGE="zeta4lab/zeta4g-pro:2.7.7"
DATA_DIR="/data"

HOST_DATA="${1:-$HOME/.zeta4g}"

# 임시 컨테이너 정리 trap
cleanup() {
  docker rm -f zeta4g-migrate 2>/dev/null || true
}
trap cleanup EXIT

if [ ! -d "$HOST_DATA" ]; then
  echo "ERROR: 경로를 찾을 수 없습니다: $HOST_DATA"
  exit 1
fi

echo "=== Zeta4G Pro 마이그레이션 ==="
echo "  호스트 데이터: $HOST_DATA"
echo "  대상 볼륨:    $VOLUME_NAME"
echo "  이미지:       $IMAGE"
echo ""

# 1. 현재 상태 백업
echo "[1/7] 호스트 데이터 백업..."
BACKUP="${HOST_DATA}.backup.$(date +%Y%m%d-%H%M%S)"
if ! cp -a "$HOST_DATA" "$BACKUP"; then
  echo "ERROR: 백업 실패. 디스크 공간을 확인하세요: df -h $(dirname "$HOST_DATA")"
  rm -rf "$BACKUP"
  exit 1
fi
echo "  -> 백업 완료: $BACKUP"

# 2. 실행 중인 컨테이너 정지
echo "[2/7] 기존 컨테이너 정지..."
if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
  docker stop "$CONTAINER_NAME"
  echo "  -> 정지 완료"
else
  echo "  -> 실행 중인 컨테이너 없음"
fi

# 3. 이미지 pull (컨테이너 제거 전에 수행)
echo "[3/7] 이미지 가져오기..."
if ! docker pull "$IMAGE"; then
  echo "ERROR: 이미지 pull 실패. 네트워크를 확인하세요."
  echo "기존 컨테이너는 그대로 유지됩니다. 네트워크 복구 후 재실행하세요."
  exit 1
fi

# 4. 볼륨 생성 (없으면)
echo "[4/7] 볼륨 확인..."
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
  docker volume create "$VOLUME_NAME"
  echo "  -> 볼륨 생성됨"
else
  echo "  -> 볼륨 이미 존재"
fi

# 5. 임시 컨테이너로 데이터 복사
echo "[5/7] 호스트 데이터를 볼륨으로 복사..."
docker rm -f zeta4g-migrate 2>/dev/null || true

docker run -d --name zeta4g-migrate \
  --entrypoint "" \
  -v "$VOLUME_NAME":"$DATA_DIR" \
  "$IMAGE" sleep 3600

sleep 1
if [ "$(docker inspect -f '{{.State.Running}}' zeta4g-migrate)" != "true" ]; then
  echo "ERROR: 임시 컨테이너 시작 실패."
  docker logs zeta4g-migrate
  exit 1
fi

# 호스트 데이터를 컨테이너로 복사
docker cp "$HOST_DATA/." "zeta4g-migrate:$DATA_DIR/"

# 소유권 수정 (컨테이너 내 zeta4g 유저로)
docker exec zeta4g-migrate chown -R zeta4g:zeta4g "$DATA_DIR"

# 파일 수 비교로 무결성 확인
HOST_COUNT=$(find "$HOST_DATA" -type f | wc -l)
VOL_COUNT=$(docker exec zeta4g-migrate find "$DATA_DIR" -type f | wc -l)
echo "  파일 수 — 호스트: $HOST_COUNT, 볼륨: $VOL_COUNT"
if [ "$HOST_COUNT" -ne "$VOL_COUNT" ]; then
  echo "ERROR: 파일 수 불일치. 복사가 불완전합니다."
  echo "백업 위치: $BACKUP"
  exit 1
fi

# databases 디렉토리 필수 확인
if ! docker exec zeta4g-migrate test -d "$DATA_DIR/databases"; then
  echo "ERROR: databases 디렉토리 없음. 데이터가 올바르지 않습니다."
  echo "백업 위치: $BACKUP"
  exit 1
fi
echo "  -> 복사 및 검증 완료"

docker exec zeta4g-migrate ls -la "$DATA_DIR"
docker exec zeta4g-migrate ls -la "$DATA_DIR/databases"

# 임시 컨테이너 정리
docker rm -f zeta4g-migrate
echo "  -> 임시 컨테이너 정리 완료"

# 6. 기존 컨테이너 제거
echo "[6/7] 기존 컨테이너 제거..."
docker rm -f "$CONTAINER_NAME" || echo "  (기존 컨테이너 없음)"

# 7. 새 버전으로 시작
echo "[7/7] v2.7.7 컨테이너 시작..."
if ! docker compose up -d; then
  echo "ERROR: 컨테이너 시작 실패."
  echo "데이터는 볼륨 '$VOLUME_NAME'에 안전합니다."
  echo "디버그: docker compose logs"
  echo "재시도: docker compose up -d"
  exit 1
fi

echo ""
echo "=== 마이그레이션 완료 ==="
echo ""

# 결과 확인 — health check 대기
echo "[확인] 컨테이너 시작 대기..."
for i in $(seq 1 30); do
  if docker compose ps --format json 2>/dev/null | grep -q '"running"'; then
    echo "  -> 컨테이너 정상 실행 중"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "WARNING: 30초 내 시작 안됨. 로그를 확인하세요: docker compose logs"
  fi
  sleep 1
done

echo ""
docker compose ps
echo ""
echo "[확인] 최근 로그:"
docker compose logs --tail=20
echo ""
echo "백업 위치: $BACKUP"
echo "문제 발생 시 백업에서 복원 가능합니다."
