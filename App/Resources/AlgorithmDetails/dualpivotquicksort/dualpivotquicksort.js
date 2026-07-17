function partition(array, low, high) {
    if (array[low] > array[high]) {
        [array[low], array[high]] = [array[high], array[low]];
    }
    var j = low + 1;
    var g = high - 1;
    var k = low + 1;
    var p = array[low];
    var q = array[high];
    while (k <= g) {
        if (array[k] < p) {
            [array[k], array[j]] = [array[j], array[k]];
            j++;
        } else if (array[k] >= q) {
            while (array[g] > q && k < g) {
                g--;
            }
            [array[k], array[g]] = [array[g], array[k]];
            g--;
            if (array[k] < p) {
                [array[k], array[j]] = [array[j], array[k]];
                j++;
            }
        }
        k++;
    }
    j--;
    g++;
    [array[low], array[j]] = [array[j], array[low]];
    [array[high], array[g]] = [array[g], array[high]];
    return [j, g];
}

function dualPivotQuickSort(array, low, high) {
    if (low < high) {
        var [j, g] = partition(array, low, high);
        dualPivotQuickSort(array, low, j - 1);
        dualPivotQuickSort(array, j + 1, g - 1);
        dualPivotQuickSort(array, g + 1, high);
    }
}

function sort(arr) {
    dualPivotQuickSort(arr, 0, arr.length - 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
