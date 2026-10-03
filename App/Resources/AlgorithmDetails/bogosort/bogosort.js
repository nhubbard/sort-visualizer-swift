function sort(values) {
  const n = values.length;
  if (n < 2) return;
  let ordered = true;
  for (let i = 1; i < n; i++)
    if (values[i] < values[i - 1]) {
      ordered = false;
      break;
    }
  if (ordered) return;
  const reverse = (lo, hi) => {
    while (lo < hi) {
      [values[lo], values[hi]] = [values[hi], values[lo]];
      lo++;
      hi--;
    }
  };
  while (true) {
    let pivot = n - 2;
    while (pivot >= 0 && values[pivot] >= values[pivot + 1]) pivot--;
    if (pivot < 0) break;
    let successor = n - 1;
    while (values[successor] <= values[pivot]) successor--;
    [values[pivot], values[successor]] = [values[successor], values[pivot]];
    reverse(pivot + 1, n - 1);
  }
  reverse(0, n - 1);
}
const array = [0, 39, 21, 62, 91, 77, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
