using System;

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

class TimSort {
  class Tim {
    public int[] a, runBase = new int[0], length = new int[0], temp = new int[0];
    public int count, stack_size = 0, temp_capacity = 0, min_gallop = 7;
    public Tim(int[] a, int count) { this.a = a; this.count = count; }
  }
static int minimum(int a, int b) { return a < b ? a : b; }
static int maximum(int a, int b) { return a > b ? a : b; }

static void ensure_capacity(Tim s, int needed) {
  if (s.temp_capacity >= needed) return;
  int capacity = maximum(1, s.temp_capacity);
  while (capacity < needed) capacity *= 2;
  capacity = minimum(capacity, maximum(1, s.count / 2));
  s.temp = new int[capacity];
  s.temp_capacity = capacity;
}

static int min_run_length(int value) {
  int remainder = 0;
  while (value >= 32) {
    remainder |= value & 1;
    value >>= 1;
  }
  return value + remainder;
}

static int count_run(Tim s, int first, int end) {
  if (first + 1 >= end) return 1;
  int cursor = first + 2;
  if (s.a[first + 1] < s.a[first]) {
    while (cursor < end && s.a[cursor] < s.a[cursor - 1]) ++cursor;
    for (int left = first, right = cursor - 1; left < right; ++left, --right) {
      int value = s.a[left];
      s.a[left] = s.a[right];
      s.a[right] = value;
    }
  } else {
    while (cursor < end && s.a[cursor] >= s.a[cursor - 1]) ++cursor;
  }
  return cursor - first;
}

static void binary_insertion(Tim s, int first, int end, int sorted_end) {
  int cursor = maximum(first + 1, sorted_end);
  while (cursor < end) {
    int pivot = s.a[cursor], low = first, high = cursor;
    while (low < high) {
      int middle = low + (high - low) / 2;
      if (s.a[middle] <= pivot) low = middle + 1;
      else high = middle;
    }
    for (int shift = cursor; shift > low; --shift) s.a[shift] = s.a[shift - 1];
    s.a[low] = pivot;
    ++cursor;
  }
}

static int gallop(Tim s, int first, int end, int key, int upper,
                  int from_end, int use_temp) {
  if (first >= end) return first;
  int low, high;
  if (from_end != 0) {
    high = end;
    low = end - 1;
    int step = 1;
    while (!((use_temp != 0 ? s.temp[low] : s.a[low]) < key ||
             (upper != 0 && (use_temp != 0 ? s.temp[low] : s.a[low]) == key))) {
      high = low;
      if (low == first) break;
      step = minimum(end - first, step * 2);
      low = maximum(first, end - step);
    }
  } else {
    low = first;
    high = first + 1;
    while (((use_temp != 0 ? s.temp[high - 1] : s.a[high - 1]) < key ||
            (upper != 0 && (use_temp != 0 ? s.temp[high - 1] : s.a[high - 1]) == key)) &&
           high < end) {
      low = high;
      high = minimum(end, first + (high - first) * 2);
    }
  }
  while (low < high) {
    int middle = low + (high - low) / 2;
    int value = use_temp != 0 ? s.temp[middle] : s.a[middle];
    if (value < key || (upper != 0 && value == key)) low = middle + 1;
    else high = middle;
  }
  return low;
}

static void merge_low(Tim s, int first, int left_length, int right_start,
                      int right_length) {
  ensure_capacity(s, left_length);
  for (int i = 0; i < left_length; ++i) s.temp[i] = s.a[first + i];
  int left = 0, right = right_start, destination = first;
  int right_end = right_start + right_length;
  int left_wins = 0, right_wins = 0, galloped = 0;
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
    int left_stop = gallop(s, left, left_length, s.a[right], 1, 0, 1);
    while (left < left_stop) s.a[destination++] = s.temp[left++];
    if (left == left_length) break;
    s.a[destination++] = s.a[right++];
    if (right == right_end) break;
    int right_stop = gallop(s, right, right_end, s.temp[left], 0, 0, 0);
    while (right < right_stop) s.a[destination++] = s.a[right++];
    if (right == right_end) break;
    s.a[destination++] = s.temp[left++];
    s.min_gallop = maximum(1, s.min_gallop - 1);
    left_wins = right_wins = 0;
  }
  while (left < left_length) s.a[destination++] = s.temp[left++];
  if (galloped != 0) s.min_gallop += 2;
}

