function sort(arr) {
  var n = arr.length;
  if (n < 2) return arr;
  const scratch = new Array(n);
  var subarrayCount = 1;
  while (subarrayCount < n) {
    subarrayCount *= 2;
  }

  while (subarrayCount > 1) {
    for (var i = 0; i < subarrayCount; i += 2) {
      var low = Math.floor((n * i) / subarrayCount);
      var mid = Math.floor((n * (i + 1)) / subarrayCount);
      var high = Math.floor((n * (i + 2)) / subarrayCount);
      merge(arr, scratch, low, mid, high);
    }
    subarrayCount = Math.floor(subarrayCount / 2);
  }
  return arr;
}

function merge(array, scratch, low, mid, high) {
  let left = low;
  let right = mid;
  let out = low;
  while (left < mid && right < high) {
    if (array[left] <= array[right]) {
      scratch[out++] = array[left++];
    } else {
      scratch[out++] = array[right++];
    }
  }
  while (left < mid) scratch[out++] = array[left++];
  while (right < high) scratch[out++] = array[right++];
  for (let i = low; i < high; i++) array[i] = scratch[i];
}


const array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
];
sort(array);
console.log("[" + array.join(", ") + "]");
