"use strict";

// Minimal flat config (ESLint 9+ requires one) for the throwaway, single-file console scripts
// under AlgorithmDetails/. No package.json/node_modules here, so this intentionally sticks to
// eslint's own bundled core rules instead of `@eslint/js`'s `recommended` preset, which would
// need to be resolved as an npm dependency from this directory.
module.exports = [
  {
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "script",
      globals: {
        console: "readonly",
        process: "readonly",
        require: "readonly",
        module: "readonly",
      },
    },
    rules: {
      "no-undef": "error",
      "no-unused-vars": "error",
      "no-unreachable": "error",
      "no-dupe-keys": "error",
      "no-dupe-args": "error",
      "no-const-assign": "error",
      "no-redeclare": "error",
      "no-var": "off",
      "use-isnan": "error",
      "valid-typeof": "error",
      eqeqeq: "off",
    },
  },
];
