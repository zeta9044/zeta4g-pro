# Zeta4G Pro Edition

Zeta4G Pro Edition은 GraphRAG, 벡터 검색, LLM 통합을 지원하는 AI 그래프 데이터베이스 서버입니다.

Base Edition의 모든 기능에 더해 벡터 인덱스(HNSW), 그래프 임베딩, RAG 파이프라인, GraphRAG를 제공합니다.

## Downloads

[Releases](https://github.com/zeta9044/zeta4g-pro/releases) 페이지에서 최신 바이너리를 다운로드하세요.

| Platform | Architecture | 파일명 패턴 |
|----------|-------------|------------|
| macOS | Apple Silicon (M1/M2/M3/M4) | `zeta4g-pro-<version>-darwin-aarch64.tar.gz` |
| Linux | x86_64 (AMD/Intel) | `zeta4g-pro-<version>-linux-x86_64.tar.gz` |

## Docker

### Docker Hub

```bash
docker run -d --name zeta4g-pro \
  -p 9044:9044 -p 9045:9045 \
  -v zeta4g-data:/data \
  zeta4lab/zeta4g-pro:latest start --no-auth
```

### GitHub Container Registry

```bash
docker run -d --name zeta4g-pro \
  -p 9044:9044 -p 9045:9045 \
  -v zeta4g-data:/data \
  ghcr.io/zeta9044/zeta4g-pro:latest start --no-auth
```

### Docker Compose

```bash
curl -LO https://raw.githubusercontent.com/zeta9044/zeta4g-pro/main/docker-compose.yml
docker compose up -d
```

운영 환경에서는 `docker-compose.yml`의 `--no-auth`를 제거하세요.

## Quick Start

### 1. 다운로드 및 압축 해제

```bash
# macOS (Apple Silicon)
curl -LO https://github.com/zeta9044/zeta4g-pro/releases/latest/download/zeta4g-pro-darwin-aarch64.tar.gz
tar xzf zeta4g-pro-*-darwin-aarch64.tar.gz

# Linux (x86_64)
curl -LO https://github.com/zeta9044/zeta4g-pro/releases/latest/download/zeta4g-pro-linux-x86_64.tar.gz
tar xzf zeta4g-pro-*-linux-x86_64.tar.gz
```

```bash
cd zeta4g-pro-*
```

### 2. 데이터베이스 초기화

```bash
./zeta4gctl init --clean -y
```

### 3. 서버 시작

```bash
# 인증 없이 시작 (개발/테스트용)
./zeta4gctl start --no-auth

# 인증 활성화 (운영 환경)
./zeta4gctl start
```

기본 포트:
- **HTTP**: `9044`
- **Bolt**: `9045`
- **HTTPS**: `9043`

### 4. 쿼리 실행

```bash
# Cypher 쿼리
./zeta4gs "CREATE (p:Person {name: 'Alice', age: 30}) RETURN p"

# 벡터 검색
./zeta4g-vector search --index my_index --query "machine learning" --top-k 10

# RAG 질의
./zeta4g-rag query "그래프 데이터베이스의 장점은?"
```

### 5. 서버 중지

```bash
./zeta4gctl stop
```

## Binaries

| 바이너리 | 설명 |
|---------|------|
| `zeta4gd` | GraphRAG 서버 데몬 (Bolt + HTTP + RAG API) |
| `zeta4gs` | Cypher Shell (대화형 쿼리 CLI) |
| `zeta4gctl` | 서버 컨트롤 (init/start/stop/status) |
| `zeta4g-admin` | 관리 도구 (dump/load/user) |
| `zeta4g-onto` | 온톨로지/스키마 진화 관리 도구 |
| `zeta4g-index` | RAG 문서 인덱싱 (file/dir/s3/git/url) |
| `zeta4g-rag` | RAG 질의/대화 (query/chat/ner/text2cypher) |
| `zeta4g-model` | LLM/Embedding 프로바이더 관리 |
| `zeta4g-vector` | 벡터 인덱스 관리 (list/create/delete/search) |
| `zeta4g-fulltext` | 전문검색 인덱스 관리 |

## Pro Edition 핵심 기능

### 벡터 검색 (HNSW)

```bash
# 벡터 인덱스 생성
./zeta4g-vector create --name my_index --dimensions 1536 --distance cosine

# K-NN 검색
./zeta4g-vector search --index my_index --query "semantic search" --top-k 5
```

### RAG 파이프라인

```bash
# 문서 인덱싱
./zeta4g-index file --path document.pdf

# RAG 질의
./zeta4g-rag query "문서에서 주요 내용을 요약해줘"

# Text-to-Cypher
./zeta4g-rag text2cypher "Alice와 연결된 사람들을 찾아줘"
```

### GraphRAG

커뮤니티 기반 글로벌/로컬 검색:

```bash
# 커뮤니티 감지
./zeta4g-index community --algorithm leiden

# 글로벌 검색 (커뮤니티 요약 기반)
./zeta4g-rag query --mode global "전체 데이터의 주요 트렌드는?"
```

## Configuration

서버 설정 파일은 `~/.zeta4g/config/` 디렉토리에 자동 생성됩니다.

| 파일 | 설명 |
|------|------|
| `core.toml` | 스토리지, 트랜잭션, WAL 설정 |
| `server.toml` | HTTP/Bolt 포트, 인증, TLS 설정 |
| `model.toml` | LLM/Embedding 프로바이더 설정 |
| `vector.toml` | 벡터 인덱스 설정 (차원, 거리 함수, HNSW 파라미터) |

## Editions

| Edition | 핵심 기능 |
|---------|----------|
| **Base** | 서버, 온톨로지, 스키마 진화 |
| **Pro** (이 패키지) | + 벡터 검색, RAG, GraphRAG, LLM 통합 |
| **HA** | + 고가용성 클러스터 (Raft) |
| **AI** | + 분산 GraphRAG, 분산 벡터 |
| **Ultimate** | + Pregel/BSP 분산 컴퓨팅 |

## Sponsor

[![Sponsor](https://img.shields.io/badge/Sponsor-Zeta4G-ea4aaa?logo=github-sponsors&logoColor=white)](https://github.com/sponsors/zeta9044)

## Support & Contact

| | |
|---|---|
| **Telegram** | [@pub_zeta](https://t.me/pub_zeta) |
| **Email** | [zeta4lab@gmail.com](mailto:zeta4lab@gmail.com) |
| **Website** | [https://zeta4.net](https://zeta4.net) |

## License

Proprietary. All rights reserved.

---

**제타포랩 (Zeta4Lab)** | 대표: 최강유 | 사업자등록번호: 570-35-01460

[zeta4.net](https://zeta4.net) | [zeta4lab@gmail.com](mailto:zeta4lab@gmail.com) | Telegram [@pub_zeta](https://t.me/pub_zeta)
