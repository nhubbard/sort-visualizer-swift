function sillySort(arr, i, j) {
    if (i < j) {
        const m = i + Math.floor((j - i) / 2);
        sillySort(arr, i, m);
        sillySort(arr, m + 1, j);
        if (arr[i] >= arr[m + 1]) {
            [arr[i], arr[m + 1]] = [arr[m + 1], arr[i]];
        }
        sillySort(arr, i + 1, j);
    }
}

function sort(arr) {
    sillySort(arr, 0, arr.length - 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
