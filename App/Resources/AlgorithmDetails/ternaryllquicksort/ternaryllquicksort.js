function compare3(arr, a, b) {
    if (arr[a] === arr[b]) return 0;
    return arr[a] > arr[b] ? 1 : -1;
}

function selectPivot(arr, lo, hi) {
    const mid = Math.floor((lo + hi) / 2);
    const cLoMid = compare3(arr, lo, mid);
    if (cLoMid === 0) return lo;
    const cLoHi = compare3(arr, lo, hi - 1);
    const cMidHi = compare3(arr, mid, hi - 1);
    if (cLoHi === 0 || cMidHi === 0) return hi - 1;

    if (cLoMid < 0) {
        return cMidHi < 0 ? mid : (cLoHi < 0 ? hi - 1 : lo);
    } else {
        return cMidHi > 0 ? mid : (cLoHi < 0 ? lo : hi - 1);
    }
}

function partitionTernaryLL(arr, lo, hi) {
    const p = selectPivot(arr, lo, hi);
    [arr[p], arr[hi - 1]] = [arr[hi - 1], arr[p]];
    const pivotIndex = hi - 1;

    let i = lo;
    let k = hi - 1;

    for (let j = lo; j < k; j++) {
        const cmp = compare3(arr, j, pivotIndex);
        if (cmp === 0) {
            k--;
            [arr[k], arr[j]] = [arr[j], arr[k]];
            j--;
        } else if (cmp < 0) {
            [arr[i], arr[j]] = [arr[j], arr[i]];
            i++;
        }
    }

    for (let s = 0; s < hi - k; s++) {
        [arr[i + s], arr[hi - 1 - s]] = [arr[hi - 1 - s], arr[i + s]];
    }

    return {first: i, second: i + (hi - k)};
}

function quicksortTernaryLL(arr, lo, hi) {
    if (lo + 1 < hi) {
        const mid = partitionTernaryLL(arr, lo, hi);
        quicksortTernaryLL(arr, lo, mid.first);
        quicksortTernaryLL(arr, mid.second, hi);
    }
}

function sort(arr) {
    quicksortTernaryLL(arr, 0, arr.length);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
