function swap(arr, a, b) {
    const t = arr[a];
    arr[a] = arr[b];
    arr[b] = t;
}

function multiSwap(arr, a, b, count) {
    for (let i = 0; i < count; i++) swap(arr, a + i, b + i);
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

function insertSort(arr, pos, len) {
    for (let i = 1; i < len; i++) {
        let j = pos + i;
        while (j > pos && arr[j] < arr[j - 1]) {
            swap(arr, j, j - 1);
            j--;
        }
    }
}

function binSearch(arr, pos, len, keyPos, isLeft) {
    let left = -1;
    let right = len;
    const key = arr[keyPos];
    while (left < right - 1) {
        const mid = left + Math.floor((right - left) / 2);
        const cond = isLeft ? (arr[pos + mid] >= key) : (arr[pos + mid] > key);
        if (cond) right = mid; else left = mid;
    }
    return right;
}

function mergeWithoutBuffer(arr, pos, len1, len2) {
    if (len1 === 0 || len2 === 0) return;
    if (len1 + len2 === 2) {
        if (arr[pos] > arr[pos + 1]) swap(arr, pos, pos + 1);
        return;
    }
    let mid1, mid2;
    if (len1 > len2) {
        mid1 = Math.floor(len1 / 2);
        mid2 = binSearch(arr, pos + len1, len2, pos + mid1, true);
    } else {
        mid2 = Math.floor(len2 / 2);
        mid1 = binSearch(arr, pos, len1, pos + len1 + mid2, false);
    }
    rotate(arr, pos + mid1, len1 - mid1, mid2);
    mergeWithoutBuffer(arr, pos, mid1, mid2);
    mergeWithoutBuffer(arr, pos + mid1 + mid2, len1 - mid1, len2 - mid2);
}

function mergeLeft(arr, pos, leftLen, rightLen, dist) {
    let left = 0;
    let right = leftLen;
    rightLen += leftLen;
    while (right < rightLen) {
        if (left === leftLen || arr[pos + left] > arr[pos + right]) {
            swap(arr, pos + dist, pos + right); dist++; right++;
        } else {
            swap(arr, pos + dist, pos + left); dist++; left++;
        }
    }
    if (dist !== left) multiSwap(arr, pos + dist, pos + left, leftLen - left);
}

function mergeRight(arr, pos, leftLen, rightLen, dist) {
    let mergedPos = leftLen + rightLen + dist - 1;
    let right = leftLen + rightLen - 1;
    let left = leftLen - 1;
    while (left >= 0) {
        if (right < leftLen || arr[pos + left] > arr[pos + right]) {
            swap(arr, pos + mergedPos, pos + left); mergedPos--; left--;
        } else {
            swap(arr, pos + mergedPos, pos + right); mergedPos--; right--;
        }
    }
    while (right !== mergedPos && right >= leftLen) {
        swap(arr, pos + mergedPos, pos + right); mergedPos--; right--;
    }
}

function smartMergeWithBuffer(arr, pos, leftOverLen, blockLen) {
    let dist = -blockLen;
    let left = 0;
    let right = leftOverLen;
    let leftEnd = right;
    let rightEnd = right + blockLen;
    let length;
    while (left < leftEnd && right < rightEnd) {
        if (arr[pos + left] <= arr[pos + right]) {
            swap(arr, pos + dist, pos + left); dist++; left++;
        } else {
            swap(arr, pos + dist, pos + right); dist++; right++;
        }
    }
    if (left < leftEnd) {
        length = leftEnd - left;
        while (left < leftEnd) {
            leftEnd--; rightEnd--;
            swap(arr, pos + leftEnd, pos + rightEnd);
        }
    } else {
        length = rightEnd - right;
    }
    return length;
}

function mergeBuffersLeft(arr, pos, blockCount, blockLen, aBlockCount, lastLen) {
    if (blockCount === 0) {
        mergeLeft(arr, pos, aBlockCount * blockLen, lastLen, -blockLen);
        return;
    }
    let leftOverLen = blockLen;
    let processIndex = blockLen;
    for (let keyIndex = 1; keyIndex < blockCount; keyIndex++) {
        const restToProcess = processIndex - leftOverLen;
        leftOverLen = smartMergeWithBuffer(arr, pos + restToProcess, leftOverLen, blockLen);
        processIndex += blockLen;
    }
    const restToProcess = processIndex - leftOverLen;
    if (lastLen !== 0) {
        leftOverLen += blockLen * aBlockCount;
        mergeLeft(arr, pos + restToProcess, leftOverLen, lastLen, -blockLen);
    } else {
        multiSwap(arr, pos + restToProcess, pos + restToProcess - blockLen, leftOverLen);
    }
}

function buildBlocks(arr, pos, len, buildLen) {
    for (let dist = 1; dist < len; dist += 2) {
        const extraDist = (arr[pos + dist - 1] > arr[pos + dist]) ? 1 : 0;
        swap(arr, pos + dist - 3, pos + dist - 1 + extraDist);
        swap(arr, pos + dist - 2, pos + dist - extraDist);
    }
    if (len % 2 === 1) swap(arr, pos + len - 1, pos + len - 3);
    pos -= 2;
    let part = 2;
    while (part < buildLen) {
        let left = 0;
        let right = len - 2 * part;
        while (left <= right) {
            mergeLeft(arr, pos + left, part, part, -part);
            left += 2 * part;
        }
        const rest = len - left;
        if (rest > part) mergeLeft(arr, pos + left, part, rest - part, -part);
        else rotate(arr, pos + left - part, part, rest);
        pos -= part;
        part *= 2;
    }
    const restToBuild = len % (2 * buildLen);
    let leftOverPos = len - restToBuild;
    if (restToBuild <= buildLen) rotate(arr, pos + leftOverPos, restToBuild, buildLen);
    else mergeRight(arr, pos + leftOverPos, buildLen, restToBuild - buildLen, buildLen);
    while (leftOverPos > 0) {
        leftOverPos -= 2 * buildLen;
        mergeRight(arr, pos + leftOverPos, buildLen, buildLen, buildLen);
    }
}

function combineBlocks(arr, pos, len, buildLen, regBlockLen) {
    const combineLen = Math.floor(len / (2 * buildLen));
    let leftOver = len % (2 * buildLen);
    if (leftOver <= buildLen) {
        len -= leftOver;
        leftOver = 0;
    }
    for (let i = 0; i <= combineLen; i++) {
        if (i === combineLen && leftOver === 0) break;
        const blockPos = pos + i * 2 * buildLen;
        const blockCount = Math.floor((i === combineLen ? leftOver : 2 * buildLen) / regBlockLen);
        for (let index = 1; index < blockCount; index++) {
            let leftIndex = index - 1;
            for (let rightIndex = index; rightIndex < blockCount; rightIndex++) {
                const a = arr[blockPos + leftIndex * regBlockLen];
                const b = arr[blockPos + rightIndex * regBlockLen];
                const cmp = (a > b ? 1 : (a < b ? -1 : 0));
                if (cmp > 0 || (cmp === 0 && arr[blockPos + (leftIndex + 1) * regBlockLen - 1] >
                                                  arr[blockPos + (rightIndex + 1) * regBlockLen - 1])) {
                    leftIndex = rightIndex;
                }
            }
            if (leftIndex !== index - 1) {
                multiSwap(arr, blockPos + (index - 1) * regBlockLen, blockPos + leftIndex * regBlockLen, regBlockLen);
            }
        }
        let aBlockCount = 0;
        const lastLen = (i === combineLen) ? (leftOver % regBlockLen) : 0;
        if (lastLen !== 0) {
            while (aBlockCount < blockCount &&
                   arr[blockPos + blockCount * regBlockLen] < arr[blockPos + (blockCount - aBlockCount - 1) * regBlockLen]) {
                aBlockCount++;
            }
        }
        mergeBuffersLeft(arr, blockPos, blockCount - aBlockCount, regBlockLen, aBlockCount, lastLen);
    }
    while (len > 0) {
        len--;
        swap(arr, pos + len, pos + len - regBlockLen);
    }
}

function commonSort(arr, pos, len) {
    if (len <= 16) {
        insertSort(arr, pos, len);
        return;
    }
    let blockLen = 1;
    while (blockLen * blockLen < len) blockLen *= 2;
    let buildLen = blockLen;
    buildBlocks(arr, pos + blockLen, len - blockLen, buildLen);
    while (true) {
        buildLen *= 2;
        if (len - blockLen <= buildLen) break;
        combineBlocks(arr, pos + blockLen, len - blockLen, buildLen, blockLen);
    }
    insertSort(arr, pos, blockLen);
    mergeWithoutBuffer(arr, pos, blockLen, len - blockLen);
}

function sort(arr) {
    const n = arr.length;
    commonSort(arr, 0, n);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
