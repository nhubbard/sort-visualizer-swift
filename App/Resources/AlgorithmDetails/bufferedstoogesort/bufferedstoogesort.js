function bufferedStoogeSort(arr, start, stop) {
  if (stop - start > 1) {
    if (stop - start === 2 && arr[start] > arr[stop - 1]) {
      [arr[start], arr[stop - 1]] = [arr[stop - 1], arr[start]];
    }
    if (stop - start > 2) {
      const width = stop - start;
      const third = Math.floor((width + 2) / 3) + start;
      let twoThird = Math.floor((2 * width + 2) / 3) + start;
      if (twoThird - third < third) {
        twoThird--;
      }
      if ((width - 2) % 3 === 0) {
        twoThird--;
      }

      bufferedStoogeSort(arr, third, twoThird);
      bufferedStoogeSort(arr, twoThird, stop);

      let left = third;
      let right = twoThird;
      let bufferStart = start;
      while (left < twoThird && right < stop) {
        if (arr[left] > arr[right]) {
          [arr[bufferStart], arr[right]] = [arr[right], arr[bufferStart]];
          right++;
        } else {
          [arr[bufferStart], arr[left]] = [arr[left], arr[bufferStart]];
          left++;
        }
        bufferStart++;
      }
      while (right < stop) {
        [arr[bufferStart], arr[right]] = [arr[right], arr[bufferStart]];
        right++;
        bufferStart++;
      }

      bufferedStoogeSort(arr, twoThird, stop);

      left = twoThird - 1;
      right = stop - 1;
      while (right > left && left >= start) {
        if (arr[left] > arr[right]) {
          for (let i = left; i < right; i++) {
            [arr[i], arr[i + 1]] = [arr[i + 1], arr[i]];
          }
          left--;
        }
        right--;
      }
    }
  }
}

function sort(arr) {
  bufferedStoogeSort(arr, 0, arr.length);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
