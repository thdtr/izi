/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    {
      name: "no-circular",
      severity: "error",
      from: {},
      to: { circular: true },
    },
    {
      name: "no-dev-deps-in-production",
      severity: "error",
      from: { path: "^src", pathNot: "\\.(test|spec)\\.[jt]sx?$" },
      to: { dependencyTypes: ["npm-dev"], pathNot: "node_modules/@types/" },
    },
    // Layer rules derived from docs/PROJECT.md > Architecture decisions.
    // Example: UI doesn't import server code directly.
    // {
    //   name: "ui-no-server-imports",
    //   severity: "error",
    //   from: { path: "^src/components" },
    //   to: { path: "^src/server" },
    // },
  ],
  options: {
    doNotFollow: { path: "node_modules" },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: "tsconfig.json" },
    enhancedResolveOptions: {
      exportsFields: ["exports"],
      conditionNames: ["import", "require", "node", "default", "types"],
    },
  },
};
