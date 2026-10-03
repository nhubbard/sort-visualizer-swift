function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  let run = n;
  while (run >= 32) run = Math.floor((run + 1) / 2);

  function insertion(start, end) {
    for (let i = start + 1; i < end; i++) {
      const value = arr[i];
      let low = start;
      let high = i;
      while (low < high) {
        const middle = Math.floor((low + high) / 2);
        if (arr[middle] > value) high = middle;
        else low = middle + 1;
      }
      for (let j = i; j > low; j--) arr[j] = arr[j - 1];
      arr[low] = value;
    }
  }

  if (n <= 32) {
    insertion(0, n);
    return;
  }
  const half = Math.floor(n / 2);
  let buffer = arr.slice(half, 2 * half);

  function mergeBackward(start, middle, end, workspace) {
    const count = end - middle;
    for (let offset = 0; offset < count; offset++)
      arr[workspace + offset] = arr[middle + offset];
    let left = middle - 1;
    let right = workspace + count - 1;
    let output = end - 1;
    while (left >= start && right >= workspace) {
      if (arr[left] > arr[right]) arr[output--] = arr[left--];
      else arr[output--] = arr[right--];
    }
    while (right >= workspace) arr[output--] = arr[right--];
  }

  function sortSegment(start, end, workspace) {
    for (let lower = start; lower < end; lower += run)
      insertion(lower, Math.min(lower + run, end));
    for (let width = run; width < end - start; width *= 2) {
      for (let lower = start; lower < end; lower += 2 * width) {
        const middle = Math.min(lower + width, end);
        const upper = Math.min(lower + 2 * width, end);
        if (middle < upper) mergeBackward(lower, middle, upper, workspace);
      }
    }
  }

  sortSegment(0, half, half);
  for (let i = 0; i < half; i++) arr[half + i] = buffer[i];
  buffer = arr.slice(0, half);
  sortSegment(half, n, 0);
  let left = 0;
  let right = half;
  let output = 0;
  while (left < half && right < n) {
    if (buffer[left] <= arr[right]) arr[output++] = buffer[left++];
    else arr[output++] = arr[right++];
  }
  while (left < half) arr[output++] = buffer[left++];
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
