function sort(arr) {
    var n = arr.length;
    var min = arr[0];
    var max = arr[0];
    for (var i = 1; i < n; i++) {
        if (arr[i] < min) min = arr[i];
        if (arr[i] > max) max = arr[i];
    }

    var size = max - min + 1;
    var holes = new Array(size).fill(0);
    for (var i = 0; i < n; i++) {
        holes[arr[i] - min]++;
    }

    var j = 0;
    for (var count = 0; count < size; count++) {
        while (holes[count] > 0) {
            holes[count]--;
            arr[j] = count + min;
            j++;
        }
    }
    return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
