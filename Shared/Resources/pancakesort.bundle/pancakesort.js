function flip(arr, n) {
  let left = 0;
  while (left < n) {
    [arr[left], arr[n]] = [arr[n], arr[left]];
    n--;
    left++;
  }
}

function maxIndex(arr, n) {
  let index = 0;
  for (let i = 0; i < n; i++) {
    if (arr[i] > arr[index]) {
      index = i;
    }
  }
  return index;
}

function sort(arr) {
  let n = arr.length;
  while (n > 1) {
    let max = maxIndex(arr, n);
    if (max != n) {
      flip(arr, max);
      flip(arr, n - 1);
    }
    n--;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");