# Run ontologies_web_ui

## Using OntoPortal UI utilities script
### See help

```bash 
bin/ontoportal help
```

```
Usage: bin/ontoportal {dev|test|run|help} [--reset-cache] [--api-url API_URL] [--api-key API_KEY]
  dev            : Start the Ontoportal Web UI development server.
                  Example: bin/ontoportal dev --api-url http://localhost:9393 --api-key my_api_key
                  Use --reset-cache to remove volumes: bin/ontoportal dev --reset-cache
  test           : Run tests. Specify either a test file:line_number or  empty for 'all'.
                  Example: $0 test test/integration/login_flows_test.rb:22
  run            : Run a command in the Ontoportal Web UI Docker container.
  help           : Show this help message.

Description:
  This script provides convenient commands for managing an Ontoportal Web UI
  application using Docker Compose. It includes options for starting the development server,
  running tests, and executing commands within the Ontoportal Web UI Docker container.

Goals:
  - Simplify common tasks related to Ontoportal Web UI development using Docker.
  - Provide a consistent and easy-to-use interface for common actions.
```


### Run dev
```bash 
bin/ontoportal dev --api-url <an ontoportal api url> --api-key <my_api_key>
```

### Run test with a local OntoPortal API
```bash 
bin/ontoportal test 
```

