function destination(array, flagged, a, b1, b) {
  var heldValue = array[a];
  var d = a;
  var e = 0;
  for (var i = a + 1; i < b; i++) {
    if (array[i] < heldValue) {
      d++;
    } else if (i < b1 && !flagged[i] && array[i] === heldValue) {
      e++;
    }
  }
  while (flagged[d] || e > 0) {
    if (!flagged[d]) e--;
    d++;
  }
  return d;
}

function stableCycleSort(array) {
  var n = array.length;
  if (n <= 1) return array;
  var flagged = new Array(n).fill(false);
  for (var i = 0; i < n - 1; i++) {
    if (flagged[i]) continue;
    var j = i;
    do {
      var k = destination(array, flagged, i, j, n);
      [array[i], array[k]] = [array[k], array[i]];
      flagged[k] = true;
      j = k;
    } while (j !== i);
  }
  return array;
}

function sort(arr) {
  stableCycleSort(arr);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
