function gravitySort(arr) {
  var n = arr.length;
  if (n === 0) return arr;

  var minValue = Math.min.apply(null, arr);
  var maxValue = Math.max.apply(null, arr);
  var ySize = maxValue - minValue + 1;

  var x = new Array(n).fill(0);
  var y = new Array(ySize).fill(0);

  for (var i = 0; i < n; i++) {
    x[i] = arr[i] - minValue;
    y[x[i]]++;
  }

  for (i = ySize - 1; i > 0; i--) {
    y[i - 1] += y[i];
  }

  for (var j = ySize - 1; j >= 0; j--) {
    for (i = 0; i < n; i++) {
      var inc = (i >= n - y[j] ? 1 : 0) - (x[i] >= j ? 1 : 0);
      arr[i] += inc;
    }
  }

  return arr;
}

function sort(arr) {
  return gravitySort(arr);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
