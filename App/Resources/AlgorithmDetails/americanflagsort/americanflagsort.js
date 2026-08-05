function digitAt(value, divisor, radix) {
  return Math.floor(value / divisor) % radix;
}

function flagSort(arr, low, high, divisor, radix) {
  if (high - low <= 1) {
    return;
  }

  var count = new Array(radix).fill(0);
  var offset = new Array(radix).fill(0);

  for (var i = low; i < high; i++) {
    count[digitAt(arr[i], divisor, radix)]++;
  }

  offset[0] = low;
  for (var d = 1; d < radix; d++) {
    offset[d] = offset[d - 1] + count[d - 1];
  }
  var bucketStart = offset.slice();

  for (var b = 0; b < radix; b++) {
    while (count[b] > 0) {
      var origin = offset[b];
      var from = origin;
      var value = arr[from];

      do {
        var digit = digitAt(value, divisor, radix);
        var dest = offset[digit]++;
        count[digit]--;
        var displaced = arr[dest];
        arr[dest] = value;
        value = displaced;
        from = dest;
      } while (from !== origin);
    }
  }

  if (divisor > 1) {
    for (var d2 = 0; d2 < radix; d2++) {
      var begin = bucketStart[d2];
      var end = offset[d2];
      if (end - begin > 1) {
        flagSort(arr, begin, end, Math.floor(divisor / radix), radix);
      }
    }
  }
}

function sort(arr) {
  const n = arr.length;
  if (n <= 1) {
    return arr;
  }

  var radix = 10;
  var maxValue = Math.max.apply(null, arr);

  var divisor = 1;
  while (Math.floor(maxValue / divisor) >= radix) {
    divisor *= radix;
  }

  flagSort(arr, 0, n, divisor, radix);
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
