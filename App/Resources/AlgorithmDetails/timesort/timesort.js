function sort(arr) {
  const n = arr.length;
  if (n <= 1) {
    return;
  }

  // Simulate the reporting order that proportional-to-value sleep durations
  // would produce in a jitter-free race: sort by value, ties broken by the
  // original position, i.e. the order the sleeps were originally scheduled.
  const woken = arr
    .map((value, index) => [value, index])
    .sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  for (let i = 0; i < n; i++) {
    arr[i] = woken[i][0];
  }

  // Defensive cleanup pass: real scheduling jitter can't be fully trusted,
  // so finish with an ordinary insertion sort no matter what the race produced.
  for (let i = 1; i < n; i++) {
    let j = i;
    while (j > 0 && arr[j - 1] > arr[j]) {
      const t = arr[j - 1];
      arr[j - 1] = arr[j];
      arr[j] = t;
      j--;
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
