# monobuild

A small build system for big repos.

Monobuild is a simple build system (think make) with an expressive, obvious
domain-specific language (think Python). Monobuild is not a replacement for
highly specialized build systems like Cmake, Gradle, or Webpack, but is intended
as a lightweight solution for configuring monorepos

## Examples

```
var pythonBinary = "python";

target main {
  const deps = [frontend, backend, python];

  function build() {
    run([pythonBinary, "tool/integration_test.py"]);
  }
}

target frontend {
  const deps = [submodules];

  function context(ctx) {
    ctx.cwd += "site";
  }

  function build() {
    # Leverage JS tooling
    run("npm install");
    run("run run analyze");
    run("npm test");
    run("npm run build");
  }
}

target backend {
  const deps = [submodules];

  function context(ctx) {
    ctx.cwd += "server";
  }

  function build() {
    # Leverage Go tooling
    run("go get");
    run("go vet");
    run("go test");
    run("go build");
  }
}

target python() {
  function build() {
    var result = runWithErrors([pythonBinary, "--version"]); # Unimplemented
    if (result.exitCode == 0) { # Unimplemented
      # Returning from a `target` means it succeeded
      return; # Unimplemented
    }
    pythonBinary = "python3";
    result = runWithErrors([pythonBinary, "--version"]);
    if (result.exitCode == 0) {
      return;
    }
    fail("Could not resolve python or python3 from the $PATH");
  }
}

target submodules {
  function build() {
    run("git submodule init");
    run("git submodule update");
  }
}
```

## Concepts

### Dependency Graph

Each invocation of Microbuild must have a single target entrypoint (if a target
is not explicitly provided via a command-line argument, `'main'` will be
implicitly executed). Targets specify zero or more target dependencies which are
recursively validated to be up to date before the current target is executed.

Note: a particular target is guaranteed to run at most once in a build, even if
it is depended on multiple times and its fingerprint has been invalidated by
another build (or a target does not provide a fingerprint). This means that if
one target produces side effects that affect the execution of another target,
the order targets are executed may matter, although this order is not guaranteed
to be stable (other than declared dependencies are guaranteed to run before
dependent targets). If side effects from target A affects the execution of
target B, target B should declare target A as its dependency.

### Context Stack

