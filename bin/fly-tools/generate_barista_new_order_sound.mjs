#!/usr/bin/env node
/**
 * Generate public/audio/barista_new_order.wav (~2s cafe chime, 44.1kHz mono).
 *   node bin/fly-tools/generate_barista_new_order_sound.mjs
 */
import { writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const __dirname = dirname(fileURLToPath(import.meta.url))
const outDir = join(__dirname, "..", "..", "public", "audio")
const outPath = join(outDir, "barista_new_order.wav")

const sampleRate = 44100
const durationSec = 2.0
const numSamples = Math.floor(sampleRate * durationSec)
const samples = new Float32Array(numSamples)

function env(t, attack, decay) {
  if (t < attack) return t / attack
  const d = (t - attack) / decay
  return Math.max(0, 1 - d)
}

for (let i = 0; i < numSamples; i++) {
  const t = i / sampleRate
  const e1 = env(t, 0.02, 0.35) * (t < 0.55 ? 1 : 0)
  const e2 = env(Math.max(0, t - 0.45), 0.02, 0.5) * (t >= 0.45 && t < 1.2 ? 1 : 0)
  const e3 = env(Math.max(0, t - 1.0), 0.02, 0.8) * (t >= 1.0 ? 1 : 0)
  const s1 = Math.sin(2 * Math.PI * 523.25 * t) * e1
  const s2 = Math.sin(2 * Math.PI * 659.25 * t) * e2
  const s3 = Math.sin(2 * Math.PI * 783.99 * t) * e3
  samples[i] = (s1 * 0.45 + s2 * 0.4 + s3 * 0.35) * 0.85
}

const pcm = Buffer.alloc(numSamples * 2)
for (let i = 0; i < numSamples; i++) {
  const clamped = Math.max(-1, Math.min(1, samples[i]))
  pcm.writeInt16LE(Math.round(clamped * 32767), i * 2)
}

const header = Buffer.alloc(44)
header.write("RIFF", 0)
header.writeUInt32LE(36 + pcm.length, 4)
header.write("WAVE", 8)
header.write("fmt ", 12)
header.writeUInt32LE(16, 16)
header.writeUInt16LE(1, 20)
header.writeUInt16LE(1, 22)
header.writeUInt32LE(sampleRate, 24)
header.writeUInt32LE(sampleRate * 2, 28)
header.writeUInt16LE(2, 32)
header.writeUInt16LE(16, 34)
header.write("data", 36)
header.writeUInt32LE(pcm.length, 40)

mkdirSync(outDir, { recursive: true })
writeFileSync(outPath, Buffer.concat([header, pcm]))
console.log(`Wrote ${outPath} (${(durationSec).toFixed(1)}s, ${sampleRate}Hz)`)
