/* Copyright (C) 2008 The Android Open Source Project
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

function minimum(a, b) { return a < b ? a : b; }
function maximum(a, b) { return a > b ? a : b; }

function ensure_capacity(s, needed) {
  if (s.temp_capacity >= needed) return;
  let capacity = maximum(1, s.temp_capacity);
  while (capacity < needed) capacity *= 2;
  capacity = minimum(capacity, maximum(1, Math.trunc(s.count / 2)));
  s.temp = new Array(capacity).fill(0);
  s.temp_capacity = capacity;
}

function min_run_length(value) {
  let remainder = 0;
  while (value >= 32) {
    remainder |= value & 1;
    value >>= 1;
  }
  return value + remainder;
}

function count_run(s, first, end) {
  if (first + 1 >= end) return 1;
  let cursor = first + 2;
  if (s.a[first + 1] < s.a[first]) {
    while (cursor < end && s.a[cursor] < s.a[cursor - 1]) ++cursor;
    for (let left = first, right = cursor - 1; left < right; ++left, --right) {
      let value = s.a[left];
      s.a[left] = s.a[right];
      s.a[right] = value;
    }
  } else {
    while (cursor < end && s.a[cursor] >= s.a[cursor - 1]) ++cursor;
  }
  return cursor - first;
}

function binary_insertion(s, first, end, sorted_end) {
  let cursor = maximum(first + 1, sorted_end);
  while (cursor < end) {
    let pivot = s.a[cursor], low = first, high = cursor;
    while (low < high) {
      let middle = low + Math.trunc((high - low) / 2);
      if (s.a[middle] <= pivot) low = middle + 1;
      else high = middle;
    }
    for (let shift = cursor; shift > low; --shift) s.a[shift] = s.a[shift - 1];
    s.a[low] = pivot;
    ++cursor;
  }
}

function gallop(s, first, end, key, upper,
                  from_end, use_temp) {
  if (first >= end) return first;
  let low, high;
  if (from_end) {
    high = end;
    low = end - 1;
    let step = 1;
    while (!((use_temp ? s.temp[low] : s.a[low]) < key ||
             (upper && (use_temp ? s.temp[low] : s.a[low]) == key))) {
      high = low;
      if (low == first) break;
      step = minimum(end - first, step * 2);
      low = maximum(first, end - step);
    }
  } else {
    low = first;
    high = first + 1;
    while (((use_temp ? s.temp[high - 1] : s.a[high - 1]) < key ||
            (upper && (use_temp ? s.temp[high - 1] : s.a[high - 1]) == key)) &&
           high < end) {
      low = high;
      high = minimum(end, first + (high - first) * 2);
    }
  }
  while (low < high) {
    let middle = low + Math.trunc((high - low) / 2);
    let value = use_temp ? s.temp[middle] : s.a[middle];
    if (value < key || (upper && value == key)) low = middle + 1;
    else high = middle;
  }
  return low;
}

function merge_low(s, first, left_length, right_start,
                      right_length) {
  ensure_capacity(s, left_length);
  for (let i = 0; i < left_length; ++i) s.temp[i] = s.a[first + i];
  let left = 0, right = right_start, destination = first;
  let right_end = right_start + right_length;
  let left_wins = 0, right_wins = 0, galloped = 0;
  while (left < left_length && right < right_end) {
    if (s.a[right] < s.temp[left]) {
      s.a[destination] = s.a[right++];
      ++right_wins; left_wins = 0;
    } else {
      s.a[destination] = s.temp[left++];
      ++left_wins; right_wins = 0;
    }
    ++destination;
    if (left >= left_length || right >= right_end) break;
    if (maximum(left_wins, right_wins) < s.min_gallop) continue;
    galloped = 1;
    let left_stop = gallop(s, left, left_length, s.a[right], 1, 0, 1);
    while (left < left_stop) s.a[destination++] = s.temp[left++];
    if (left == left_length) break;
    s.a[destination++] = s.a[right++];
    if (right == right_end) break;
    let right_stop = gallop(s, right, right_end, s.temp[left], 0, 0, 0);
    while (right < right_stop) s.a[destination++] = s.a[right++];
    if (right == right_end) break;
    s.a[destination++] = s.temp[left++];
    s.min_gallop = maximum(1, s.min_gallop - 1);
    left_wins = right_wins = 0;
  }
  while (left < left_length) s.a[destination++] = s.temp[left++];
  if (galloped) s.min_gallop += 2;
}

function merge_high(s, first, left_length, right_start,
                       right_length) {
  ensure_capacity(s, right_length);
  for (let i = 0; i < right_length; ++i) s.temp[i] = s.a[right_start + i];
  let left = right_start - 1, right = right_length - 1;
  let destination = right_start + right_length - 1;
  let left_wins = 0, right_wins = 0, galloped = 0;
  while (left >= first && right >= 0) {
    if (s.temp[right] < s.a[left]) {
      s.a[destination] = s.a[left--];
      ++left_wins; right_wins = 0;
    } else {
      s.a[destination] = s.temp[right--];
      ++right_wins; left_wins = 0;
    }
    --destination;
    if (left < first || right < 0) break;
    if (maximum(left_wins, right_wins) < s.min_gallop) continue;
    galloped = 1;
    let left_stop = gallop(s, first, left + 1, s.temp[right], 1, 1, 0);
    while (left >= left_stop) s.a[destination--] = s.a[left--];
    if (left < first) break;
    s.a[destination--] = s.temp[right--];
    if (right < 0) break;
    let right_stop = gallop(s, 0, right + 1, s.a[left], 0, 1, 1);
    while (right >= right_stop) s.a[destination--] = s.temp[right--];
    if (right < 0) break;
    s.a[destination--] = s.a[left--];
    s.min_gallop = maximum(1, s.min_gallop - 1);
    left_wins = right_wins = 0;
  }
  while (right >= 0) s.a[destination--] = s.temp[right--];
  if (galloped) s.min_gallop += 2;
}

function merge_at(s, index) {
  let left_start = s.base[index], left_length = s.length[index];
  let right_start = s.base[index + 1], right_length = s.length[index + 1];
  s.length[index] = left_length + right_length;
  if (index == s.stack_size - 3) {
    s.base[index + 1] = s.base[index + 2];
    s.length[index + 1] = s.length[index + 2];
  }
  --s.stack_size;
  let skipped = gallop(s, left_start, right_start, s.a[right_start], 1, 0, 0);
  left_length -= skipped - left_start;
  left_start = skipped;
  if (left_length == 0) return;
  right_length = gallop(s, right_start, right_start + right_length,
                        s.a[right_start - 1], 0, 0, 0) - right_start;
  if (right_length == 0) return;
  if (left_length <= right_length)
    merge_low(s, left_start, left_length, right_start, right_length);
  else
    merge_high(s, left_start, left_length, right_start, right_length);
}

function collapse(s) {
  while (s.stack_size > 1) {
    let index = s.stack_size - 2;
    if ((index >= 1 && s.length[index - 1] <= s.length[index] + s.length[index + 1]) ||
        (index >= 2 && s.length[index - 2] <= s.length[index] + s.length[index - 1])) {
      if (s.length[index - 1] < s.length[index + 1]) --index;
    } else if (s.length[index] > s.length[index + 1]) break;
    merge_at(s, index);
  }
}

function force_collapse(s) {
  while (s.stack_size > 1) {
    let index = s.stack_size - 2;
    if (index > 0 && s.length[index - 1] < s.length[index + 1]) --index;
    merge_at(s, index);
  }
}

function sort(a, n) {
  if (n <= 1) return;
  let stack_capacity = n < 120 ? 5 : n < 1542 ? 10 : n < 119151 ? 19 : 40;
  let s = {a, count:n, base:[], length:[], stack_size:0, temp:[], temp_capacity:0, min_gallop:7};
  s.base = new Array(stack_capacity).fill(0);
  s.length = new Array(stack_capacity).fill(0);
  if (n < 32) {
    let run = count_run(s, 0, n);
    binary_insertion(s, 0, n, run);
  } else {
    let min_run = min_run_length(n), cursor = 0;
    while (cursor < n) {
      let run = count_run(s, cursor, n);
      if (run < min_run) {
        let forced = minimum(min_run, n - cursor);
        binary_insertion(s, cursor, cursor + forced, cursor + run);
        run = forced;
      }
      s.base[s.stack_size] = cursor;
      s.length[s.stack_size] = run;
      ++s.stack_size;
      collapse(s);
      cursor += run;
    }
    force_collapse(s);
  }
}


let array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array, array.length);
console.log("[" + array.join(", ") + "]");
