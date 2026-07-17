function sort(arr) {
    const n = arr.length;
    const idx = [...Array(n).keys()];

    function isSorted(a) {
        for (let i = 1; i < a.length; i++) {
            if (a[i] < a[i - 1]) {
                return false;
            }
        }
        return true;
    }

    function permute(length) {
        if (length < 2) {
            return isSorted(arr);
        }
        for (let i = length - 2; i >= 0; i--) {
            if (permute(length - 1)) {
                return true;
            }
            const t1 = arr[idx[i]];
            arr[idx[i]] = arr[idx[length - 1]];
            arr[idx[length - 1]] = t1;
            const t2 = idx[i];
            idx[i] = idx[length - 1];
            idx[length - 1] = t2;
        }
        if (permute(length - 1)) {
            return true;
        }
        let t = idx[length - 1];
        for (let i = length - 1; i > 0; i--) {
            idx[i] = idx[i - 1];
        }
        idx[0] = t;
        t = arr[idx[0]];
        for (let i = 1; i < length; i++) {
            arr[idx[i - 1]] = arr[idx[i]];
        }
        arr[idx[length - 1]] = t;
        return false;
    }

    permute(n);
}

var array = [0, 39, 21, 62, 91, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
