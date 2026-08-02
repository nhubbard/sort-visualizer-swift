function insertionSort(arr, start, end) {
    for (let i = start + 1; i < end; i++) {
        const key = arr[i];
        let j = i - 1;
        while (j >= start && arr[j] > key) {
            arr[j + 1] = arr[j];
            j--;
        }
        arr[j + 1] = key;
    }
}

function shatterPartition(arr, start, length, num) {
    let minV = arr[start];
    let maxV = arr[start];
    for (let i = 1; i < length; i++) {
        if (arr[start + i] < minV) minV = arr[start + i];
        if (arr[start + i] > maxV) maxV = arr[start + i];
    }
    const valueRange = maxV - minV + 1;
    const shatters = Math.ceil(length / num);

    const buckets = [];
    for (let i = 0; i < shatters; i++) buckets.push([]);

    for (let i = 0; i < length; i++) {
        const v = arr[start + i];
        let idx = Math.floor((v - minV) * shatters / valueRange);
        if (idx > shatters - 1) idx = shatters - 1;
        buckets[idx].push(v);
    }

    const offsets = new Array(shatters + 1).fill(0);
    for (let i = 0; i < shatters; i++) offsets[i + 1] = offsets[i] + buckets[i].length;

    let pos = start;
    for (const bucket of buckets) {
        for (const v of bucket) arr[pos++] = v;
    }
    return offsets;
}

function floorLog2(n) {
    let log = 0;
    let m = n;
    while (m > 1) {
        m = Math.floor(m / 2);
        log++;
    }
    return log;
}

function simpleShatterSort(arr, length, num, rate) {
    let i = num;
    while (i > 1) {
        shatterPartition(arr, 0, length, i);
        i = Math.floor(i / rate);
    }
    const offsets = shatterPartition(arr, 0, length, 1);
    for (let k = 0; k < offsets.length - 1; k++) {
        if (offsets[k + 1] - offsets[k] > 1) insertionSort(arr, offsets[k], offsets[k + 1]);
    }
}

function sort(arr) {
    const n = arr.length;
    const rate = Math.max(2, Math.floor(floorLog2(n) / 2));
    simpleShatterSort(arr, n, 4, rate);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
