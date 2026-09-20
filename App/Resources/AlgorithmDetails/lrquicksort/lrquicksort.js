function sort(arr) {
  quickSort(arr, 0, arr.length - 1);
}

function quickSort(array, p, r) {
  while (p < r) {
    const pivot = array[p + Math.floor((r - p + 1) / 2)];
    let i = p;
    let j = r;
    while (i <= j) {
      while (array[i] < pivot) i++;
      while (array[j] > pivot) j--;
      if (i <= j) {
        [array[i], array[j]] = [array[j], array[i]];
        i++;
        j--;
      }
    }
    if (j - p < r - i) {
      if (p < j) quickSort(array, p, j);
      p = i;
    } else {
      if (i < r) quickSort(array, i, r);
      r = j;
    }
  }
}


const array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
];
sort(array);
console.log("[" + array.join(", ") + "]");
