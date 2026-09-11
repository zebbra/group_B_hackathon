// @ts-check

import js from "@eslint/js";
import { defineConfig, globalIgnores } from "eslint/config";
import tseslint from "typescript-eslint";
import prettierConfig from "eslint-config-prettier";
import unusedImports from "eslint-plugin-unused-imports";

export default defineConfig([
  globalIgnores(["vendor", "node_modules"]),
  {
    files: ["**/*.{js,ts}"],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,

      // Must come last: switches off every rule that conflicts with prettier, so
      // formatting is prettier's job alone (see the `lint:prettier` script).
      prettierConfig,
    ],
    plugins: {
      "unused-imports": unusedImports,
    },
    rules: {
      "unused-imports/no-unused-imports": "error",

      // a leading underscore marks an argument or binding as deliberately unused
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
        },
      ],

      // TypeScript's compiler already catches undefined identifiers (including DOM
      // globals like `window`); ESLint's own check doesn't understand ambient/lib
      // types and would otherwise need a separate `globals` dependency.
      "no-undef": "off",
    },
  },
]);
