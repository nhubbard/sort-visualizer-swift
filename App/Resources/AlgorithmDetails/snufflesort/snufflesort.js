function snuffleSort(arr, start, stop) {
    if (stop - start + 1 >= 2) {
        if (arr[start] > arr[stop]) {
            [arr[start], arr[stop]] = [arr[stop], arr[start]];
        }
        if (stop - start + 1 >= 3) {
            let mid = Math.floor((stop - start) / 2) + start;
            let iterations = Math.floor((stop - start + 1) / 2);
            for (let i = 0; i < iterations; i++) {
                snuffleSort(arr, start, mid);
                snuffleSort(arr, mid, stop);
            }
        }
    }
}

function sort(arr) {
    snuffleSort(arr, 0, arr.length - 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
