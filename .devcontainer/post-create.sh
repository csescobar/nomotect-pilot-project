#!/usr/bin/env bash
set -euo pipefail

bundle install
bundle exec rails db:prepare

printf '\nDev Container setup complete. Start Rails with: bin/dev -b 0.0.0.0\n'
