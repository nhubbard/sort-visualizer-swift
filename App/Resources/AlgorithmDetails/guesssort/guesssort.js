function sort(arr) {
    const n = arr.length;
    const loops = new Array(n).fill(0);
    const indexes = new Array(n).fill(0);

    function isValid() {
        let total = 0;
        for (let i = 0; i < n; i++) {
            for (let j = 0; j < n; j++) {
                if (loops[i] === loops[j]) {
                    total += 1;
                }
            }
        }
        for (let i = 0; i < n; i++) {
            for (let j = 0; j < n; j++) {
                if (i < j && arr[loops[i]] > arr[loops[j]]) {
                    total += 1;
                } else if (i > j && arr[loops[i]] < arr[loops[j]]) {
                    total += 1;
                }
            }
        }
        return total === n;
    }

    while (true) {
        if (isValid()) {
            for (let i = 0; i < n; i++) {
                indexes[i] = loops[i];
            }
        }
        let pos = 0;
        while (pos < n) {
            if (loops[pos] < n - 1) {
                loops[pos] += 1;
                break;
            } else {
                loops[pos] = 0;
                pos += 1;
            }
        }
        if (pos === n) {
            break;
        }
    }

    const original = arr.slice();
    for (let i = 0; i < n; i++) {
        arr[i] = original[indexes[i]];
    }
}

var array = [0, 39, 21, 14];
sort(array);
console.log("[" + array.join(", ") + "]");
