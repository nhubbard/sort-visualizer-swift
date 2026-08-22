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

function radixMSD(array, low, high, radix, power) {
  if (low >= high || power < 0) {
    return;
  }

  var buckets = [];
  for (var b = 0; b < radix; b++) {
    buckets.push([]);
  }

  for (var i = low; i < high; i++) {
    buckets[getDigit(array[i], power, radix)].push(array[i]);
  }

  var index = low;
  for (var b2 = 0; b2 < radix; b2++) {
    for (var j = 0; j < buckets[b2].length; j++) {
      array[index++] = buckets[b2][j];
    }
  }

  var start = low;
  for (var b3 = 0; b3 < radix; b3++) {
    radixMSD(array, start, start + buckets[b3].length, radix, power - 1);
    start += buckets[b3].length;
  }
}

function sort(arr) {
  if (arr.length <= 1) {
    return arr;
  }
  var radix = 4;
  var maxValue = Math.max.apply(null, arr);
  var highestPower = 0;
  var probe = radix;
  while (probe <= maxValue) {
    highestPower++;
    probe *= radix;
  }
  radixMSD(arr, 0, arr.length, radix, highestPower);
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
