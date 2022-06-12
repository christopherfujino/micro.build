## V2?

### Node.js

```
const global = {};
const pythonBinary = "python";

global.targets = {
  "main": Target(
    {
      "deps": ["frontend", "backend", "python"],
      "build": () => run([pythonBinary, "tool/integration_test.py"]),
    }
  ),
  "frontend": Target(
    {
      "deps": ["submodules"],
      "build": () => [
        "npm install",
        "npm run analyze",
        "npm test",
        "npm run build",
      ].forEach(run),
    },
  ),
  "backend": Target(
    {
      "deps": ["submodule"],
      "context": () => ctx.cwd += "server",
      "build": () => ["go get", "go vet", "go test", "go build"].map(run);
    },
  ),
};

module.exports = global;
```