static void merge_high(Tim s, int first, int left_length, int right_start,
                       int right_length) {
  ensure_capacity(s, right_length);
  for (int i = 0; i < right_length; ++i) s.temp[i] = s.a[right_start + i];
  int left = right_start - 1, right = right_length - 1;
  int destination = right_start + right_length - 1;
  int left_wins = 0, right_wins = 0, galloped = 0;
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
    int left_stop = gallop(s, first, left + 1, s.temp[right], 1, 1, 0);
    while (left >= left_stop) s.a[destination--] = s.a[left--];
    if (left < first) break;
    s.a[destination--] = s.temp[right--];
    if (right < 0) break;
    int right_stop = gallop(s, 0, right + 1, s.a[left], 0, 1, 1);
    while (right >= right_stop) s.a[destination--] = s.temp[right--];
    if (right < 0) break;
    s.a[destination--] = s.a[left--];
    s.min_gallop = maximum(1, s.min_gallop - 1);
    left_wins = right_wins = 0;
  }
  while (right >= 0) s.a[destination--] = s.temp[right--];
  if (galloped != 0) s.min_gallop += 2;
}

static void merge_at(Tim s, int index) {
  int left_start = s.runBase[index], left_length = s.length[index];
  int right_start = s.runBase[index + 1], right_length = s.length[index + 1];
  s.length[index] = left_length + right_length;
  if (index == s.stack_size - 3) {
    s.runBase[index + 1] = s.runBase[index + 2];
    s.length[index + 1] = s.length[index + 2];
  }
  --s.stack_size;
  int skipped = gallop(s, left_start, right_start, s.a[right_start], 1, 0, 0);
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

static void collapse(Tim s) {
  while (s.stack_size > 1) {
    int index = s.stack_size - 2;
    if ((index >= 1 && s.length[index - 1] <= s.length[index] + s.length[index + 1]) ||
        (index >= 2 && s.length[index - 2] <= s.length[index] + s.length[index - 1])) {
      if (s.length[index - 1] < s.length[index + 1]) --index;
    } else if (s.length[index] > s.length[index + 1]) break;
    merge_at(s, index);
  }
}

static void force_collapse(Tim s) {
  while (s.stack_size > 1) {
    int index = s.stack_size - 2;
    if (index > 0 && s.length[index - 1] < s.length[index + 1]) --index;
    merge_at(s, index);
  }
}

static void sort(int[] a, int n) {
  if (n <= 1) return;
  int stack_capacity = n < 120 ? 5 : n < 1542 ? 10 : n < 119151 ? 19 : 40;
  Tim s = new Tim(a, n);
  s.runBase = new int[stack_capacity];
  s.length = new int[stack_capacity];
  if (n < 32) {
    int run = count_run(s, 0, n);
    binary_insertion(s, 0, n, run);
  } else {
    int min_run = min_run_length(n), cursor = 0;
    while (cursor < n) {
      int run = count_run(s, cursor, n);
      if (run < min_run) {
        int forced = minimum(min_run, n - cursor);
        binary_insertion(s, cursor, cursor + forced, cursor + run);
        run = forced;
      }
      s.runBase[s.stack_size] = cursor;
      s.length[s.stack_size] = run;
      ++s.stack_size;
      collapse(s);
      cursor += run;
    }
    force_collapse(s);
  }
}

  static void Main() {
    int[] a = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(a, a.Length);
    Console.WriteLine("[" + string.Join(", ", a) + "]");
  }
}
