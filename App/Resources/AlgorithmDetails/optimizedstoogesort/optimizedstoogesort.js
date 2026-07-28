function forward(arr, left, right) {
    while (left < right) {
        let index = right;
        while (left < index) {
            if (arr[left] > arr[index]) {
                [arr[left], arr[index]] = [arr[index], arr[left]];
            }
            left++;
            index--;
        }
        left = 0;
        right--;
    }
}

function backward(arr, left, right) {
    const length = right;
    while (left < right) {
        let index = left;
        while (index < right) {
            if (arr[index] > arr[right]) {
                [arr[index], arr[right]] = [arr[right], arr[index]];
            }
            index++;
            right--;
        }
        left++;
        right = length;
    }
}

function exchange(arr, length) {
    let left = 0;
    let right = length - 1;
    while (left < right) {
        if (arr[left] > arr[right]) {
            [arr[left], arr[right]] = [arr[right], arr[left]];
        }
        left++;
        right--;
    }

    forward(arr, 0, length - 2);
    backward(arr, 1, length - 1);
}

function sort(arr) {
    exchange(arr, arr.length);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
