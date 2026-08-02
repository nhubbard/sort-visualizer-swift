function traverse(arr, temp, lower, upper, state, r) {
  if (lower[r] !== 0) {
    traverse(arr, temp, lower, upper, state, lower[r]);
  }
  temp[state.idx++] = arr[r];
  if (upper[r] !== 0) {
    traverse(arr, temp, lower, upper, state, upper[r]);
  }
}

function sort(arr) {
  var n = arr.length;
  if (n <= 1) {
    return;
  }
  var lower = new Array(n).fill(0);
  var upper = new Array(n).fill(0);

  for (var i = 1; i < n; i++) {
    var c = 0;
    while (true) {
      var next = arr[i] < arr[c] ? lower : upper;
      if (next[c] === 0) {
        next[c] = i;
        break;
      } else {
        c = next[c];
      }
    }
  }

  var temp = new Array(n);
  traverse(arr, temp, lower, upper, { idx: 0 }, 0);
  for (var j = 0; j < n; j++) {
    arr[j] = temp[j];
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
