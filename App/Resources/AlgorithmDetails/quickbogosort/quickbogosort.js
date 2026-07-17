function sort(arr, start = 0, end = arr.length) {
    if (start >= end - 1) {
        return;
    }

    let pivot = start;

    function isPartitioned() {
        for (let i = start; i < pivot; i++) {
            if (arr[i] > arr[pivot]) {
                return false;
            }
        }
        for (let i = pivot + 1; i < end; i++) {
            if (arr[pivot] > arr[i]) {
                return false;
            }
        }
        return true;
    }

    while (!isPartitioned()) {
        for (let i = start; i < end; i++) {
            const j = i + Math.floor(Math.random() * (end - i));
            if (pivot === i) {
                pivot = j;
            } else if (pivot === j) {
                pivot = i;
            }
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
    }

    sort(arr, start, pivot);
    sort(arr, pivot + 1, end);
}

var array = [0, 39, 21, 62, 91, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
