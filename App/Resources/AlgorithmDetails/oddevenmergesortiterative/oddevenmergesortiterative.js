function sort(arr) {
    const n = arr.length;

    for (let p = 1; p < n; p += p) {
        for (let k = p; k > 0; k = Math.floor(k / 2)) {
            for (let j = k % p; j + k < n; j += k + k) {
                for (let i = 0; i < k; i++) {
                    if (Math.floor((i + j) / (p + p)) === Math.floor((i + j + k) / (p + p))) {
                        if (i + j + k < n) {
                            if (arr[i + j] > arr[i + j + k]) {
                                [arr[i + j], arr[i + j + k]] = [arr[i + j + k], arr[i + j]];
                            }
                        }
                    }
                }
            }
        }
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");