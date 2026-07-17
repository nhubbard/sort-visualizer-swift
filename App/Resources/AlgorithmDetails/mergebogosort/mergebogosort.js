function sort(arr, start = 0, end = arr.length) {
    if (start >= end - 1) {
        return;
    }
    const mid = Math.floor((start + end) / 2);
    sort(arr, start, mid);
    sort(arr, mid, end);

    const saved = arr.slice(start, end);

    function isSorted() {
        for (let i = start; i < end - 1; i++) {
            if (arr[i] > arr[i + 1]) {
                return false;
            }
        }
        return true;
    }

    while (!isSorted()) {
        const indices = [...Array(end - start).keys()];
        for (let i = indices.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [indices[i], indices[j]] = [indices[j], indices[i]];
        }
        const highPositions = new Set(indices.slice(0, end - mid));

        let low = 0, high = mid - start;
        for (let offset = 0; offset < end - start; offset++) {
            if (highPositions.has(offset)) {
                arr[start + offset] = saved[high];
                high++;
            } else {
                arr[start + offset] = saved[low];
                low++;
            }
        }
    }
}

var array = [0, 39, 21, 62, 91, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
