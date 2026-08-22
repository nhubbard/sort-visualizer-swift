function oddEvenMergeCompare(array, i, j) {
  if (array[i] > array[j]) {
    [array[i], array[j]] = [array[j], array[i]];
  }
}

// lo is the starting position, m2 is the halfway point, n is the length of
// the piece being merged, and r is the distance of the elements compared.
function oddEvenMerge(array, lo, m2, n, r) {
  var m = r * 2;
  if (m < n) {
    if (Math.floor(n / r) % 2 !== 0) {
      oddEvenMerge(array, lo, Math.floor((m2 + 1) / 2), n + r, m); // even subsequence
      oddEvenMerge(array, lo + r, Math.floor(m2 / 2), n - r, m); // odd subsequence
    } else {
      oddEvenMerge(array, lo, Math.floor((m2 + 1) / 2), n, m); // even subsequence
      oddEvenMerge(array, lo + r, Math.floor(m2 / 2), n, m); // odd subsequence
    }

    if (m2 % 2 !== 0) {
      for (var i = lo; i + r < lo + n; i += m) {
        oddEvenMergeCompare(array, i, i + r);
      }
    } else {
      for (i = lo + r; i + r < lo + n; i += m) {
        oddEvenMergeCompare(array, i, i + r);
      }
    }
  } else {
    if (n > r) {
      oddEvenMergeCompare(array, lo, lo + r);
    }
  }
}

function oddEvenMergeSort(array, lo, n) {
  if (n > 1) {
    var m = Math.floor(n / 2);
    oddEvenMergeSort(array, lo, m);
    oddEvenMergeSort(array, lo + m, n - m);
    oddEvenMerge(array, lo, m, n, 1);
  }
}

function sort(arr) {
  oddEvenMergeSort(arr, 0, arr.length);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
