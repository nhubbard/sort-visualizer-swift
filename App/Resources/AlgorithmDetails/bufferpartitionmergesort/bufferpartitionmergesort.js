function sort(arr) {
  const run = 8;
  for (let start = 0; start < arr.length; start += run) {
    const end = Math.min(start + run, arr.length);
    for (let i = start + 1; i < end; i += 1) {
      const value = arr[i];
      let j = i;
      while (j > start && arr[j - 1] > value) {
        arr[j] = arr[j - 1];
        j -= 1;
      }
      arr[j] = value;
    }
  }

  const scratch = arr.slice();
  for (let width = run; width < arr.length; width *= 2) {
    for (let start = 0; start < arr.length; start += 2 * width) {
      const middle = Math.min(start + width, arr.length);
      const end = Math.min(start + 2 * width, arr.length);
      let left = start;
      let right = middle;
      for (let out = start; out < end; out += 1) {
        if (left < middle && (right >= end || arr[left] < arr[right])) {
          scratch[out] = arr[left];
          left += 1;
        } else {
          scratch[out] = arr[right];
          right += 1;
        }
      }
    }
    for (let i = 0; i < arr.length; i += 1) arr[i] = scratch[i];
  }
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
