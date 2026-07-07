function insertionSort(arr) {
  const n = arr.length;
  for (let i = 1; i < n; i++) {
    let key = arr[i];
    let j = i - 1;
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j];
      j = j - 1;
    }
    arr[j + 1] = key;
  }
}

function sort(arr) {
  const n = arr.length;
  let shrink = 1.3;
  let gap = n;
  let sorted = false;
  let threshold = Math.min(8, Math.floor(n / 32));
  while (!sorted) {
    gap = parseInt(gap / shrink);
    if (gap <= 1) {
      sorted = true;
      gap = 1;
    }
    for (let i = 0; i < n - gap; i++) {
      if (gap <= threshold) {
        insertionSort(arr);
        return;
      }
      let sm = gap + i;
      if (arr[i] > arr[sm]) {
        [arr[i], arr[sm]] = [arr[sm], arr[i]];
        sorted = false;
      }
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
