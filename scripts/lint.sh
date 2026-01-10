#!/bin/bash
set -e

cd "$(dirname "$0")/.."

mint run swiftformat --lint .

mint run swiftlint lint
