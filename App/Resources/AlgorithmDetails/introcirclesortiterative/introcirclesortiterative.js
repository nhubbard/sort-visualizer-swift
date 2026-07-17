function circleSortRoutine(array, length, end) {
    var swapCount = 0;
    for (var gap = Math.floor(length / 2); gap > 0; gap = Math.floor(gap / 2)) {
        for (var start = 0; start + gap < end; start += 2 * gap) {
            var low = start;
            var high = start + 2 * gap - 1;
            while (low < high) {
                if (high < end && array[low] > array[high]) {
                    [array[low], array[high]] = [array[high], array[low]];
                    swapCount++;
                }
                low++;
                high--;
            }
        }
    }
    return swapCount;
}

function binaryInsertionSort(array, end) {
    for (var i = 1; i < end; i++) {
        var value = array[i];
        var lo = 0;
        var hi = i;
        while (lo < hi) {
            var mid = Math.floor(lo + (hi - lo) / 2);
            if (value < array[mid]) {
                hi = mid;
            } else {
                lo = mid + 1;
            }
        }
        var j = i;
        while (j > lo) {
            array[j] = array[j - 1];
            j--;
        }
        array[lo] = value;
    }
}

function sort(arr) {
    var end = arr.length;
    if (end <= 1) return arr;
    var n = 1;
    var threshold = 0;
    while (n < end) {
        n <<= 1;
        threshold++;
    }
    threshold = Math.floor(threshold / 2);

    var iterations = 0;
    while (true) {
        iterations++;
        if (iterations >= threshold) {
            binaryInsertionSort(arr, end);
            return arr;
        }
        if (circleSortRoutine(arr, n, end) === 0) {
            return arr;
        }
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
