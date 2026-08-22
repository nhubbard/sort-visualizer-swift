function cycleSort(array) {
  var n = array.length;
  for (var cycleStart = 0; cycleStart < n - 1; cycleStart++) {
    var item = array[cycleStart];
    var pos = cycleStart;
    for (var i = cycleStart + 1; i < n; i++) {
      if (array[i] < item) pos++;
    }
    if (pos === cycleStart) continue;
    while (item === array[pos]) pos++;
    [array[pos], item] = [item, array[pos]];
    while (pos !== cycleStart) {
      pos = cycleStart;
      for (var j = cycleStart + 1; j < n; j++) {
        if (array[j] < item) pos++;
      }
      while (item === array[pos]) pos++;
      [array[pos], item] = [item, array[pos]];
    }
  }
  return array;
}

function sort(arr) {
  cycleSort(arr);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
