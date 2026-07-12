function is3Smooth(n) {
  while (n % 6 === 0) {
    n /= 6;
  }
  while (n % 3 === 0) {
    n /= 3;
  }
  while (n % 2 === 0) {
    n /= 2;
  }
  return n === 1;
}

function sort(arr) {
  var length = arr.length;
  for (var g = length - 1; g > 0; g--) {
    if (is3Smooth(g)) {
      for (var i = g; i < length; i++) {
        if (arr[i - g] > arr[i]) {
          var t = arr[i - g];
          arr[i - g] = arr[i];
          arr[i] = t;
        }
      }
    }
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
