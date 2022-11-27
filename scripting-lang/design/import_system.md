# Import System

Each source code file is a module.

## TODO

- [ ] module-level config via optional `function context()` hook.

## Example

File 1 (`./app/micro.build`):

```
import "../third_party/compiler.micro.build" as compiler;

target app {
  const deps = [compiler.main];

  function build() {
    run([compiler.main.binary, "compile", "."]);
  }
}
```

File 2 (`./third_party/compiler.micro.build`):

```
function context(ctx) {
  ctx.cwd += "compiler-submodule";
}

target main {
  function build(ctx) {
    run("make");
    ctx.exports.binary = ctx.cwd + "out" + "cmplr";
  }
}
```
