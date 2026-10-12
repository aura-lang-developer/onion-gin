#!/bin/bash
# ==============================================================================
# Onion-Gin Microservice - Automated Test Runner
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "================================================================================"
echo "  🧅 RUNNING FULL TEST SUITE FOR ONION-GIN (AURA LANGUAGE)"
echo "================================================================================"

echo ""
echo ">> Step 1/4: Typechecking Composition Root & Server Main..."
aura check cmd/server/main.aura

echo ""
echo ">> Step 2/4: Running Domain Layer Unit Tests..."
aura run tests/domain_test.aura

echo ""
echo ">> Step 3/4: Running Application Layer Use Case Tests..."
aura run tests/usecase_test.aura

echo ""
echo ">> Step 4/4: Running Presentation HTTP Integration Tests..."
aura run tests/http_integration_test.aura

echo ""
echo "================================================================================"
echo "  ✅ ALL 4 TEST SUITES PASSED CLEANLY (100% SUCCESS RATE)"
echo "================================================================================"
