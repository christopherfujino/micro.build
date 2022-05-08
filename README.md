# monobuild

A small build system for big repos.

## Examples

```
target main(frontend, backend) {
  run("python tool/integration_test.py");
}

with ({workingDir: "./site"}) {
  target frontend(submodules) {
    # Leverage JS tooling
    run("npm install");
    run("run run analyze");
    run("npm test");
    run("npm run build");
  }
}

with ({workingDir: "./server"}) {
  target backend(submodules) {
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
