# monobuild

A small build system for big repos.

## Examples

```
target main(frontend, backend) {
  run("python tool/integration_test.py");
}

target frontend(submodules) {
  with ({workingDir: "./site"}) {
    # Leverage JS tooling
    run("npm install");
    run("run run analyze");
    run("npm test");
    run("npm run build");
  }
}

target backend(submodules) {
  with ({workingDir: "./server"}) {
    # Leverage Go tooling
    run("go get");
    run("go vet");
    run("go test");
    run("go build");
  }
}

target submodules() {
  run("git submodule init");
  run("git submodule update");
}
```
