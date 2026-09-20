function insertionSort(a, start, end) {
  for (let i = start + 1; i < end; i++) {
    for (let j = i; j > start && a[j] < a[j - 1]; j--) {
      [a[j - 1], a[j]] = [a[j], a[j - 1]];
    }
  }
}

function dualPivotQuickSort(a, left, right, divisor) {
  const length = right - left;
  if (length < 4) { insertionSort(a, left, right + 1); return; }
  const third = Math.floor(length / divisor);
  let med1 = left + third, med2 = right - third;
  if (med1 <= left) med1 = left + 1;
  if (med2 >= right) med2 = right - 1;
  if (a[med1] < a[med2]) {
    [a[med1], a[left]] = [a[left], a[med1]];
    [a[med2], a[right]] = [a[right], a[med2]];
  } else {
    [a[med1], a[right]] = [a[right], a[med1]];
    [a[med2], a[left]] = [a[left], a[med2]];
  }
  const pivot1 = a[left], pivot2 = a[right];
  let less = left + 1, great = right - 1;
  for (let k = less; k <= great; k++) {
    if (a[k] < pivot1) { [a[k], a[less]] = [a[less], a[k]]; less++; }
    else if (a[k] > pivot2) {
      while (k < great && a[great] > pivot2) great--;
      [a[k], a[great]] = [a[great], a[k]]; great--;
      if (a[k] < pivot1) { [a[k], a[less]] = [a[less], a[k]]; less++; }
    }
  }
  if (great - less < 13) divisor++;
  [a[less - 1], a[left]] = [a[left], a[less - 1]];
  [a[great + 1], a[right]] = [a[right], a[great + 1]];
  dualPivotQuickSort(a, left, less - 2, divisor);
  if (pivot1 < pivot2) dualPivotQuickSort(a, less, great, divisor);
  dualPivotQuickSort(a, great + 2, right, divisor);
}

function sort(arr) {
  dualPivotQuickSort(arr, 0, arr.length - 1, 3);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
