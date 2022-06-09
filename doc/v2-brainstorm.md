## V2?

```
const global = {};
const pythonBinary = "python";

global.targets = {
  "main": Target()
    .deps(["frontend", "backend", "python"]),
    .build(() => run([pythonBinary, "tool/integration_test.py"])),
  "frontend": Target()
    .deps(["submodules"]),
    .build(() => ),
};

module.exports = global;
```
