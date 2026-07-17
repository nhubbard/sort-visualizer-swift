function sort(arr) {
    const n = arr.length;

    function isSorted() {
        for (let i = 0; i < n - 1; i++) {
            if (arr[i] > arr[i + 1]) {
                return false;
            }
        }
        return true;
    }

    function permutationSort(depth) {
        if (depth >= n - 1) {
            return isSorted();
        }
        for (let i = n - 1; i > depth; i--) {
            if (permutationSort(depth + 1)) {
                return true;
            }
            if ((n - depth) % 2 === 0) {
                [arr[depth], arr[i]] = [arr[i], arr[depth]];
            } else {
                [arr[depth], arr[n - 1]] = [arr[n - 1], arr[depth]];
            }
        }
        return permutationSort(depth + 1);
    }

    permutationSort(0);
}

var array = [0, 39, 21, 62, 91, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
