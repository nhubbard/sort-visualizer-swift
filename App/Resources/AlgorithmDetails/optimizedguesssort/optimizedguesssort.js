function sort(arr) {
    const n = arr.length;
    let loops = new Array(n).fill(0);

    function isValid() {
        for (let i = 0; i < n - 1; i++) {
            const a = arr[loops[i]];
            const b = arr[loops[i + 1]];
            if (a < b || (a === b && loops[i] < loops[i + 1])) {
                continue;
            }
            return false;
        }
        return true;
    }

    while (!isValid()) {
        for (let pos = 0; pos < n; pos++) {
            if (loops[pos] < n - 1) {
                loops[pos]++;
                break;
            } else {
                loops[pos] = 0;
            }
        }
    }

    const mapped = loops.map((i) => arr[i]);
    for (let i = 0; i < n; i++) {
        arr[i] = mapped[i];
    }
}

var array = [0, 39, 21, 62, 14];
sort(array);
console.log("[" + array.join(", ") + "]");
