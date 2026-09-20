function sort(a) {
  const n = a.length;
  if (n < 2) return;
  let swapped = true;
  while (swapped) {
    swapped = false;
    for (let i = 0; i + 1 < n; i++) {
      if (a[i] > a[i + 1]) {
        [a[i], a[i + 1]] = [a[i + 1], a[i]];
        swapped = true;
      }
    }
  }
}
const array = [
  0, 39, 21, 62, 91, 77, 14, 23,
];
sort(array);
console.log("[" + array.join(", ") + "]");
