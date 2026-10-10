/* ArrayV's buffer-partition merge: select a prefix, sort it through an
   in-array swap buffer, then merge it into the growing sorted suffix. */
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

function shift_backward(a, first, middle, end) {
  while (middle > first) exchange(a, --end, --middle);
}

function multi_swap(a, first, second, length) {
  for (let i = 0; i < length; ++i) exchange(a, first + i, second + i);
}

function rotate(a, first, middle, end) {
  let left = middle - first, right = end - middle;
  while (left > 0 && right > 0) {
    if (right < left) {
      multi_swap(a, middle - right, middle, right);
      end -= right; middle -= right; left -= right;
    } else {
      multi_swap(a, first, middle, left);
      first += left; middle += left; right -= left;
    }
  }
}

function in_place_merge(a, first, middle, end) {
  let left = first, right = middle;
  while (left < right && right < end) {
    if (a[left] > a[right]) {
      let upper = right + 1;
      while (upper < end && a[left] > a[upper]) ++upper;
      rotate(a, left, right, upper);
      left += upper - right;
      right = upper;
    } else ++left;
  }
}

function partition(a, first, end) {
  let left = first, right = end;
  for (;;) {
    do { ++left; } while (left < right && a[left] > a[first]);
    do { --right; } while (right >= left && a[right] < a[first]);
    if (left >= right) return right;
    exchange(a, left, right);
  }
}

function quick_select(a, lower, upper, target) {
  let bad_split = 0, used_medians = 0;
  let target_upper = Math.trunc((target + upper + 1) / 2);
  for (;;) {
    if (bad_split) { median_medians(a, lower, upper); used_medians = 1; }
    else median_three(a, lower, upper);
    let pivot = partition(a, lower, upper);
    exchange(a, lower, pivot);
    let left = pivot - lower, right = upper - pivot - 1;
    if (left < 1) left = 1;
    if (right < 1) right = 1;
    bad_split = !used_medians && (Math.trunc(left / right) >= 16 || Math.trunc(right / left) >= 16);
    if (pivot >= target && pivot < target_upper) return pivot;
    if (pivot < target) lower = pivot + 1;
    else upper = pivot;
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

function merge_forward(a, destination, first, middle, end) {
  let left = first, right = middle;
  while (left < middle && right < end) {
    if (a[left] <= a[right]) exchange(a, destination++, left++);
    else exchange(a, destination++, right++);
  }
  return left < middle ? left : right;
}

function sort(a, n) {
  if (n <= 1) return;
  let first = 0, middle = Math.trunc((n + 1) / 2);
  let minimum = Math.trunc(Math.sqrt(n));
  merge_sort(a, middle, n, first);
  while (middle - first > minimum) {
    let selected = Math.trunc((first + middle + 1) / 2);
    selected = quick_select(a, first, middle, selected);
    merge_sort(a, selected, middle, first);
    let buffer_length = selected - first;
    let merge_end = selected + buffer_length < n ? selected + buffer_length : n;
    selected = merge_forward(a, first, selected, middle, merge_end);
    while (selected < middle) {
      shift_backward(a, selected, middle, merge_end);
      selected = merge_end - (middle - selected);
      first = selected - buffer_length;
      middle = merge_end;
      if (middle == n) break;
      merge_end = merge_end + buffer_length < n ? merge_end + buffer_length : n;
      selected = merge_forward(a, first, selected, middle, merge_end);
    }
    middle = selected;
    first = selected - buffer_length;
  }
  binary_insertion(a, first, middle);
  in_place_merge(a, first, middle, n);
}


const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array, array.length);
console.log("[" + array.join(", ") + "]");
