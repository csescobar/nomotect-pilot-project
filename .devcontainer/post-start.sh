#!/usr/bin/env bash
set -euo pipefail

rm -f tmp/pids/server.pid
bundle exec rails db:version >/dev/null
