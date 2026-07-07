function doubleInsertionSort(array, start, end) {
  var left = start + Math.floor((end - start) / 2) - 1;
  var right = left + 1;
  if (array[left] > array[right]) {
    var temp = array[left];
    array[left] = array[right];
    array[right] = temp;
  }
  left--;
  right++;

  while (left >= start && right < end) {
    if (array[left] > array[right]) {
      var leftItem = array[right];
      var rightItem = array[left];

      var pos = left + 1;
      while (pos <= right && array[pos] <= leftItem) {
        array[pos - 1] = array[pos];
        pos++;
      }
      array[pos - 1] = leftItem;

      pos = right - 1;
      while (pos >= left && array[pos] >= rightItem) {
        array[pos + 1] = array[pos];
        pos--;
      }
      array[pos + 1] = rightItem;
    } else {
      var leftItem = array[left];
      var rightItem = array[right];

      var pos = left + 1;
      while (array[pos] < leftItem) {
        array[pos - 1] = array[pos];
        pos++;
      }
      array[pos - 1] = leftItem;

      pos = right - 1;
      while (array[pos] > rightItem) {
        array[pos + 1] = array[pos];
        pos--;
      }
      array[pos + 1] = rightItem;
    }

    left--;
    right++;
  }

  if (right < end) {
    var pos = right - 1;
    var current = array[right];
    while (pos >= start && array[pos] > current) {
      array[pos + 1] = array[pos];
      pos--;
    }
    array[pos + 1] = current;
  }
}

function sort(arr) {
  if (arr.length > 1) {
    doubleInsertionSort(arr, 0, arr.length);
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
