function classify(value, minValue, c) {
    return Math.trunc((value - minValue) * c) + 1;
}

function flashSort(array) {
    var n = array.length;
    if (n === 0) return;

    var m = Math.trunc(0.2 * n) + 2;

    var minValue = array[0];
    var maxValue = array[0];
    var maxIndex = 0;

    var i = 1;
    while (i < n - 1) {
        var small, big, bigIndex;
        if (array[i] < array[i + 1]) {
            small = array[i];
            big = array[i + 1];
            bigIndex = i + 1;
        } else {
            big = array[i];
            bigIndex = i;
            small = array[i + 1];
        }
        if (big > maxValue) {
            maxValue = big;
            maxIndex = bigIndex;
        }
        if (small < minValue) {
            minValue = small;
        }
        i += 2;
    }

    var last = array[n - 1];
    if (last < minValue) {
        minValue = last;
    } else if (last > maxValue) {
        maxValue = last;
        maxIndex = n - 1;
    }

    if (maxValue === minValue) return;

    var L = new Array(m + 1).fill(0);
    var c = (m - 1.0) / (maxValue - minValue);

    for (var h = 0; h < n; h++) {
        var k = classify(array[h], minValue, c);
        L[k] += 1;
    }

    for (var k2 = 2; k2 <= m; k2++) {
        L[k2] += L[k2 - 1];
    }

    var tmpSwap = array[maxIndex];
    array[maxIndex] = array[0];
    array[0] = tmpSwap;

    var j = 0;
    var k = m;
    var numMoves = 0;
    while (numMoves < n) {
        while (j >= L[k]) {
            j += 1;
            k = classify(array[j], minValue, c);
        }

        var evicted = array[j];
        while (j < L[k]) {
            k = classify(evicted, minValue, c);
            var location = L[k] - 1;
            var temp = array[location];
            array[location] = evicted;
            evicted = temp;
            L[k] -= 1;
            numMoves += 1;
        }
    }

    for (var ii = 1; ii < n; ii++) {
        var current = array[ii];
        var pos = ii - 1;
        while (pos >= 0 && array[pos] > current) {
            array[pos + 1] = array[pos];
            pos -= 1;
        }
        array[pos + 1] = current;
    }
}

function sort(arr) {
    flashSort(arr);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
