function push(array, low, high) {
    for (var i = low; i < high; i++) {
        if (array[i] > array[i + 1]) {
            [array[i], array[i + 1]] = [array[i + 1], array[i]];
        }
    }
}

function merge(array, low, high, mid) {
    var i = low;
    while (i <= mid) {
        if (array[i] > array[mid + 1]) {
            [array[i], array[mid + 1]] = [array[mid + 1], array[i]];
            push(array, mid + 1, high);
        }
        i++;
    }
}

function mergeSort(array, low, high) {
    if (high - low === 0) {

    } else if (high - low === 1) {
        if (array[low] > array[high]) {
            [array[low], array[high]] = [array[high], array[low]];
        }
    } else {
        var mid = Math.floor((low + high) / 2);
        mergeSort(array, low, mid);
        mergeSort(array, mid + 1, high);
        merge(array, low, high, mid);
    }
}

function sort(arr) {
    if (arr.length >= 2) {
        mergeSort(arr, 0, arr.length - 1);
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
