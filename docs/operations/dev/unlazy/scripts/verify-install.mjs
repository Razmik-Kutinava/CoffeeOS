#!/usr/bin/env node
/**
 * CoffeeOS unlazy install smoke — success-only marker for gate-check EXPECT.
 */
import { access } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

// scripts/ → unlazy/ → dev/ → operations/ → docs/ → repo root
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../../");
const gateCheck = path.join(root, ".agents/skills/unlazy/scripts/gate-check.mjs");

await access(gateCheck);
console.log("unlazy coffeeos install ok");