A Monobuild context consists of environment variables (`$env`), the current
working directory (`$cwd`, by default bound to the directory containing the
current build file), and various setters and getters to
[persistent storage](#persistent-storage). See
[context getters](#context-getters) and [context setters](#context-setters) for
more information.

During the runtime of a build, a stack of contexts are maintained. New contexts
are added to the stack when a new target is begun, when a new build file is
entered (`$cwd` is updated to the containing directory of the build file), or
when in a `with` block.

```
target main {
  const deps = [dep];

  function build() {
    print("foo is " + $env["foo"]); # "foo is "
  }
}

target dep {
  function context(ctx) {
    ctx.env += {"foo": "bar"};
  }

  function build() {
    print("foo is " + $env["foo"]); # "foo is bar"
  }
}
```

### Persistent Storage

While Make by default is stateless and determines whether a target is stale or
not by comparing the last modified dates of the inputs to that of the output,
Monobuild is stateful, and requires targets to define arbitrary `$fingerprint`
strings.

## MBScript

### Keywords

Keyword | Description | Implemented?
--- | --- | ---
`target` | A build target. See [Dependency Graph](#dependency-graph) for more context. | [x]
`var` | A mutable variable | [ ]
`const` | An immutable variable (attempting to modify a `const` `Map` is a runtime error) | [ ]
`function` | A custom function. | [x]

### Primitives

Type | Example | Description | Implemented?
--- | --- | --- | ---
String | `"Hello, world!"` | ASCII, immutable string | [x]
Number | `12.3` | Floating point number (currently 32-bit) | [ ]
`bool` | `var shouldUpdate = false;` | Either `true` or `false` | [ ]
null | `null` | null literal | [ ]

### Composite Types

Type | Example | Description | Implemented?
--- | --- | --- | ---
List | `[1, "b", null]` | An untyped, growable list of objects | [ ]
Map | `{"age": 36}` | Hash map from `String` to any object. Using a non-string as a key will trigger an implicit cast. Attempting to get a value from an unset key will return `null`. | [ ]
Path | `const source = $cwd + "lib" + "main.c"` | An interface over file system paths on the current machine. `Path` overloads the `+` operator to allow concatenating two `Path`s, or adding a string to a `Path`. Note: when constructing `Path`s, path separators (`/` on Unix or `\` on Windows) should never be manually specified. | [ ]

### Control Flow

Keyword | Example | Implemented?
--- | --- | ---
`if` | `if check() {}` | [ ]
`for` & `in` | `for file in getFiles() {}` | [ ]

### Functions

Function Name | Description | Implemented?
--- | --- | ---
`run(String)` | Run a subprocess. Does not support paths or arguments with spaces | [x]
`run(List)` | Run a subprocess with support for spaces. Each element should be either a `String` or a `Path`. | [ ]
`print(String)` | Print a `String` to STDOUT | [ ]
`printError(String)` | Print a `String` to STDERR | [ ]
`fail(String)` | Explicitly fail a target with an error message | [ ]

### Context Getters

Context getters look like variables prefixed with a `$`. However, they are
evaluated at runtime relative to the current running context.

Getter Name | Description | Implemented?
--- | --- | ---
`$cwd` | A `Path` object representing the current working directory. By default, a target's working directory will be the location of the build file it is defined in. This can be temporarily modified with the `with` keyword. | [ ]
`$root` | A `Path` object respresenting the current file system's root. Note: this should be used with caution, as encoding `Path`s from root may not work on other machines. | [ ]
`$env` | A `Map` interface that gets environment variables from the [Context Stack](#context-stack) | [ ]
`$fileState` | A `Map` interface around Microbuild's local key/value database file, scoped to the current file. Note, files are tracked by absolute file system path. If a file's absolute path changes, earlier persistent data will not be accessible. | [ ]
`$targetState` | A `Map` interface around Microbuild's local key/value database file, scoped to the current target. Note, targets are tracked by target name and absolute file system path. | [ ]

### Context Setters

Setter Name | Description | Implemented?
--- | --- | ---
`$fingerprint` | A write-only `String` interface that is persisted to database file.

## Dependencies

Target declarations have what look like a parameter-list; however, this is
actually a list of named targets that must be up to date before this executes.

## Why Not Use...

### Make

While Make's simple architecture the primary inspiration for Monobuild, Make
assumes that target cache invalidation is based on last modified timestamps on
files. This means doing other kinds of cache invalidation (e.g. hashing file
contents, running an arbitrary script), while possible, is awkward and requires
shell scripting and Makefile syntax knowledge.

Monobuild's built-in DSL, MBScript, allows targets to define arbitrary cache
fingerprints. It also has an expressive, obvious scripting syntax, which should
be accessible to programmers coming from different languages, unlike Makefile or
shell.

Monobuild is neither good at nor concerned with compiling your code. Monobuild
assumes that build targets already know how to build themselves, whether by via
a generalized build system like Make or CMake, or a language-specific toolchain
like the `go` tool.

### Bazel

Didn't Google already solve the problem of describing cross-language build
targets across monorepos with [Bazel](https://bazel.build)?

Sort of. Bazel assumes you will be compiling a large number (hundreds or
thousands) targets in parallel across multiple remote compute instances, while
Monobuild aims to manage reproducibly manage monorepo workspaces on a local
machine.

In addition, Bazel assumes that there will be Bazel build rules for all code in
your dependency graph. At Google, third party dependency sources are copied
internally and Bazel build rules maintained alongside. In addition to
maintaining build rules per project, rules for each programming language
toolchain must be available. While mainstream languages have
[support](https://bazel.build/rules), for more esoteric languages you community
support may be unreliable (or non-existent).
