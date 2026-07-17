function minFrom(arr, i) {
    var m = arr[i];
    for (var k = i + 1; k < arr.length; k++) {
        if (arr[k] < m) {
            m = arr[k];
        }
    }
    return m;
}

function sort(arr) {
    const n = arr.length;
    for (let i = 0; i < n; i++) {
        while (arr[i] !== minFrom(arr, i)) {
            const j = i + Math.floor(Math.random() * (n - i));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
    }
}

var array = [0, 39, 21, 62, 91, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
