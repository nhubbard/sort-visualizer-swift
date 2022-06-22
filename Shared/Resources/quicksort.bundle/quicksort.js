function quickSort(array, start, end) {
  if (start === undefined) {
    start = 0;
    end = array.length - 1;
  } else if (start >= end) {
    return array;
  }
  var rStart = start, rEnd = end;
  var pivotIndex = Math.random() * (end - start + 1) + start;
  var pivot = array[Math.floor(pivotIndex)];
  while (start < end) {
    while (array[start] <= pivot) start++;
    while (array[end] > pivot) end--;
    if (start < end) {
      [array[start], array[end]] = [array[end], array[start]];
    }
  }
  quickSort(array, rStart, start - 1);
  quickSort(array, start, rEnd);
}

function sort(arr) {
  quickSort(arr, 0, arr.length - 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");