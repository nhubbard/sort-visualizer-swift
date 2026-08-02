function stablePartition(arr, start, end) {
    const pivotValue = arr[start];
    const leftList = [];
    const rightList = [];

    for (let i = start + 1; i <= end; i++) {
        if (arr[i] < pivotValue) {
            leftList.push(arr[i]);
        } else {
            rightList.push(arr[i]);
        }
    }

    let writeIndex = start;
    for (const v of leftList) {
        arr[writeIndex++] = v;
    }
    const pivotIndex = writeIndex;
    arr[writeIndex++] = pivotValue;
    for (const v of rightList) {
        arr[writeIndex++] = v;
    }
    return pivotIndex;
}

function stableQuickSort(arr, start, end) {
    if (start < end) {
        const p = stablePartition(arr, start, end);
        stableQuickSort(arr, start, p - 1);
        stableQuickSort(arr, p + 1, end);
    }
}

function sort(arr) {
    const n = arr.length;
    stableQuickSort(arr, 0, n - 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
