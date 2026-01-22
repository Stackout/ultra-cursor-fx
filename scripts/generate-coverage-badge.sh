#!/bin/bash
# Generate coverage badge from LuaCov report

set -e

if [ ! -f "luacov.report.out" ]; then
    echo "Error: luacov.report.out not found"
    exit 1
fi

# Extract addon-specific coverage (excluding test files, libraries, and UI.lua)
# UI.lua is excluded because it's primarily UI callback code that's difficult to test comprehensively
CORE_COVERAGE=$(grep -E "^(Commands|Core|Effects|Init|Profiles|Utils)\.lua.*%" luacov.report.out | \
    awk '{hits+=$2; missed+=$3} END {
        if (hits+missed > 0) {
            coverage = (hits / (hits + missed)) * 100;
            printf "%.1f", coverage
        } else {
            print "0.0"
        }
    }')

echo "Core Addon Coverage (excluding UI): ${CORE_COVERAGE}%"

echo "Core Addon Coverage (excluding UI): ${CORE_COVERAGE}%"

# Determine badge color based on core coverage
if (( $(echo "$CORE_COVERAGE >= 95" | bc -l) )); then
    COLOR="brightgreen"
elif (( $(echo "$CORE_COVERAGE >= 90" | bc -l) )); then
    COLOR="green"
elif (( $(echo "$CORE_COVERAGE >= 80" | bc -l) )); then
    COLOR="yellow"
elif (( $(echo "$CORE_COVERAGE >= 70" | bc -l) )); then
    COLOR="orange"
else
    COLOR="red"
fi

echo "Badge Color: $COLOR"

# Output for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "coverage=${CORE_COVERAGE}" >> $GITHUB_OUTPUT
    echo "color=${COLOR}" >> $GITHUB_OUTPUT
fi

# Create badge markdown
BADGE_URL="https://img.shields.io/badge/coverage-${CORE_COVERAGE}%25-${COLOR}"
echo "Badge URL: $BADGE_URL"
