function minRunLength(n) {
    var r = 0;
    while (n >= 64) {
        r |= n & 1;
        n >>= 1;
    }
    return n + r;
}

function cocktailShakerSort(array, start, end) {
    var length = end - start;
    if (length <= 1) {
        return;
    }
    var i = 0;
    while (i < Math.floor(length / 2)) {
        var isSorted = true;
        var j = i;
        while (j < length - i - 1) {
            if (array[start + j] > array[start + j + 1]) {
                [array[start + j], array[start + j + 1]] = [array[start + j + 1], array[start + j]];
                isSorted = false;
            }
            j++;
        }
        j = length - i - 1;
        while (j > i) {
            if (array[start + j - 1] > array[start + j]) {
                [array[start + j - 1], array[start + j]] = [array[start + j], array[start + j - 1]];
                isSorted = false;
            }
            j--;
        }
        if (isSorted) {
            break;
        }
        i++;
    }
}

function merge(array, start, mid, end) {
    var left = array.slice(start, mid);
    var right = array.slice(mid, end);
    var i = 0, j = 0, k = start;
    while (i < left.length && j < right.length) {
        if (left[i] <= right[j]) {
            array[k] = left[i];
            i++;
        } else {
            array[k] = right[j];
            j++;
        }
        k++;
    }
    while (i < left.length) {
        array[k] = left[i];
        i++;
        k++;
    }
    while (j < right.length) {
        array[k] = right[j];
        j++;
        k++;
    }
}

function cocktailMergeSort(array) {
    var n = array.length;
    if (n <= 1) {
        return;
    }
    var minRun = minRunLength(n);
    if (n === minRun) {
        cocktailShakerSort(array, 0, n);
        return;
    }
    var i = 0;
    while (i <= n - minRun) {
        cocktailShakerSort(array, i, i + minRun);
        i += minRun;
    }
    if (i < n) {
        cocktailShakerSort(array, i, n);
    }
    var width = minRun;
    while (width < n) {
        i = 0;
        while (i < n) {
            var mid = Math.min(i + width, n);
            var end = Math.min(i + 2 * width, n);
            if (mid < end) {
                merge(array, i, mid, end);
            }
            i += 2 * width;
        }
        width *= 2;
    }
}

function sort(arr) {
    cocktailMergeSort(arr);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
