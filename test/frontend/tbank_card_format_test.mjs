import test from "node:test"
import assert from "node:assert/strict"
import {
  luhnValid,
  formatPanInput,
  formatExpiryInput,
  buildCardDataString,
  validateCardFields,
  assertNoPlainCardInPayload
} from "../../app/frontend/lib/tbankCardFormat.js"

test("luhnValid accepts test Visa pan", () => {
  assert.equal(luhnValid("4300000000000777"), true)
  assert.equal(luhnValid("4300000000000778"), false)
})

test("formatPanInput groups by fours", () => {
  assert.equal(formatPanInput("4300000000000777"), "4300 0000 0000 0777")
})

test("formatExpiryInput inserts slash", () => {
  assert.equal(formatExpiryInput("1228"), "12 / 28")
})

test("buildCardDataString uses T-Bank key=value format", () => {
  const s = buildCardDataString({
    pan: "4300 0000 0000 0777",
    expDate: "1228",
    cvv: "123",
    cardHolder: "ivan petrov"
  })
  assert.equal(s, "PAN=4300000000000777;ExpDate=1228;CardHolder=IVAN PETROV;CVV=123")
})

test("validateCardFields blocks invalid pan", () => {
  const bad = validateCardFields({ pan: "4111", expiry: "12 / 28", cvv: "123" })
  assert.equal(bad.valid, false)
  assert.ok(bad.errors.pan)
})

test("assertNoPlainCardInPayload rejects leaking pan/cvv", () => {
  const pan = "4300000000000777"
  const cvv = "123"
  assert.throws(() => assertNoPlainCardInPayload({ pan, cvv }, pan, cvv))
  assert.doesNotThrow(() => assertNoPlainCardInPayload({ card_data: "encrypted" }, pan, cvv))
})
