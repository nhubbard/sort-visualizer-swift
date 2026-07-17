function sort(arr) {
    const n = arr.length;
    let heapSize = n - 1;

    function maxHeapify(i) {
        const left = 3 * i + 1;
        const mid = 3 * i + 2;
        const right = 3 * i + 3;
        let largest = i;
        if (left <= heapSize && arr[left] > arr[largest]) {
            largest = left;
        }
        if (right <= heapSize && arr[right] > arr[largest]) {
            largest = right;
        }
        if (mid <= heapSize && arr[mid] > arr[largest]) {
            largest = mid;
        }
        if (largest !== i) {
            [arr[i], arr[largest]] = [arr[largest], arr[i]];
            maxHeapify(largest);
        }
    }

    for (let i = n - 1; i >= 0; i--) {
        maxHeapify(i);
    }
    for (let i = n - 1; i >= 0; i--) {
        [arr[0], arr[i]] = [arr[i], arr[0]];
        heapSize -= 1;
        maxHeapify(0);
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
