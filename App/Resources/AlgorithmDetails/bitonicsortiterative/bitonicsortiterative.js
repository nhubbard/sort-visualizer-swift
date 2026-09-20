function sort(arr) {
  let n = arr.length;
  for (let k = 2; k < 2 * n; k *= 2) {
    const m = Math.floor((n + k - 1) / k) % 2 !== 0;
    for (let j = k / 2; j > 0; j /= 2) {
      for (let i = 0; i < n; i++) {
        let l = i ^ j;
        if (l > i && l < n) {
          const ascending = ((i & k) === 0) === m;
          if ((ascending && arr[i] > arr[l]) || (!ascending && arr[i] < arr[l])) {
            [arr[i], arr[l]] = [arr[l], arr[i]];
          }
        }
      }
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
