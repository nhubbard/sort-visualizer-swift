function swap(arr, a, b) {
    const t = arr[a];
    arr[a] = arr[b];
    arr[b] = t;
}

function compareValues(a, b) {
    return (a > b ? 1 : (a < b ? -1 : 0));
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

function findKeys(arr, pos, len, numKeys) {
    let dist = 1;
    let foundKeys = 1;
    let firstKey = 0;
    while (dist < len && foundKeys < numKeys) {
        const loc = binSearch(arr, pos + firstKey, foundKeys, pos + dist, true);
        if (loc === foundKeys || arr[pos + dist] !== arr[pos + firstKey + loc]) {
            rotate(arr, pos + firstKey, foundKeys, dist - (firstKey + foundKeys));
            firstKey = dist - foundKeys;
            rotate(arr, pos + (firstKey + loc), foundKeys - loc, 1);
            foundKeys++;
        }
        dist++;
    }
    rotate(arr, pos, firstKey, foundKeys);
    return foundKeys;
}

function mergeWithoutBuffer(arr, pos, len1, len2) {
    if (len1 === 0 || len2 === 0) return;
    if (len1 < len2) {
        while (len1 !== 0) {
            const loc = binSearch(arr, pos + len1, len2, pos, true);
            if (loc !== 0) {
                rotate(arr, pos, len1, loc);
                pos += loc;
                len2 -= loc;
            }
            if (len2 === 0) break;
            do {
                pos++;
                len1--;
            } while (len1 !== 0 && arr[pos] <= arr[pos + len1]);
        }
    } else {
        while (len2 !== 0) {
            const loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false);
            if (loc !== len1) {
                rotate(arr, pos + loc, len1 - loc, len2);
                len1 = loc;
            }
            if (len1 === 0) break;
            do {
                len2--;
            } while (len2 !== 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]);
        }
    }
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

function smartMergeWithoutBuffer(arr, pos, leftOverLen, leftOverFrag, regBlockLen) {
    if (regBlockLen === 0) return [leftOverLen, leftOverFrag];
    let len1 = leftOverLen;
    let len2 = regBlockLen;
    const typeFrag = 1 - leftOverFrag;
    if (len1 !== 0 && (compareValues(arr[pos + len1 - 1], arr[pos + len1]) - typeFrag) >= 0) {
        while (len1 !== 0) {
            const foundLen = binSearch(arr, pos + len1, len2, pos, typeFrag !== 0);
            if (foundLen !== 0) {
                rotate(arr, pos, len1, foundLen);
                pos += foundLen;
                len2 -= foundLen;
            }
            if (len2 === 0) return [len1, leftOverFrag];
            do {
                pos++;
                len1--;
            } while (len1 !== 0 && (compareValues(arr[pos], arr[pos + len1]) - typeFrag) < 0);
        }
    }
    return [len2, typeFrag];
}

function smartMergeWithBuffer(arr, pos, leftOverLen, leftOverFrag, blockLen) {
    let dist = -blockLen;
    let left = 0;
    let right = leftOverLen;
    let leftEnd = right;
    let rightEnd = right + blockLen;
    const typeFrag = 1 - leftOverFrag;
    while (left < leftEnd && right < rightEnd) {
        if ((compareValues(arr[pos + left], arr[pos + right]) - typeFrag) < 0) {
            swap(arr, pos + dist, pos + left); dist++; left++;
        } else {
            swap(arr, pos + dist, pos + right); dist++; right++;
        }
    }
    let length;
    let fragment = leftOverFrag;
    if (left < leftEnd) {
        length = leftEnd - left;
        while (left < leftEnd) {
            leftEnd--; rightEnd--;
            swap(arr, pos + leftEnd, pos + rightEnd);
        }
    } else {
        length = rightEnd - right;
        fragment = typeFrag;
    }
    return [length, fragment];
}

