function sort(arr) {
    const end = arr.length;
    let i = 0;
    while (i < end - 1) {
        if (arr[i] > arr[i + 1]) {
            for (let f = i; f < end - 1; f++) {
                [arr[f], arr[f + 1]] = [arr[f + 1], arr[f]];
            }
            if (i > 0) i--;
            continue;
        }
        i++;
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
