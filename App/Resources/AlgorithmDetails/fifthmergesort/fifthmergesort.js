function binary_insertion(s, first, end) {
  for (let i = first + 1; i < end; ++i) {
    let value = s.a[i], low = first, high = i;
    while (low < high) {
      let middle = low + Math.trunc((high - low) / 2);
      if (s.a[middle] > value) high = middle;
      else low = middle + 1;
    }
    for (let j = i; j > low; --j) s.a[j] = s.a[j - 1];
    s.a[low] = value;
  }
}

function source(s, index, offset, from_buffer) {
  return from_buffer ? s.buffer[index - offset] : s.a[index];
}

function merge(s, offset, first, middle, end,
                  from_buffer) {
  let left = first, right = middle;
  let destination = from_buffer ? first : first - offset;
  while (left < middle && right < end) {
    let value;
    if (source(s, left, offset, from_buffer) <=
        source(s, right, offset, from_buffer))
      value = source(s, left++, offset, from_buffer);
    else value = source(s, right++, offset, from_buffer);
    if (from_buffer) s.a[destination++] = value;
    else s.buffer[destination++] = value;
  }
  while (left < middle) {
    let value = source(s, left++, offset, from_buffer);
    if (from_buffer) s.a[destination++] = value;
    else s.buffer[destination++] = value;
  }
  while (right < end) {
    let value = source(s, right++, offset, from_buffer);
    if (from_buffer) s.a[destination++] = value;
    else s.buffer[destination++] = value;
  }
}

function ping_pong(s, first, end) {
  let i = first;
  while (i + 8 < end) {
    binary_insertion(s, i, i + 8);
    i += 8;
  }
  if (end - i > 1) binary_insertion(s, i, end);

  let length = end - first, from_buffer = 0;
  for (let gap = 8; gap < length; gap *= 2) {
    let full = gap * 2;
    i = first;
    while (i + full < end) {
      merge(s, first, i, i + gap, i + full, from_buffer);
      i += full;
    }
    if (i + gap < end) merge(s, first, i, i + gap, end, from_buffer);
    else {
      for (let j = i; j < end; ++j) {
        if (from_buffer) s.a[j] = s.buffer[j - first];
        else s.buffer[j - first] = s.a[j];
      }
    }
    from_buffer = !from_buffer;
  }
  if (from_buffer) {
    for (let j = 0; j < length; ++j) s.a[first + j] = s.buffer[j];
  }
}

function merge_forward(s, destination, first, middle, end) {
  let left = first, right = middle;
  while (left < middle && right < end) {
    if (s.a[left] <= s.a[right]) s.a[destination++] = s.a[left++];
    else s.a[destination++] = s.a[right++];
  }
  while (left < middle) s.a[destination++] = s.a[left++];
  while (right < end) s.a[destination++] = s.a[right++];
}


function merge_backward(s, destination, middle, end) {
  let left = middle - 1, right = end - 1;
  while (destination > right && right >= middle && left >= 0) {
    if (s.a[left] > s.a[right]) s.a[destination--] = s.a[left--];
    else s.a[destination--] = s.a[right--];
  }
  if (left < 0) {
    while (right >= middle) s.a[destination--] = s.a[right--];
  } else if (right == left) {
    while (right >= 0) s.a[destination--] = s.a[right--];
  } else if (right < middle) {
    while (left >= 0) s.a[destination--] = s.a[left--];
  }
  let result = {left: left + 1, right: right + 1};
  return result;
}

function merge_main_prefix(s, destination, left_end,
                              middle, end) {
  let left = 0, right = middle;
  while (left < left_end && right < end) {
    if (s.a[left] <= s.a[right]) s.a[destination++] = s.a[left++];
    else s.a[destination++] = s.a[right++];
  }
  while (left < left_end) s.a[destination++] = s.a[left++];
}

function merge_external(s, destination, middle, end) {
  let left = 0, right = middle;
  while (left < s.buffer_length && right < end) {
    if (s.buffer[left] <= s.a[right])
      s.a[destination++] = s.buffer[left++];
    else s.a[destination++] = s.a[right++];
  }
  while (left < s.buffer_length) s.a[destination++] = s.buffer[left++];
}

function sort(a, n) {
  if (n <= 1) return;
  let fifth = Math.trunc(n / 5), buffer_length = n - 4 * fifth;
  let buffer = new Array(buffer_length).fill(0);
  let s = {a, buffer, buffer_length};
  ping_pong(s, 0, buffer_length);
  let first = buffer_length;
  for (let i = 0; i < 4; ++i) {
    ping_pong(s, first, first + fifth);
    first += fifth;
  }
  for (let i = 0; i < buffer_length; ++i) buffer[i] = a[i];

  let two_fifths = 2 * fifth;
  first = buffer_length;
  for (let i = 0; i < 2; ++i) {
    merge_forward(s, first - buffer_length, first, first + fifth,
                  first + two_fifths);
    first += two_fifths;
  }
  let remainder = merge_backward(s, n - 1, two_fifths, 2 * two_fifths);
  if (remainder.right > 0)
    merge_main_prefix(s, buffer_length, remainder.left, two_fifths, n);
  merge_external(s, 0, buffer_length, n);
}


let array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array, array.length);
console.log("[" + array.join(", ") + "]");
