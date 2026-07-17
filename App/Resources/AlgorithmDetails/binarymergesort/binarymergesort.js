function sort(arr) {
    const n = arr.length;
    if (n < 2) return;

    const threshold = 32;

    mergeSort(0, n);

    function insertionSort(start, end) {
        for (let i = start + 1; i < end; i++) {
            let j = i;
            while (j > start && arr[j] < arr[j - 1]) {
                [arr[j - 1], arr[j]] = [arr[j], arr[j - 1]];
                j--;
            }
        }
    }

    function mergeSort(start, end) {
        if (end - start <= threshold) {
            insertionSort(start, end);
            return;
        }
        const mid = start + Math.floor((end - start) / 2);
        mergeSort(start, mid);
        mergeSort(mid, end);
        merge(start, mid, end);
    }

    function merge(start, mid, end) {
        let low = start;
        let high = mid;
        const merged = [];
        while (low < mid && high < end) {
            if (arr[high] < arr[low]) {
                merged.push(arr[high]);
                high++;
            } else {
                merged.push(arr[low]);
                low++;
            }
        }
        while (low < mid) {
            merged.push(arr[low]);
            low++;
        }
        while (high < end) {
            merged.push(arr[high]);
            high++;
        }
        for (let i = 0; i < merged.length; i++) arr[start + i] = merged[i];
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
