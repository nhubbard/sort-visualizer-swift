const INSERTION_THRESHOLD = 24;

// Once a range's "between the pivots" middle partition holds more than this fraction of the
// range, it's worth pausing to scan out any elements that exactly equal one of the two pivots
// before recursing into what's left.
const EQUAL_ELEMENTS_MIN_FRACTION = 4;

function insertionSort(arr, low, high) {
  // Sorts arr[low..high] in place (both bounds inclusive).
  for (let i = low + 1; i <= high; i++) {
    const key = arr[i];
    let j = i - 1;
    while (j >= low && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

function movePivotDuplicatesOut(arr, low, high, pivot1, pivot2) {
  // arr[low..high] holds only values in the closed range [pivot1, pivot2]. In a single scan,
  // moves every element equal to pivot1 to the front and every element equal to pivot2 to the
  // back -- a Dutch-national-flag-style three-way partition, generalized to two specific
  // target values instead of "less than/greater than a pivot". Returns [low, high]: the
  // inclusive bounds of what's left strictly between the two pivots.
  let writeLow = low;
  let read = low;
  let writeHigh = high;
  while (read <= writeHigh) {
    if (arr[read] === pivot1) {
      [arr[read], arr[writeLow]] = [arr[writeLow], arr[read]];
      writeLow++;
      read++;
    } else if (arr[read] === pivot2) {
      [arr[read], arr[writeHigh]] = [arr[writeHigh], arr[read]];
      writeHigh--;
    } else {
      read++;
    }
  }
  return [writeLow, writeHigh];
}

function optimizedDualPivotQuickSort(arr, low, high) {
  // Sorts arr[low..high] in place (both bounds inclusive).
  const size = high - low + 1;
  if (size <= INSERTION_THRESHOLD) {
    if (size > 1) {
      insertionSort(arr, low, high);
    }
    return;
  }

  // Sample two candidates roughly a third of the way in from each end and seed the two
  // pivots from them, smaller one first.
  const third = Math.floor(size / 3);
  let pivot1Index = low + third;
  let pivot2Index = high - third;
  if (arr[pivot1Index] > arr[pivot2Index]) {
    [arr[pivot1Index], arr[pivot2Index]] = [arr[pivot2Index], arr[pivot1Index]];
  }
  [arr[low], arr[pivot1Index]] = [arr[pivot1Index], arr[low]];
  [arr[high], arr[pivot2Index]] = [arr[pivot2Index], arr[high]];
  const pivot1 = arr[low];
  const pivot2 = arr[high];

  // Single left-to-right scan splitting the interior into three regions: less than pivot1,
  // between the two pivots, and greater than pivot2.
  let less = low + 1;
  let great = high - 1;
  let k = less;
  while (k <= great) {
    if (arr[k] < pivot1) {
      [arr[k], arr[less]] = [arr[less], arr[k]];
      less++;
    } else if (arr[k] > pivot2) {
      while (k < great && arr[great] > pivot2) {
        great--;
      }
      [arr[k], arr[great]] = [arr[great], arr[k]];
      great--;
      if (arr[k] < pivot1) {
        [arr[k], arr[less]] = [arr[less], arr[k]];
        less++;
      }
    }
    k++;
  }

  // Drop the two pivots into place at the boundaries of their regions.
  less--;
  great++;
  [arr[low], arr[less]] = [arr[less], arr[low]];
  [arr[high], arr[great]] = [arr[great], arr[high]];

  // arr[low..less-1] < pivot1, arr[less] == pivot1, arr[less+1..great-1] is the middle
  // region, arr[great] == pivot2, arr[great+1..high] > pivot2.
  optimizedDualPivotQuickSort(arr, low, less - 1);
  optimizedDualPivotQuickSort(arr, great + 1, high);

  let middleLow = less + 1;
  let middleHigh = great - 1;

  if (pivot1 !== pivot2 && middleHigh >= middleLow) {
    const middleSize = middleHigh - middleLow + 1;
    // Equal-elements optimization: a middle region this large is usually full of values tied
    // to one pivot or the other, which would otherwise get pointlessly re-partitioned by the
    // recursive call below. Shrink it first by scanning out the exact duplicates. They're
    // already correctly positioned relative to the low and high regions -- every pivot1
    // duplicate is >= everything already sorted into the low region, and every pivot2
    // duplicate is <= everything already sorted into the high region -- so neither of those
    // two regions needs to be touched again.
    if (middleSize > Math.floor(size / EQUAL_ELEMENTS_MIN_FRACTION)) {
      [middleLow, middleHigh] = movePivotDuplicatesOut(
        arr,
        middleLow,
        middleHigh,
        pivot1,
        pivot2,
      );
    }
  }

  if (pivot1 !== pivot2 && middleHigh >= middleLow) {
    optimizedDualPivotQuickSort(arr, middleLow, middleHigh);
  }
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  optimizedDualPivotQuickSort(arr, 0, n - 1);
}

var array = [
  55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
  66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
];
sort(array);
console.log("[" + array.join(", ") + "]");
