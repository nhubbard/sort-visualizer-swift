function sort(arr) {
  let n = arr.length;
  for (let k = 2; k <= n; k *= 2) {
    for (let j = k / 2; j > 0; j /= 2) {
      for (let i = 0; i < n; i++) {
        let l = i ^ j;
        if (l > i) {
          if (((i & k) == 0) && (arr[i] > arr[l]) ||
              (((i & k) != 0) && (arr[i] < arr[l]))) {
            [arr[i], arr[l]] = [arr[l], arr[i]];
          }
        }
      }
    }
  }
}

// Specific to bitonic sort: size must be power of 2.
var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");