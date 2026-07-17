function sort(arr, start = 0, end = arr.length) {
    if (start >= end - 1) {
        return;
    }
    const mid = Math.floor((start + end) / 2);

    function isSplit() {
        let lowMax = arr[start];
        for (let i = start + 1; i < mid; i++) {
            if (arr[i] > lowMax) {
                lowMax = arr[i];
            }
        }
        for (let i = mid; i < end; i++) {
            if (lowMax > arr[i]) {
                return false;
            }
        }
        return true;
    }

    while (!isSplit()) {
        const sub = arr.slice(start, end);
        for (let i = sub.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const tmp = sub[i];
            sub[i] = sub[j];
            sub[j] = tmp;
        }
        for (let i = start; i < end; i++) {
            arr[i] = sub[i - start];
        }
    }

    sort(arr, start, mid);
    sort(arr, mid, end);
}

var array = [0, 39, 21, 62, 91, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
