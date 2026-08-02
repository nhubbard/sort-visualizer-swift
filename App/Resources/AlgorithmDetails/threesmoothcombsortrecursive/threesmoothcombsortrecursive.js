function powerOfThree(arr, pos, gap, end) {
  if (pos + gap > end) {
    return;
  }

  powerOfThree(arr, pos, gap * 3, end);
  powerOfThree(arr, pos + gap, gap * 3, end);
  powerOfThree(arr, pos + 2 * gap, gap * 3, end);

  for (var i = pos; i + gap < end; i += gap) {
    if (arr[i] > arr[i + gap]) {
      var t = arr[i];
      arr[i] = arr[i + gap];
      arr[i + gap] = t;
    }
  }
}

function recursiveComb(arr, pos, gap, end) {
  if (pos + gap > end) {
    return;
  }

  recursiveComb(arr, pos, gap * 2, end);
  recursiveComb(arr, pos + gap, gap * 2, end);

  powerOfThree(arr, pos, gap, end);
}

function sort(arr) {
  var n = arr.length;
  if (n > 1) {
    recursiveComb(arr, 0, 1, n);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
