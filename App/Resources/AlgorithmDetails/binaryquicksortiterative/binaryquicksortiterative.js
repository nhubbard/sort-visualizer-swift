function mostSignificantBit(value) {
    if (value === 0) return -1;
    let bit = 0;
    while ((value >> (bit + 1)) !== 0) bit++;
    return bit;
}

function partition(arr, p, r, bit) {
    let i = p - 1;
    let j = r + 1;
    while (true) {
        do {
            i++;
        } while (i <= r && ((arr[i] >> bit) & 1) === 0);
        do {
            j--;
        } while (j >= p && ((arr[j] >> bit) & 1) === 1);
        if (i < j) {
            [arr[i], arr[j]] = [arr[j], arr[i]];
        } else {
            return j;
        }
    }
}

function sort(arr) {
    const n = arr.length;
    let maxValue = arr[0];
    for (let i = 1; i < n; i++) {
        if (arr[i] > maxValue) maxValue = arr[i];
    }
    const bit = mostSignificantBit(maxValue);

    const tasks = [[0, n - 1, bit]];
    while (tasks.length > 0) {
        const [p, r, b] = tasks.shift();
        if (p < r && b >= 0) {
            const q = partition(arr, p, r, b);
            tasks.push([p, q, b - 1]);
            tasks.push([q + 1, r, b - 1]);
        }
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
