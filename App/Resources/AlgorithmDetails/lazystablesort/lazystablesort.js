function multiSwap(arr, a, b, count) {
    for (let i = 0; i < count; i++) {
        [arr[a + i], arr[b + i]] = [arr[b + i], arr[a + i]];
    }
}

function rotate(arr, pos, lenA, lenB) {
    while (lenA !== 0 && lenB !== 0) {
        if (lenA <= lenB) {
            multiSwap(arr, pos, pos + lenA, lenA);
            pos += lenA;
            lenB -= lenA;
        } else {
            multiSwap(arr, pos + (lenA - lenB), pos + lenA, lenB);
            lenA -= lenB;
        }
    }
}

function binSearch(arr, pos, len, keyPos, isLeft) {
    let left = 0;
    let right = len;
    while (left < right) {
        const mid = left + Math.floor((right - left) / 2);
        const cond = isLeft ? arr[pos + mid] < arr[keyPos] : arr[pos + mid] <= arr[keyPos];
        if (cond) left = mid + 1;
        else right = mid;
    }
    return left;
}

function mergeWithoutBuffer(arr, pos, len1, len2) {
    if (len1 === 0 || len2 === 0) return;
    if (len1 === 1) {
        const loc = binSearch(arr, pos + 1, len2, pos, true);
        rotate(arr, pos, 1, loc);
        return;
    }
    if (len2 === 1) {
        const loc = binSearch(arr, pos, len1, pos + len1, false);
        rotate(arr, pos + loc, len1 - loc, 1);
        return;
    }
    const mid1 = Math.floor(len1 / 2);
    const loc = binSearch(arr, pos + len1, len2, pos + mid1, true);
    rotate(arr, pos + mid1, len1 - mid1, loc);
    mergeWithoutBuffer(arr, pos, mid1, loc);
    mergeWithoutBuffer(arr, pos + mid1 + loc, len1 - mid1, len2 - loc);
}

function sort(arr) {
    const n = arr.length;
    let dist = 1;
    while (dist < n) {
        if (arr[dist - 1] > arr[dist]) {
            [arr[dist - 1], arr[dist]] = [arr[dist], arr[dist - 1]];
        }
        dist += 2;
    }
    let part = 2;
    while (part < n) {
        let left = 0;
        const right = n - 2 * part;
        while (left <= right) {
            mergeWithoutBuffer(arr, left, part, part);
            left += 2 * part;
        }
        const rest = n - left;
        if (rest > part) mergeWithoutBuffer(arr, left, part, rest - part);
        part *= 2;
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
