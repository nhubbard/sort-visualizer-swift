function compSwap(arr, a, b) {
    if (arr[a] > arr[b]) {
        [arr[a], arr[b]] = [arr[b], arr[a]];
        return true;
    }
    return false;
}

function stoogeSort(arr, a, m, b, merge) {
    if (a >= m) return false;
    if (b - a === 2) return compSwap(arr, a, m);

    let lChange = false;
    let rChange = false;

    const a2 = Math.floor((a + a + b) / 3);
    const b2 = Math.floor((a + b + b + 2) / 3);

    if (m < b2) {
        lChange = stoogeSort(arr, a, m, b2, merge);
        if (merge) {
            rChange = stoogeSort(arr, Math.max(a + b2 - m, a2), b2, b, true);
            if (rChange) {
                stoogeSort(arr, a + b2 - m, a2, 2 * a2 - a, true);
            }
        } else {
            rChange = stoogeSort(arr, a2, b2, b, false);
            if (rChange) {
                stoogeSort(arr, a, a2, 2 * a2 - a, true);
            }
        }
    } else {
        rChange = stoogeSort(arr, a2, m, b, merge);
        if (rChange) {
            stoogeSort(arr, a, a2, a2 + b - m, true);
        }
    }

    return lChange || rChange;
}

function sort(arr) {
    stoogeSort(arr, 0, 1, arr.length, false);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
