#!/bin/bash
# Helper script to run tests in Docker

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check for docker compose (new) or docker-compose (legacy)
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}Error: Neither 'docker compose' nor 'docker-compose' found${NC}"
    echo "Please install Docker with Compose plugin"
    exit 1
fi

echo -e "${YELLOW}🧪 UltraCursorFX Test Runner${NC}\n"

case "$1" in
    "unit")
        echo -e "${GREEN}Running unit tests...${NC}"
        $DOCKER_COMPOSE run --rm test-unit
        ;;
    "integration")
        echo -e "${GREEN}Running integration tests...${NC}"
        $DOCKER_COMPOSE run --rm test-integration
        ;;
    "coverage")
        echo -e "${GREEN}Running tests with coverage...${NC}"
        $DOCKER_COMPOSE run --rm test-coverage
        ;;
    "lint")
        echo -e "${GREEN}Running linter...${NC}"
        $DOCKER_COMPOSE run --rm lint
        ;;
    "shell")
        echo -e "${GREEN}Opening interactive shell...${NC}"
        $DOCKER_COMPOSE run --rm shell
        ;;
    "build")
        echo -e "${GREEN}Building Docker image...${NC}"
        $DOCKER_COMPOSE build
        ;;
    "clean")
        echo -e "${YELLOW}Cleaning up Docker resources...${NC}"
        $DOCKER_COMPOSE down -v
        docker system prune -f
        echo -e "${GREEN}Cleanup complete!${NC}"
        ;;
    "all")
        echo -e "${GREEN}Running all tests and checks...${NC}"
        $DOCKER_COMPOSE run --rm lint
        $DOCKER_COMPOSE run --rm test
        $DOCKER_COMPOSE run --rm test-coverage
        ;;
    *)
        echo -e "${GREEN}Running all tests...${NC}"
        $DOCKER_COMPOSE run --rm test
        ;;
esac

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo -e "\n${GREEN}✅ Success!${NC}"
else
    echo -e "\n${RED}❌ Tests failed${NC}"
    exit $exit_code
fi
