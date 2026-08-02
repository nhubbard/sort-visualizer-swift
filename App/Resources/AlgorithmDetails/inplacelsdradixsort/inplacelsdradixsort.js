function intPow(base, exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

function getDigit(value, power, radix) {
  return Math.floor(value / intPow(radix, power)) % radix;
}

function multiSwap(arr, pos, to) {
  if (to > pos) {
    for (let k = pos; k < to; k++) {
      let temp = arr[k];
      arr[k] = arr[k + 1];
      arr[k + 1] = temp;
    }
  } else if (to < pos) {
    for (let k = pos; k > to; k--) {
      let temp = arr[k];
      arr[k] = arr[k - 1];
      arr[k - 1] = temp;
    }
  }
}

function sort(arr) {
  const n = arr.length;
  if (n === 0) {
    return arr;
  }
  const radix = 4;
  let maxValue = arr[0];
  for (const value of arr) {
    if (value > maxValue) {
      maxValue = value;
    }
  }

  let maxPower = 0;
  let probe = radix;
  while (probe <= maxValue) {
    maxPower++;
    probe *= radix;
  }

  const vregs = new Array(radix - 1).fill(0);

  for (let power = 0; power <= maxPower; power++) {
    for (let i = 0; i < vregs.length; i++) {
      vregs[i] = n - 1;
    }

    let pos = 0;
    for (let step = 0; step < n; step++) {
      const digit = getDigit(arr[pos], power, radix);
      if (digit === 0) {
        pos++;
      } else {
        const to = vregs[digit - 1];
        multiSwap(arr, pos, to);
        for (let j = digit - 1; j > 0; j--) {
          vregs[j - 1]--;
        }
      }
    }
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
