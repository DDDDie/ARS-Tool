#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$ROOT/release/index.html" ]; then
  echo "release/index.html not found. Building the app first..."
  cd "$ROOT"
  if [ ! -d "$ROOT/node_modules" ]; then
    npm install || exit 1
  fi
  npm run build || exit 1
fi

cd "$ROOT/src/server"

python3 lenovo_spec_server.py &
PY_PID=$!

sleep 1.5

open "$ROOT/release/index.html"

wait $PY_PID
