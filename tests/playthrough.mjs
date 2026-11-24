import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';

// Run build.py --check --labels <file> to get the actual addresses of the
// game's exported zero-page fields. The test observes them and uses only
// controller input to change game state.
const labelsPath = process.argv[2];
assert.ok(labelsPath, 'Usage: node tests/playthrough.mjs <ld65 labels file>');
const labels = new Map([...readFileSync(labelsPath, 'utf8').matchAll(/^al ([a-f0-9]+) \.(\w+)$/gim)]
  .map(([, address, name]) => [name, Number.parseInt(address, 16)]));
const cartridge = readFileSync(new URL('../web/reef-runner.nes', import.meta.url));
const require = createRequire(import.meta.url);
const { NES, Controller } = require('../web/vendor/jsnes-2.1.0.min.js');
const Phase = { title: 0, paddle: 1, ride: 2, wipeout: 3, complete: 4 };
const Message = { takeoff: 2, early: 3, late: 4, wipeout: 7, finish: 8 };
let frames = 0;
let image;
const nes = new NES({
  emulateSound: false,
  onFrame(pixels) {
    frames++;
    image = pixels;
  },
});
nes.loadROM(cartridge.toString('binary'));

function read(field, offset = 0) {
  const address = labels.get(field);
  assert.ok(Number.isInteger(address), 'Missing exported label ' + field);
  return nes.cpu.mem[address + offset];
}

function digits(field, length) {
  let value = 0;
  for (let i = 0; i < length; i++) {
    const digit = read(field, i);
    assert.ok(digit >= 0 && digit < 10, field + ' contains an invalid digit');
    value = value * 10 + digit;
  }
  return value;
}

function step(count = 1) {
  for (let i = 0; i < count; i++) nes.frame();
}

function hold(button, count = 1) {
  nes.buttonDown(1, button);
  step(count);
  nes.buttonUp(1, button);
}

function until(condition, limit, failure) {
  for (let i = 0; !condition() && i < limit; i++) step();
  assert.ok(condition(), failure);
}

function takeoff() {
  until(() => read('messageIndex') === Message.takeoff, 120, 'Wave never reached the takeoff window');
  hold(Controller.BUTTON_A);
  assert.equal(read('state'), Phase.ride);
}

step(12);
assert.equal(read('state'), Phase.title);
assert.equal(image.length, 256 * 240);
assert.ok(new Set(image).size > 8, 'The title frame should show the reef artwork');
hold(Controller.BUTTON_START);
assert.equal(read('state'), Phase.paddle);
hold(Controller.BUTTON_A);
assert.equal(read('messageIndex'), Message.early);
assert.equal(read('state'), Phase.paddle);
until(() => read('pocketX') < 54, 100, 'Wave never passed the takeoff window');
hold(Controller.BUTTON_A);
assert.equal(read('messageIndex'), Message.late);
assert.equal(read('state'), Phase.paddle);
step(); // Let the game see the released A button before the next wave.
takeoff();
assert.equal(digits('timeDigits', 2), 30);
console.log('Title, early and late takeoff feedback, and a correctly timed takeoff verified.');

const x = read('surferX');
const y = read('surferY');
hold(Controller.BUTTON_RIGHT, 3);
assert.equal(read('surferX'), x + 6);
hold(Controller.BUTTON_LEFT, 3);
assert.equal(read('surferX'), x);
hold(Controller.BUTTON_UP, 3);
assert.equal(read('surferY'), y - 6);
hold(Controller.BUTTON_DOWN, 3);
assert.equal(read('surferY'), y);
assert.ok(digits('scoreDigits', 4) > 0, 'Riding in the pocket did not earn points');
assert.equal(digits('bestDigits', 4), digits('scoreDigits', 4));
until(() => read('reefX') > 0, 120, 'Reef never spawned');
until(() => read('state') === Phase.wipeout, 160, 'Surfer in the reef lane did not wipe out');
assert.equal(read('messageIndex'), Message.wipeout);
assert.ok(digits('timeDigits', 2) < 30, 'Ride timer never ticked down');
const best = digits('bestDigits', 4);
assert.equal(best, digits('scoreDigits', 4));
console.log('Four-way steering, pocket score, best score, timer, and reef collision verified.');

hold(Controller.BUTTON_START);
assert.equal(read('state'), Phase.paddle);
assert.equal(digits('scoreDigits', 4), 0);
assert.equal(digits('bestDigits', 4), best);
takeoff();
const rideStartsAt = frames;
hold(Controller.BUTTON_DOWN, 35);
assert.equal(read('surferY'), 182);
until(() => read('state') !== Phase.ride, 1800, 'Ride did not finish');
assert.equal(read('state'), Phase.complete);
assert.equal(read('messageIndex'), Message.finish);
assert.equal(digits('timeDigits', 2), 0);
assert.equal(frames - rideStartsAt, 30 * 60);

hold(Controller.BUTTON_START);
assert.equal(read('state'), Phase.paddle);
assert.equal(digits('timeDigits', 2), 30);
assert.equal(digits('scoreDigits', 4), 0);
assert.ok(digits('bestDigits', 4) >= best);
console.log('Played a full 30-second ride and verified clean finish and reset.');
