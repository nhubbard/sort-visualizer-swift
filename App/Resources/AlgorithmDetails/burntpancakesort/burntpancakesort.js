function sort(arr) {
  const n = arr.length;

  function flip(end) {
    let start = 0;
    while (start < end) {
      [arr[start], arr[end]] = [arr[end], arr[start]];
      start++;
      end--;
    }
  }

  for (let i = n - 1; i > 0; i--) {
    let max = 0;
    for (let j = max + 1; j <= i; j++) {
      if (arr[j] > arr[max]) {
        max = j;
      }
    }
    if (max !== i) {
      flip(max);
      flip(i);
      flip(i - 1);
      flip(max - 1);
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
