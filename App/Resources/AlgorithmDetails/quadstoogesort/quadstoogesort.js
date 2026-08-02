function quadStooge(arr, pos, length) {
  if (length >= 2 && arr[pos] > arr[pos + length - 1]) {
    [arr[pos], arr[pos + length - 1]] = [arr[pos + length - 1], arr[pos]];
  }
  if (length <= 2) {
    return;
  }

  const len1 = Math.floor(length / 2);
  const len2 = Math.floor((length + 1) / 2);
  const len3 = Math.floor((len1 + 1) / 2) + Math.floor((len2 + 1) / 2);

  quadStooge(arr, pos, len1);
  quadStooge(arr, pos + len1, len2);
  quadStooge(arr, pos + Math.floor(len1 / 2), len3);
  quadStooge(arr, pos + len1, len2);
  quadStooge(arr, pos, len1);
  if (length > 3) {
    quadStooge(arr, pos + Math.floor(len1 / 2), len3);
  }
}

function sort(arr) {
  quadStooge(arr, 0, arr.length);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
