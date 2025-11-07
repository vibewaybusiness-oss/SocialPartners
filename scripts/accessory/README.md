# Accessory Scripts

This directory contains utility and testing scripts that are not part of the core startup process.

## Scripts

- **run_tests.sh** - Runs comprehensive test suite for both frontend and backend
- **setup-env.sh** - Sets up environment variables for local development
- **test_frontend_hooks.js** - Tests frontend React hooks structure

## Usage

These scripts can be run independently for testing and setup purposes:

```bash
# Run all tests
./scripts/accessory/run_tests.sh

# Setup environment variables
./scripts/accessory/setup-env.sh

# Test frontend hooks
node scripts/accessory/test_frontend_hooks.js
```

## Note

These scripts are not required for normal development workflow. Use them for:
- Manual testing
- Environment setup
- Debugging and diagnostics

