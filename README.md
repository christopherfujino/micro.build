# monobuild

A small build system for big repos.

Monobuild is a simple build system (think make) but with an expressive, obvious
domain-specific language (think Python). Monobuild is not a replacement for
highly specialized build systems like Cmake, Gradle, or Webpack, but is intended
as a lightweight solution for configuring monorepos

## Examples

```
var pythonBinary = "python";

target main(frontend, backend, python) {
  run("python tool/integration_test.py");
}

with ({cwd: "./site"}) { # Unimplemented
  target frontend(submodules) {
    # Leverage JS tooling
    run("npm install");
    run("run run analyze");
    run("npm test");
    run("npm run build");
  }
}

with ({cwd: "./server"}) {
  target backend(submodules) {
    # Leverage Go tooling
    run("go get");
    run("go vet");
    run("go test");
    run("go build");
  }
}

target python() {
  var result = runWithErrors([pythonBinary, "--version"]); # Unimplemented
  if (result.exitCode == 0) { # Unimplemented
    # Returning from a `target` means it succeeded
    return; # Unimplemented
  }
  pythonBinary = "python3";
}

target submodules() {
  run("git submodule init");
  run("git submodule update");
}
```

## MBScript

### Keywords

Keyword | Description | Implemented?
--- | --- | ---
`target` | A build target. Without additional arguments, Microbuild defaults to executing a `main` target. | - [x]
`var` | A mutable variable | - [ ]
`const` | An immutable variable (attempting to modify a `const` `Map` is a runtime error) | - [ ]
`with` | Creates a context block, in which `$cwd` or `$env` is modified | - [ ]

### Primitives

Type | Example | Description | Implemented?
--- | --- | --- | ---
String | `"Hello, world!"` | ASCII, immutable string | - [x]
Number | `12.3` | Floating point number (currently 32-bit) | - [ ]
`bool` | `var shouldUpdate = false;` | Either `true` or `false` | - [ ]
null | `null` | null literal | - [ ]

### Composite Types

Type | Example | Description | Implemented?
--- | --- | --- | ---
List | `[1, "b", null]` | An untyped, growable list of objects | - [ ]
Map | `{"age": 36}` | Hash map from `String` to any object. Using a non-string as a key will trigger an implicit cast. Attempting to get a value from an unset key will return `null`. | - [ ]

### Control Flow

Keyword | Example | Implemented?
--- | --- | ---
`if` | `if check() {}` | - [ ]
`for` & `in` | `for file in getFiles() {}` | - [ ]

### Functions

Function Name | Description | Implemented?
--- | --- | ---
`run(String)` | Run a subprocess. Does not support paths or arguments with spaces | - [x]
`run(List)` | Run a subprocess with support for spaces | - [ ]

### Variables

Constant Name | Description | Implemented?
--- | --- | ---
`$cwd` | By default, a target's working directory will be the location of the build file it is defined in. This can be temporarily modified with the `with` keyword. | - [ ]
`$env` | A `Map` of environment variables when Monobuild started | - [ ]

## Dependencies

Target declarations have what look like a parameter-list; however, this is
actually a list of named targets that must be up to date before this executes.
