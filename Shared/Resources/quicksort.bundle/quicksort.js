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

var array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0];
quickSort(array, 0, array.length - 1);
console.log(array);
