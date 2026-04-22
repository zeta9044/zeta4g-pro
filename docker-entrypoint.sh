#!/bin/sh
set -e

export ZETA4G_HOME="${ZETA4G_HOME:-/data}"

# Initialize database on first run
if [ ! -d "${ZETA4G_HOME}/.zeta4g" ]; then
  echo "==> Initializing Zeta4G database at ${ZETA4G_HOME}..."
  zeta4gctl --home "${ZETA4G_HOME}" init -y
fi

case "$1" in
  start)
    shift
    echo "==> Starting Zeta4G Pro server (foreground)..."
    exec zeta4gctl --home "${ZETA4G_HOME}" console --host 0.0.0.0 "$@"
    ;;
  init)
    shift
    exec zeta4gctl --home "${ZETA4G_HOME}" init "$@"
    ;;
  shell)
    shift
    exec zeta4gs "$@"
    ;;
  *)
    exec "$@"
    ;;
esac
