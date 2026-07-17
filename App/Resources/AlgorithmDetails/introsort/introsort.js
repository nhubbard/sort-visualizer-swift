function sort(arr) {
    const n = arr.length;
    const sizeThreshold = 16;

    function medianOf3(left, mid, right) {
        if (!(arr[left] >= arr[right])) {
            [arr[left], arr[right]] = [arr[right], arr[left]];
        }
        if (!(arr[left] >= arr[mid])) {
            [arr[left], arr[mid]] = [arr[mid], arr[left]];
        }
        if (!(arr[mid] >= arr[right])) {
            [arr[mid], arr[right]] = [arr[right], arr[mid]];
        }
        return mid;
    }

    function partition(lo, hi, pivotValue) {
        let i = lo, j = hi;
        while (true) {
            while (arr[i] < pivotValue) i++;
            j--;
            while (pivotValue < arr[j]) j--;
            if (!(i < j)) return i;
            [arr[i], arr[j]] = [arr[j], arr[i]];
            i++;
        }
    }

    function heapSortRange(lo, hi) {
        const size = hi - lo;

        function siftDown(root, rangeSize) {
            while (true) {
                let largest = root;
                const left = 2 * root + 1;
                const right = 2 * root + 2;
                if (left < rangeSize && arr[lo + largest] < arr[lo + left]) largest = left;
                if (right < rangeSize && arr[lo + largest] < arr[lo + right]) largest = right;
                if (largest === root) break;
                [arr[lo + root], arr[lo + largest]] = [arr[lo + largest], arr[lo + root]];
                root = largest;
            }
        }

        for (let i = Math.floor(size / 2) - 1; i >= 0; i--) siftDown(i, size);
        for (let end = size - 1; end > 0; end--) {
            [arr[lo], arr[lo + end]] = [arr[lo + end], arr[lo]];
            siftDown(0, end);
        }
    }

    function introsortLoop(lo, hi, depthLimit) {
        while (hi - lo > sizeThreshold) {
            if (depthLimit === 0) {
                heapSortRange(lo, hi);
                return;
            }
            depthLimit--;
            const mid = lo + Math.floor((hi - lo) / 2);
            const pivotIndex = medianOf3(lo, mid, hi - 1);
            const pivotValue = arr[pivotIndex];
            const p = partition(lo, hi, pivotValue);
            introsortLoop(p, hi, depthLimit);
            hi = p;
        }
    }

    function insertionSort(start, end) {
        for (let i = start + 1; i < end; i++) {
            let j = i;
            while (j > start && arr[j] < arr[j - 1]) {
                [arr[j - 1], arr[j]] = [arr[j], arr[j - 1]];
                j--;
            }
        }
    }

    function floorLog2(a) {
        return Math.floor(Math.log(a) / Math.log(2));
    }

    introsortLoop(0, n, 2 * floorLog2(n));
    insertionSort(0, n);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
