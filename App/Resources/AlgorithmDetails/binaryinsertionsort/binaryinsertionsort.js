function binarySearch(array, item, start, end) {
  var low = start;
  var high = end;
  while (low < high) {
    var mid = low + Math.floor((high - low) / 2);
    if (item < array[mid]) {
      high = mid;
    } else {
      low = mid + 1;
    }
  }
  return low;
}

function sort(arr) {
  for (var i = 1; i < arr.length; i++) {
    var item = arr[i];
    var pos = binarySearch(arr, item, 0, i);
    var j = i;
    while (j > pos) {
      arr[j] = arr[j - 1];
      j--;
    }
    arr[pos] = item;
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
