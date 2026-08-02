function sort(arr) {
  const n = arr.length;

  function maxToFront(a, b) {
    let best = a;
    let i = a + 1;
    while (i < b) {
      if (arr[i] > arr[best]) {
        best = i;
      }
      i++;
    }
    [arr[best], arr[a]] = [arr[a], arr[best]];
  }

  const s = Math.floor(Math.sqrt(n - 1)) + 1;

  let i = 0;
  while (i < n) {
    maxToFront(i, Math.min(i + s, n));
    i += s;
  }

  let j = n;
  while (j > 0) {
    let best = 0;
    let k = best + s;
    while (k < j) {
      if (arr[k] >= arr[best]) {
        best = k;
      }
      k += s;
    }
    j--;
    [arr[best], arr[j]] = [arr[j], arr[best]];
    maxToFront(best, Math.min(best + s, j));
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
