function swaplessBubbleSort(array) {
  var n = array.length;
  var i = n;
  while (i > 0) {
    var last = 0;
    var pos = 0;
    var comp = array[0];
    for (var j = 1; j < i; j++) {
      if (comp > array[j]) {
        array[j - 1] = array[j];
        last = j;
      } else {
        if (pos + 1 < j) {
          array[j - 1] = comp;
        }
        pos = j;
        comp = array[j];
      }
    }
    array[i - 1] = comp;
    i = last;
  }
  return array;
}

function sort(arr) {
  return swaplessBubbleSort(arr);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
