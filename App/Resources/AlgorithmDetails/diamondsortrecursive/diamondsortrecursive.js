// [start, stop) is the half-open range being sorted. merge selects whether
// the two halves are recursively pre-sorted before the fixed diamond
// comparison pattern below merges them together.
function sort(arr, start, stop, merge) {
  if (stop - start === 2) {
    if (arr[start] > arr[stop - 1]) {
      [arr[start], arr[stop - 1]] = [arr[stop - 1], arr[start]];
    }
  } else if (stop - start >= 3) {
    var div = (stop - start) / 4;
    var mid = Math.floor((stop - start) / 2) + start;
    var quarter = Math.floor(div) + start;
    var threeQuarters = Math.floor(div * 3) + start;

    if (merge) {
      sort(arr, start, mid, true);
      sort(arr, mid, stop, true);
    }
    sort(arr, quarter, threeQuarters, false);
    sort(arr, start, mid, false);
    sort(arr, mid, stop, false);
    sort(arr, quarter, threeQuarters, false);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array, 0, array.length, true);
console.log("[" + array.join(", ") + "]");
