function multiSwap(arr, pos, to) {
    if (to - pos > 0) {
        for (var i = pos; i < to; i++) {
            var tmp = arr[i];
            arr[i] = arr[i + 1];
            arr[i + 1] = tmp;
        }
    } else {
        for (var i = pos; i > to; i--) {
            var tmp = arr[i];
            arr[i] = arr[i - 1];
            arr[i - 1] = tmp;
        }
    }
}

function weaveInsert(arr, start, end) {
    for (var j = start; j < end; j++) {
        var pos = j;
        while (pos > start && arr[pos] <= arr[pos - 1]) {
            var tmp = arr[pos];
            arr[pos] = arr[pos - 1];
            arr[pos - 1] = tmp;
            pos--;
        }
    }
}

function weaveMerge(arr, min, max, mid) {
    var target = mid - min;
    for (var i = 1; i <= target; i++) {
        multiSwap(arr, mid + i, min + (i * 2) - 1);
    }
    weaveInsert(arr, min, max + 1);
}

function weaveMergeSort(arr, min, max) {
    if (max - min === 0) {

    } else if (max - min === 1) {
        if (arr[min] > arr[max]) {
            var tmp = arr[min];
            arr[min] = arr[max];
            arr[max] = tmp;
        }
    } else {
        var mid = Math.floor((min + max) / 2);
        weaveMergeSort(arr, min, mid);
        weaveMergeSort(arr, mid + 1, max);
        weaveMerge(arr, min, max, mid);
    }
}

function sort(arr) {
    if (arr.length > 1) {
        weaveMergeSort(arr, 0, arr.length - 1);
    }
    return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
