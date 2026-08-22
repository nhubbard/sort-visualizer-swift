function sort(arr) {
  const n = arr.length;

  function compSwap(start, end) {
    if (arr[start] > arr[end]) {
      const temp = arr[start];
      arr[start] = arr[end];
      arr[end] = temp;
    }
  }

  function merge(start1, len1, start2, len2) {
    if (len1 === 1 && len2 === 1) {
      compSwap(start1, start2);
    } else if (len1 === 1 && len2 === 2) {
      compSwap(start1, start2 + 1);
      compSwap(start1, start2);
    } else if (len1 === 2 && len2 === 1) {
      compSwap(start1, start2);
      compSwap(start1 + 1, start2);
    } else {
      const mid1 = Math.floor(len1 / 2);
      const mid2 =
        len1 % 2 === 1 ? Math.floor(len2 / 2) : Math.floor((len2 + 1) / 2);
      merge(start1, mid1, start2, mid2);
      merge(start1 + mid1, len1 - mid1, start2 + mid2, len2 - mid2);
      merge(start1 + mid1, len1 - mid1, start2, mid2);
    }
  }

  function boseNelson(start, length) {
    if (length > 1) {
      const mid = Math.floor(length / 2);
      boseNelson(start, mid);
      boseNelson(start + mid, length - mid);
      merge(start, mid, start + mid, length - mid);
    }
  }

  boseNelson(0, n);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
