/* MIT License
 * Copyright (c) 2021 The Holy Grail Sort Project, implemented by aphitorite
 * Copyright (c) 2020-2021 aphitorite
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
 * BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

function exchange(s, i, j) {
  let value = s.a[i];
  s.a[i] = s.a[j];
  s.a[j] = value;
}

function binary_insertion(s, first, end) {
  for (let i = first + 1; i < end; ++i) {
    let value = s.a[i], low = first, high = i;
    while (low < high) {
      let middle = low + Math.trunc((high - low) / 2);
      if (s.a[middle] <= value) low = middle + 1;
      else high = middle;
    }
    for (let j = i; j > low; --j) s.a[j] = s.a[j - 1];
    if (low != i) s.a[low] = value;
  }
}

function shift_forward(s, destination, source, end) {
  while (source < end) s.a[destination++] = s.a[source++];
}

function shift_backward(s, first, source_end, destination_end) {
  while (source_end > first) s.a[--destination_end] = s.a[--source_end];
}

function multi_swap(s, first, second, length) {
  for (let i = 0; i < length; ++i) exchange(s, first + i, second + i);
}

function merge_forward(s, first, middle, end, output) {
  let left = first, right = middle;
  while (left < middle && right < end) {
    if (s.a[left] <= s.a[right]) s.a[output++] = s.a[left++];
    else s.a[output++] = s.a[right++];
  }
  if (left > output) shift_forward(s, output, left, middle);
  shift_forward(s, output, right, end);
}

function merge_backward(s, first, middle, end, output) {
  let left = middle - 1, right = end - 1;
  while (right >= middle && left >= first) {
    --output;
    if (s.a[right] >= s.a[left]) s.a[output] = s.a[right--];
    else s.a[output] = s.a[left--];
  }
  if (output > right) shift_backward(s, middle, right + 1, output);
  shift_backward(s, first, left + 1, output);
}

function smart_merge_backward(s, first, middle,
                                end, output, reversed) {
  let left = middle - 1, right = end - 1;
  while (left >= first && right >= middle) {
    let take_left = reversed ? s.a[left] >= s.a[right] : s.a[left] > s.a[right];
    --output;
    if (take_left) s.a[output] = s.a[left--];
    else s.a[output] = s.a[right--];
  }
  return left + 1;
}

function block_selection(s, first, end, block,
                            tag_start, tag_count) {
  let available = tag_count + 1;
  if (available > s.tag_count - tag_start) available = s.tag_count - tag_start;
  for (let i = 0; i < available; ++i)
    s.tags[tag_start + i] = i + (i <= Math.trunc(tag_count / 2) ? 0 : s.tag_count);
  let vacant = first;
  let current = first;
  while (current < end - block) {
    let minimum = vacant == current ? current + block : current;
    for (let candidate = minimum + block; candidate < end; candidate += block) {
      if (candidate != vacant &&
          (s.a[candidate] < s.a[minimum] ||
           (s.a[candidate] == s.a[minimum] &&
            s.tags[tag_start + Math.trunc((candidate - first) / block)] <
            s.tags[tag_start + Math.trunc((minimum - first) / block)])))
        minimum = candidate;
    }
    if (minimum > current) {
      if (vacant == current) {
        for (let i = 0; i < block; ++i) s.a[current + i] = s.a[minimum + i];
        s.tags[tag_start + Math.trunc((current - first) / block)] =
          s.tags[tag_start + Math.trunc((minimum - first) / block)];
        vacant = minimum;
      } else {
        multi_swap(s, current, minimum, block);
        let current_tag = tag_start + Math.trunc((current - first) / block);
        let minimum_tag = tag_start + Math.trunc((minimum - first) / block);
        let value = s.tags[current_tag];
        s.tags[current_tag] = s.tags[minimum_tag];
        s.tags[minimum_tag] = value;
      }
    }
    current += block;
  }
}

function merge_blocks_backward(s, first, end,
                                  first_tag, past_last_tag, block) {
  let tag = past_last_tag - 1;
  let frontier = end, block_start = frontier - block;
  let reversed = s.tags[tag] < s.tag_count;
  for (;;) {
    do { --tag; block_start -= block; }
    while (tag >= first_tag && ((s.tags[tag] < s.tag_count) == reversed));
    if (tag < first_tag) {
      shift_backward(s, first, frontier, frontier + block);
      break;
    }
    frontier = smart_merge_backward(s, block_start, block_start + block,
                                    frontier, frontier + block, reversed);
    reversed = !reversed;
  }
}

function sort(a, n) {
  if (n <= 1) return;
  let s = {a, prefix: null, tags: null, n, tag_count: 0};
  if (n <= 16) { binary_insertion(s, 0, n); return; }
  let block = 1;
  while (block * block < n) block *= 2;
  let remainder = n % block;
  let first = block + remainder, end = n;
  let work_length = end - first, run = 1;
  s.tag_count = Math.trunc((n - 1) / block) + 1;
  s.prefix = new Array(first).fill(0);
  s.tags = new Array(s.tag_count).fill(0);
  binary_insertion(s, 0, first);
  for (let i = 0; i < first; ++i) s.prefix[i] = a[i];

  while (run < block) {
    let distance = run < 2 ? 2 : run;
    let index = first;
    while (index + 2 * run < end) {
      merge_forward(s, index, index + run, index + 2 * run, index - distance);
      index += 2 * run;
    }
    if (index + run < end) merge_forward(s, index, index + run, end, index - distance);
    else shift_forward(s, index - distance, index, end);
    first -= distance;
    end -= distance;
    run *= 2;
  }

  let fragment = work_length % (2 * run);
  let index = end - fragment;
  if (index + run < end) merge_backward(s, index, index + run, end, end + run);
  else shift_backward(s, index, end, end + run);
  index -= 2 * run;
  while (index >= first) {
    merge_backward(s, index, index + run, index + 2 * run, index + 3 * run);
    index -= 2 * run;
  }
  first += run; end += run; run *= 2;

  let tag_count = 4;
  while (run < work_length) {
    index = first;
    let tag_index = 0;
    while (index + 2 * run < end) {
      block_selection(s, index - block, index + 2 * run, block, tag_index, tag_count);
      index += 2 * run;
      tag_index += tag_count;
    }
    let has_fragment = index + run < end;
    fragment = Math.trunc((end - index) / block);
    if (has_fragment)
      block_selection(s, index - block, end, block, tag_index, tag_count);
    first -= block; end -= block; index -= block;
    if (has_fragment)
      merge_blocks_backward(s, index, end, tag_index, tag_index + fragment, block);
    index -= 2 * run;
    tag_index -= tag_count;
    while (index >= first) {
      merge_blocks_backward(s, index, index + 2 * run, tag_index,
                            tag_index + tag_count, block);
      index -= 2 * run;
      tag_index -= tag_count;
    }
    first += block; end += block; run *= 2; tag_count *= 2;
  }

  let left = 0, right = first, output = 0;
  while (left < first && right < end) {
    if (s.prefix[left] <= a[right]) a[output++] = s.prefix[left++];
    else a[output++] = a[right++];
  }
  while (left < first) a[output++] = s.prefix[left++];
}


let array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array, array.length);
console.log("[" + array.join(", ") + "]");
