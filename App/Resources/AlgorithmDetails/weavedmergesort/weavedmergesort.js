function merge(arr, tmp, length, residue, modulus) {
  if (residue + modulus >= length) {
    return;
  }
  var low = residue;
  var high = residue + modulus;
  var dmodulus = modulus << 1;

  merge(arr, tmp, length, low, dmodulus);
  merge(arr, tmp, length, high, dmodulus);

  var nxt = residue;
  while (low < length && high < length) {
    if (arr[low] > arr[high] || (arr[low] === arr[high] && low > high)) {
      tmp[nxt] = arr[high];
      high += dmodulus;
    } else {
      tmp[nxt] = arr[low];
      low += dmodulus;
    }
    nxt += modulus;
  }
  if (low >= length) {
    while (high < length) {
      tmp[nxt] = arr[high];
      nxt += modulus;
      high += dmodulus;
    }
  } else {
    while (low < length) {
      tmp[nxt] = arr[low];
      nxt += modulus;
      low += dmodulus;
    }
  }
  for (var i = residue; i < length; i += modulus) {
    arr[i] = tmp[i];
  }
}

function sort(arr) {
  var tmp = new Array(arr.length);
  merge(arr, tmp, arr.length, 0, 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
