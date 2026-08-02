const INSERT_SORT_THRESHOLD = 24;
const NINTHER_THRESHOLD = 128;
const PARTIAL_INSERT_SORT_LIMIT = 8;

function pdqLog(n) {
    let log = 0;
    while ((n >>= 1) !== 0) log++;
    return log;
}

function insertSort(arr, begin, end) {
    for (let cur = begin + 1; cur < end; cur++) {
        if (arr[cur] < arr[cur - 1]) {
            const tmp = arr[cur];
            let sift = cur;
            let siftMinusOne = cur - 1;
            do {
                arr[sift--] = arr[siftMinusOne--];
            } while (sift !== begin && tmp < arr[siftMinusOne]);
            arr[sift] = tmp;
        }
    }
}

function unguardInsertSort(arr, begin, end) {
    for (let cur = begin + 1; cur < end; cur++) {
        if (arr[cur] < arr[cur - 1]) {
            const tmp = arr[cur];
            let sift = cur;
            let siftMinusOne = cur - 1;
            do {
                arr[sift--] = arr[siftMinusOne--];
            } while (tmp < arr[siftMinusOne]);
            arr[sift] = tmp;
        }
    }
}

function partialInsertSort(arr, begin, end) {
    let limit = 0;
    for (let cur = begin + 1; cur < end; cur++) {
        if (limit > PARTIAL_INSERT_SORT_LIMIT) return false;
        if (arr[cur] < arr[cur - 1]) {
            const tmp = arr[cur];
            let sift = cur;
            let siftMinusOne = cur - 1;
            do {
                arr[sift--] = arr[siftMinusOne--];
            } while (sift !== begin && tmp < arr[siftMinusOne]);
            arr[sift] = tmp;
            limit += cur - sift;
        }
    }
    return true;
}

function sortTwo(arr, a, b) {
    if (arr[b] < arr[a]) {
        const t = arr[a];
        arr[a] = arr[b];
        arr[b] = t;
    }
}

function sortThree(arr, a, b, c) {
    sortTwo(arr, a, b);
    sortTwo(arr, b, c);
    sortTwo(arr, a, b);
}

function swap(arr, a, b) {
    const t = arr[a];
    arr[a] = arr[b];
    arr[b] = t;
}

function partRight(arr, begin, end) {
    const pivot = arr[begin];
    let first = begin;
    let last = end;

    first++;
    while (arr[first] < pivot) first++;

    if (first - 1 === begin) {
        last--;
        while (first < last && !(arr[last] < pivot)) last--;
    } else {
        last--;
        while (!(arr[last] < pivot)) last--;
    }

    const alreadyParted = first >= last;
    while (first < last) {
        swap(arr, first, last);
        first++;
        while (arr[first] < pivot) first++;
        last--;
        while (!(arr[last] < pivot)) last--;
    }

    const pivotPos = first - 1;
    arr[begin] = arr[pivotPos];
    arr[pivotPos] = pivot;

    return [pivotPos, alreadyParted];
}

function partLeft(arr, begin, end) {
    const pivot = arr[begin];
    let first = begin;
    let last = end;

    last--;
    while (pivot < arr[last]) last--;

    if (last + 1 === end) {
        first++;
        while (first < last && !(pivot < arr[first])) first++;
    } else {
        first++;
        while (!(pivot < arr[first])) first++;
    }

    while (first < last) {
        swap(arr, first, last);
        last--;
        while (pivot < arr[last]) last--;
        first++;
        while (!(pivot < arr[first])) first++;
    }

    const pivotPos = last;
    arr[begin] = arr[pivotPos];
    arr[pivotPos] = pivot;
    return pivotPos;
}

function siftDown(arr, begin, root, size) {
    while (true) {
        let child = 2 * root + 1;
        if (child >= size) break;
        if (child + 1 < size && arr[begin + child] < arr[begin + child + 1]) child++;
        if (arr[begin + root] < arr[begin + child]) {
            swap(arr, begin + root, begin + child);
            root = child;
        } else {
            break;
        }
    }
}

function heapSort(arr, begin, end) {
    const n = end - begin;
    for (let i = Math.floor(n / 2) - 1; i >= 0; i--) siftDown(arr, begin, i, n);
    for (let i = n - 1; i > 0; i--) {
        swap(arr, begin, begin + i);
        siftDown(arr, begin, 0, i);
    }
}

function pdqLoop(arr, begin, end, badAllowed) {
    let leftmost = true;
    while (true) {
        const size = end - begin;

        if (size < INSERT_SORT_THRESHOLD) {
            if (leftmost) insertSort(arr, begin, end);
            else unguardInsertSort(arr, begin, end);
            return;
        }

        const halfSize = Math.floor(size / 2);
        if (size > NINTHER_THRESHOLD) {
            sortThree(arr, begin, begin + halfSize, end - 1);
            sortThree(arr, begin + 1, begin + halfSize - 1, end - 2);
            sortThree(arr, begin + 2, begin + halfSize + 1, end - 3);
            sortThree(arr, begin + halfSize - 1, begin + halfSize, begin + halfSize + 1);
            swap(arr, begin, begin + halfSize);
        } else {
            sortThree(arr, begin + halfSize, begin, end - 1);
        }

        if (!leftmost && !(arr[begin - 1] < arr[begin])) {
            begin = partLeft(arr, begin, end) + 1;
            continue;
        }

        const [pivotPos, alreadyParted] = partRight(arr, begin, end);

        const leftSize = pivotPos - begin;
        const rightSize = end - (pivotPos + 1);
        const highUnbalance = leftSize < Math.floor(size / 8) || rightSize < Math.floor(size / 8);

        if (highUnbalance) {
            badAllowed--;
            if (badAllowed === 0) {
                heapSort(arr, begin, end);
                return;
            }

            if (leftSize >= INSERT_SORT_THRESHOLD) {
                swap(arr, begin, begin + Math.floor(leftSize / 4));
                swap(arr, pivotPos - 1, pivotPos - Math.floor(leftSize / 4));
                if (leftSize > NINTHER_THRESHOLD) {
                    swap(arr, begin + 1, begin + (Math.floor(leftSize / 4) + 1));
                    swap(arr, begin + 2, begin + (Math.floor(leftSize / 4) + 2));
                    swap(arr, pivotPos - 2, pivotPos - (Math.floor(leftSize / 4) + 1));
                    swap(arr, pivotPos - 3, pivotPos - (Math.floor(leftSize / 4) + 2));
                }
            }

            if (rightSize >= INSERT_SORT_THRESHOLD) {
                swap(arr, pivotPos + 1, pivotPos + (1 + Math.floor(rightSize / 4)));
                swap(arr, end - 1, end - Math.floor(rightSize / 4));
                if (rightSize > NINTHER_THRESHOLD) {
                    swap(arr, pivotPos + 2, pivotPos + (2 + Math.floor(rightSize / 4)));
                    swap(arr, pivotPos + 3, pivotPos + (3 + Math.floor(rightSize / 4)));
                    swap(arr, end - 2, end - (1 + Math.floor(rightSize / 4)));
                    swap(arr, end - 3, end - (2 + Math.floor(rightSize / 4)));
                }
            }
        } else {
            if (alreadyParted && partialInsertSort(arr, begin, pivotPos) && partialInsertSort(arr, pivotPos + 1, end)) {
                return;
            }
        }

        pdqLoop(arr, begin, pivotPos, badAllowed);
        begin = pivotPos + 1;
        leftmost = false;
    }
}

function sort(arr) {
    const n = arr.length;
    if (n < 2) return;
    pdqLoop(arr, 0, n, pdqLog(n));
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
