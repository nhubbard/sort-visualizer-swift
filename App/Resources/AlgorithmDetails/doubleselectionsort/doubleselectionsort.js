function doubleSelectionSort(array) {
    var n = array.length;
    if (n <= 1) {
        return;
    }

    var left = 0;
    var right = n - 1;
    var smallest = 0;
    var biggest = 0;

    while (left <= right) {
        for (var i = left; i <= right; i++) {
            if (array[i] > array[biggest]) {
                biggest = i;
            }
            if (array[i] < array[smallest]) {
                smallest = i;
            }
        }

        if (biggest === left) {
            biggest = smallest;
        }

        var temp = array[left];
        array[left] = array[smallest];
        array[smallest] = temp;

        temp = array[right];
        array[right] = array[biggest];
        array[biggest] = temp;

        left++;
        right--;
        smallest = left;
        biggest = right;
    }
}

function sort(arr) {
    doubleSelectionSort(arr);
    return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
