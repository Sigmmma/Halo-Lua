# Test utilities
These are utilities for locally testing Lua scripts.

You don't need any of this on your server.

# How to use
These tests depend on the [Busted](https://lunarmodules.github.io/busted/) test framework.

### Static test a single script
A static test checks for things like syntax errors and invalid event functions.

From this `test` directory, run
```
lua static_check.lua <your script file here>
```

### Run a single test file
From this `test` directory, run
```
busted <your test file here>
```

### Run whole test suite
The [.busted](.busted) config file will automatically include every file whose
name starts with `test_`.

From this `test` directory, run
```
busted
```
