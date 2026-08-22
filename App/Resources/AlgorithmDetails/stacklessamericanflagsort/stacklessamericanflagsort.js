const RADIX = 4;

function getDigit(value, place) {
  for (let p = 0; p < place; p++) {
    value = Math.floor(value / RADIX);
  }
  return value % RADIX;
}

function shift(value, places) {
  for (let p = 0; p < places; p++) {
    value = Math.floor(value / RADIX);
  }
  return value;
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) {
    return;
  }

  let q = 0;
  let probe = RADIX;
  const maxValue = Math.max(...arr);
  while (probe <= maxValue) {
    q += 1;
    probe *= RADIX;
  }

  const counts = new Array(RADIX).fill(0);
  const offsets = new Array(RADIX).fill(0);

  function bump(digit) {
    counts[digit] += 1;
  }

  // Turns the raw per-bucket counts already accumulated in `counts` into
  // starting offsets, then places every element in [start, end) by
  // following displacement cycles, one bucket at a time.
  function distribute(start, end, place) {
    for (let i = 1; i < RADIX; i++) {
      counts[i] += counts[i - 1];
      offsets[i] = counts[i - 1];
    }

    for (let bucket = 0; bucket < RADIX - 1; bucket++) {
      const position = start + offsets[bucket];
      if (counts[bucket] > offsets[bucket]) {
        let held = arr[position];
        do {
          const digit = getDigit(held, place);
          counts[digit] -= 1;
          const displaced = arr[start + counts[digit]];
          arr[start + counts[digit]] = held;
          held = displaced;
        } while (counts[bucket] > offsets[bucket]);
      }
    }

    const split = start + offsets[1];
    for (let i = 0; i < RADIX; i++) {
      counts[i] = 0;
      offsets[i] = 0;
    }
    return split;
  }

  // `i`/`b` track the bounds of whichever range is currently active, `q`
  // the digit place being distributed on, and `m` a counter that mirrors
  // how many bucket boundaries have already been walked at the current
  // depth, standing in for the call stack a recursive walk would need.
  let m = 0;
  let i = 0;
  let b = n;

  for (let j = i; j < b; j++) {
    bump(getDigit(arr[j], q));
  }

  while (i < n) {
    const p = b - i < 1 ? i : distribute(i, b, q);

    if (q === 0) {
      m += RADIX;
      let t = Math.floor(m / RADIX);
      while (t % RADIX === 0) {
        t = Math.floor(t / RADIX);
        q += 1;
      }

      i = b;
      while (b < n && shift(arr[b], q + 1) === shift(m, q + 1)) {
        bump(getDigit(arr[b], q));
        b += 1;
      }
    } else {
      b = p;
      q -= 1;
      for (let j = i; j < b; j++) {
        bump(getDigit(arr[j], q));
      }
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
