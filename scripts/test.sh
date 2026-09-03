#!/bin/zsh
# Standalone suite for Command Line Tools installations without XCTest.
set -euo pipefail

cd "$(dirname "$0")/.."

swift build --product EcranTests
".build/debug/EcranTests"
