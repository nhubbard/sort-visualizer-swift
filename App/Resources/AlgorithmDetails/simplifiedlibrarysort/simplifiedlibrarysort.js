function binarySearch(array, item, start, end) {
  var lo = start;
  var hi = end;
  while (lo < hi) {
    var mid = lo + Math.floor((hi - lo) / 2);
    if (item < array[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

function binaryInsertionSort(array, start, end) {
  for (var i = start + 1; i < end; i++) {
    var item = array[i];
    var pos = binarySearch(array, item, start, i);
    var j = i;
    while (j > pos) {
      array[j] = array[j - 1];
      j--;
    }
    array[pos] = item;
  }
}

function rebalance(array, temp, counts, locations, spineSize, batchEnd) {
  for (var i = 0; i < spineSize; i++) {
    counts[i + 1] = counts[i + 1] + counts[i] + 1;
  }

  var k = 0;
  for (i = spineSize; i < batchEnd; i++) {
    var gap = locations[k];
    var position = counts[gap];
    temp[position] = array[i];
    counts[gap] = position + 1;
    k++;
  }

  for (i = 0; i < spineSize; i++) {
    position = counts[i];
    temp[position] = array[i];
    counts[i] = position + 1;
  }

  for (i = 0; i < batchEnd; i++) {
    array[i] = temp[i];
  }

  binaryInsertionSort(array, 0, counts[0] - 1);
  for (i = 0; i < spineSize - 1; i++) {
    binaryInsertionSort(array, counts[i], counts[i + 1] - 1);
  }
  binaryInsertionSort(array, counts[spineSize - 1], counts[spineSize]);

  for (i = 0; i < spineSize + 2; i++) {
    counts[i] = 0;
  }
}

function librarySort(array) {
  var n = array.length;
  if (n < 2) {
    return array;
  }

  var rebalanceFactor = 2;
  var spineSize = 1;
  binaryInsertionSort(array, 0, spineSize);

  var maxLevel = spineSize;
  while (maxLevel * rebalanceFactor < n) {
    maxLevel *= rebalanceFactor;
  }

  var temp = new Array(n).fill(0);
  var counts = new Array(maxLevel + 2).fill(0);
  var locations = new Array(n).fill(0);

  var i = spineSize;
  var k = 0;
  while (i < n) {
    if (rebalanceFactor * spineSize == i) {
      rebalance(array, temp, counts, locations, spineSize, i);
      spineSize = i;
      k = 0;
    }
    var gap = binarySearch(array, array[i], 0, spineSize);
    counts[gap + 1]++;
    locations[k] = gap;
    k++;
    i++;
  }
  rebalance(array, temp, counts, locations, spineSize, n);
  return array;
}

function sort(arr) {
  return librarySort(arr);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