function mergeBuffersLeft(arr, keysPos, midkey, pos, blockCount, blockLen, havebuf, aBlockCount, lastLen) {
    if (blockCount === 0) {
        const aBlocksLen = aBlockCount * blockLen;
        if (havebuf) mergeLeft(arr, pos, aBlocksLen, lastLen, -blockLen);
        else mergeWithoutBuffer(arr, pos, aBlocksLen, lastLen);
        return;
    }
    let leftOverLen = blockLen;
    let leftOverFrag = (arr[keysPos] < arr[midkey]) ? 0 : 1;
    let processIndex = blockLen;
    for (let keyIndex = 1; keyIndex < blockCount; keyIndex++) {
        let restToProcess = processIndex - leftOverLen;
        const nextFrag = (arr[keysPos + keyIndex] < arr[midkey]) ? 0 : 1;
        if (nextFrag === leftOverFrag) {
            if (havebuf) multiSwap(arr, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen);
            restToProcess = processIndex;
            leftOverLen = blockLen;
        } else {
            const result = havebuf
                ? smartMergeWithBuffer(arr, pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
                : smartMergeWithoutBuffer(arr, pos + restToProcess, leftOverLen, leftOverFrag, blockLen);
            leftOverLen = result[0];
            leftOverFrag = result[1];
        }
        processIndex += blockLen;
    }
    let restToProcess = processIndex - leftOverLen;
    if (lastLen !== 0) {
        if (leftOverFrag !== 0) {
            if (havebuf) multiSwap(arr, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen);
            restToProcess = processIndex;
            leftOverLen = blockLen * aBlockCount;
            leftOverFrag = 0;
        } else {
            leftOverLen += blockLen * aBlockCount;
        }
        if (havebuf) mergeLeft(arr, pos + restToProcess, leftOverLen, lastLen, -blockLen);
        else mergeWithoutBuffer(arr, pos + restToProcess, leftOverLen, lastLen);
    } else {
        if (havebuf) multiSwap(arr, pos + restToProcess, pos + restToProcess - blockLen, leftOverLen);
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

function combineBlocks(arr, keyPos, pos, len, buildLen, regBlockLen, havebuf) {
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
        insertSort(arr, keyPos, blockCount + (i === combineLen ? 1 : 0));
        let midkey = Math.floor(buildLen / regBlockLen);
        for (let index = 1; index < blockCount; index++) {
            let leftIndex = index - 1;
            for (let rightIndex = index; rightIndex < blockCount; rightIndex++) {
                const a = arr[blockPos + leftIndex * regBlockLen];
                const b = arr[blockPos + rightIndex * regBlockLen];
                if (a > b || (a === b && arr[keyPos + leftIndex] > arr[keyPos + rightIndex])) {
                    leftIndex = rightIndex;
                }
            }
            if (leftIndex !== index - 1) {
                multiSwap(arr, blockPos + (index - 1) * regBlockLen, blockPos + leftIndex * regBlockLen, regBlockLen);
                swap(arr, keyPos + (index - 1), keyPos + leftIndex);
                if (midkey === index - 1 || midkey === leftIndex) {
                    midkey ^= (index - 1) ^ leftIndex;
                }
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
        mergeBuffersLeft(arr, keyPos, keyPos + midkey, blockPos, blockCount - aBlockCount, regBlockLen, havebuf, aBlockCount, lastLen);
    }
    if (havebuf) {
        while (len > 0) {
            len--;
            swap(arr, pos + len, pos + len - regBlockLen);
        }
    }
}

function lazyStableSort(arr, pos, len) {
    for (let dist = 1; dist < len; dist += 2) {
        if (arr[pos + dist - 1] > arr[pos + dist]) swap(arr, pos + dist - 1, pos + dist);
    }
    let part = 2;
    while (part < len) {
        let left = 0;
        let right = len - 2 * part;
        while (left <= right) {
            mergeWithoutBuffer(arr, pos + left, part, part);
            left += 2 * part;
        }
        const rest = len - left;
        if (rest > part) mergeWithoutBuffer(arr, pos + left, part, rest - part);
        part *= 2;
    }
}

function commonSort(arr, pos, len) {
    if (len <= 16) {
        insertSort(arr, pos, len);
        return;
    }
    let blockLen = 1;
    while (blockLen * blockLen < len) blockLen *= 2;
    let numKeys = Math.floor((len - 1) / blockLen) + 1;
    const keysFound = findKeys(arr, pos, len, numKeys + blockLen);
    let bufferEnabled = true;
    if (keysFound < numKeys + blockLen) {
        if (keysFound < 4) {
            lazyStableSort(arr, pos, len);
            return;
        }
        numKeys = blockLen;
        while (numKeys > keysFound) numKeys = Math.floor(numKeys / 2);
        bufferEnabled = false;
        blockLen = 0;
    }
    const dist = blockLen + numKeys;
    let buildLen = bufferEnabled ? blockLen : numKeys;
    buildBlocks(arr, pos + dist, len - dist, buildLen);
    while (true) {
        buildLen *= 2;
        if (len - dist <= buildLen) break;
        let regBlockLen = blockLen;
        let buildBufEnabled = bufferEnabled;
        if (!bufferEnabled) {
            if (numKeys > 4 && Math.floor(numKeys / 8) * numKeys >= buildLen) {
                regBlockLen = Math.floor(numKeys / 2);
                buildBufEnabled = true;
            } else {
                let calcKeys = 1;
                let i = Math.floor((buildLen * keysFound) / 2);
                while (calcKeys < numKeys && i !== 0) {
                    calcKeys *= 2;
                    i = Math.floor(i / 8);
                }
                regBlockLen = Math.floor((2 * buildLen) / calcKeys);
            }
        }
        combineBlocks(arr, pos, pos + dist, len - dist, buildLen, regBlockLen, buildBufEnabled);
    }
    insertSort(arr, pos, dist);
    mergeWithoutBuffer(arr, pos, dist, len - dist);
}

function sort(arr) {
    const n = arr.length;
    commonSort(arr, 0, n);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
