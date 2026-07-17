function sort(arr) {
    var i = arr.length - 1;
    while (i > 0) {
        var consecSorted = 1;
        for (var j = 0; j < i; j++) {
            if (arr[j] > arr[j + 1]) {
                [arr[j], arr[j + 1]] = [arr[j + 1], arr[j]];
                consecSorted = 1;
            } else {
                consecSorted++;
            }
        }
        i -= consecSorted;
    }
    return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
