/* ArrayV's median-merge hybrid. The larger partition is an in-array swap
   buffer while the smaller partition is merge-sorted. No heap buffer is used. */
function exchange(a, i, j) {
  let value = a[i];
  a[i] = a[j];
  a[j] = value;
}

function insertion(a, first, end) {
  for (let i = first + 1; i < end; ++i)
    for (let j = i; j > first && a[j - 1] > a[j]; --j)
      exchange(a, j - 1, j);
}

function binary_insertion(a, first, end) {
  for (let i = first + 1; i < end; ++i) {
    let value = a[i], low = first, high = i;
    while (low < high) {
      let middle = low + Math.trunc((high - low) / 2);
      if (value < a[middle]) high = middle;
      else low = middle + 1;
    }
    for (let j = i; j > low; --j) a[j] = a[j - 1];
    a[low] = value;
  }
}

function median_three(a, first, end) {
  let middle = first + Math.trunc((end - 1 - first) / 2);
  if (a[first] > a[middle]) exchange(a, first, middle);
  if (a[middle] > a[end - 1]) {
    exchange(a, middle, end - 1);
    if (a[first] > a[middle]) return;
  }
  exchange(a, first, middle);
}

function median_medians(a, first, end) {
  let alternate = 1;
  while (end - first > 1) {
    let write = first, i = first;
    while (i + 10 <= end) {
      insertion(a, i, i + 5);
      exchange(a, write++, i + 2);
      i += 5;
    }
    if (i < end) {
      insertion(a, i, end);
      exchange(a, write++, i + Math.trunc((end - alternate - i) / 2));
      if ((end - i) % 2 == 0) alternate = !alternate;
    }
    end = write;
  }
}

function partition(a, first, end, pivot) {
  let i = first - 1, j = end;
  for (;;) {
    do { ++i; } while (i < j && a[i] < a[pivot]);
    do { --j; } while (j >= i && a[j] > a[pivot]);
    if (i >= j) return j;
    exchange(a, i, j);
  }
}

/* The destination contains displaced values, restored on the return pass. */
function merge(a, first, middle, end, destination) {
  let i = first, j = middle;
  while (i < middle && j < end) {
    if (a[i] <= a[j]) exchange(a, destination++, i++);
    else exchange(a, destination++, j++);
  }
  while (i < middle) exchange(a, destination++, i++);
  while (j < end) exchange(a, destination++, j++);
}

function merge_sort(a, first, end, buffer) {
  let length = end - first;
  if (length <= 1) return;
  let width = length;
  while (width >= 32) width = Math.trunc((width + 3) / 4);
  let i = first;
  while (i + width <= end) {
    binary_insertion(a, i, i + width);
    i += width;
  }
  binary_insertion(a, i, end);
  while (width < length) {
    let destination = buffer;
    i = first;
    while (i + 2 * width <= end) {
      merge(a, i, i + width, i + 2 * width, destination);
      i += 2 * width;
      destination += 2 * width;
    }
    if (i + width < end) merge(a, i, i + width, end, destination);
    else while (i < end) exchange(a, i++, destination++);
    width *= 2;

    destination = first;
    i = buffer;
    while (i + 2 * width <= buffer + length) {
      merge(a, i, i + width, i + 2 * width, destination);
      i += 2 * width;
      destination += 2 * width;
    }
    if (i + width < buffer + length)
      merge(a, i, i + width, buffer + length, destination);
    else while (i < buffer + length) exchange(a, i++, destination++);
    width *= 2;
  }
}

function sort(a, n) {
  let first = 0, end = n, bad_split = 0, used_medians = 0;
  while (end - first > 16) {
    if (bad_split) {
      median_medians(a, first, end);
      used_medians = 1;
    } else median_three(a, first, end);
    let pivot = partition(a, first + 1, end, first);
    exchange(a, first, pivot);
    let left = pivot - first, right = end - pivot - 1;
    bad_split = !used_medians &&
      (left == 0 || right == 0 ||
       (left > 0 && right > 0 && (Math.trunc(left / right) >= 16 || Math.trunc(right / left) >= 16)));
    if (left <= right) {
      merge_sort(a, first, pivot, pivot + 1);
      first = pivot + 1;
    } else {
      merge_sort(a, pivot + 1, end, 2 * pivot + 1 - end);
      end = pivot;
    }
  }
  binary_insertion(a, first, end);
}


const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
  68, 83, 32, 56, 10, 2, 95, 46, 21, 74, 6, 38];
sort(array, array.length);
console.log("[" + array.join(", ") + "]");
