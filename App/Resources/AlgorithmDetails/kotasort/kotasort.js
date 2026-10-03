// MIT License
// Copyright (c) 2020 aphitorite
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.



class KotaSortExample {
  constructor(values) {
    this.a = values;
    this.buf_pos = 0;
    this.block_len = 0;
    this.buf_len = 0;
    this.tag_len = 0;
  }
  swap(left, right) {
    [this.a[left], this.a[right]] = [this.a[right], this.a[left]];
  }
  rotate(start, middle, end) {
    let left_len, offset, right_len;
    [left_len, right_len] = [(middle - start), (end - middle)];
    while ((left_len && right_len)) {
      if ((left_len <= right_len)) {
        for (offset = 0; offset < left_len; offset++) {
          this.swap((start + offset), ((start + left_len) + offset));
        }
        start += left_len;
        right_len -= left_len;
      } else {
        for (offset = 0; offset < right_len; offset++) {
          this.swap((((start + left_len) - right_len) + offset), ((start + left_len) + offset));
        }
        left_len -= right_len;
      }
    }
  }
  binary_search(start, end, value, left) {
    let middle;
    while ((start < end)) {
      middle = (start + Math.floor((end - start) / 2));
      if ((left ? (this.a[middle] >= value) : (this.a[middle] > value))) {
        end = middle;
      } else {
        start = (middle + 1);
      }
    }
    return start;
  }
  find_keys(start, end, target) {
    let count, increase, index, loc, pos, pos_end, value;
    [count, pos, pos_end, index] = [1, start, (start + 1), (start + 1)];
    while (((index < end) && (count < target))) {
      value = this.a[index];
      loc = this.binary_search(pos, pos_end, value, true);
      if (((index === loc) || (value !== this.a[loc]))) {
        this.rotate(pos, pos_end, index);
        increase = (index - pos_end);
        loc += increase;
        pos += increase;
        pos_end += increase;
        this.rotate(loc, pos_end, (pos_end + 1));
        count += 1;
        pos_end += 1;
      }
      index += 1;
    }
    this.rotate(start, pos, pos_end);
    return count;
  }
  swap_to_tags(position, tag) {
    this.swap((this.buf_pos + tag), position);
  }
  shift(start, middle, end, left) {
    if (left) {
      while ((middle > start)) {
        end -= 1;
        middle -= 1;
        this.swap(end, middle);
      }
    } else {
      while ((middle < end)) {
        this.swap(start, middle);
        start += 1;
        middle += 1;
      }
    }
  }
  multi_swap(first, second, length) {
    let offset;
    for (offset = 0; offset < length; offset++) {
      this.swap((first + offset), (second + offset));
    }
  }
  multi_swap_backward(first, second, length) {
    let offset;
    for (offset = 0; offset < length; offset++) {
      this.swap((first - offset), (second - offset));
    }
  }
  block_select(position, count) {
    let candidate, index, minimum, start, tag;
    for (tag = 0; tag < count; tag++) {
      start = (position + (tag * this.block_len));
      minimum = start;
      for (index = (tag + 1); index < count; index++) {
        candidate = (position + (index * this.block_len));
        if ((this.a[candidate] < this.a[minimum])) {
          minimum = candidate;
        }
      }
      if ((start !== minimum)) {
        this.multi_swap(start, minimum, this.block_len);
      }
      this.swap_to_tags(start, tag);
    }
  }
  block_select_backward(position, count) {
    let candidate, index, minimum, start, tag;
    for (tag = 0; tag < count; tag++) {
      start = (position - (tag * this.block_len));
      minimum = start;
      for (index = (tag + 1); index < count; index++) {
        candidate = (position - (index * this.block_len));
        if ((this.a[candidate] < this.a[minimum])) {
          minimum = candidate;
        }
      }
      if ((start !== minimum)) {
        this.multi_swap_backward(start, minimum, this.block_len);
      }
      this.swap_to_tags(start, tag);
    }
  }
  in_place_merge(start, middle, end) {
    let i, j, k;
    [i, j] = [start, middle];
    while (((i < j) && (j < end))) {
      if ((this.a[i] > this.a[j])) {
        k = this.binary_search(j, end, this.a[i], true);
        this.rotate(i, j, k);
        i += (k - j);
        j = k;
      } else {
        i += 1;
      }
    }
  }
  in_place_merge_backward(start, middle, end) {
    let i, j, k;
    [i, j] = [(middle - 1), (end - 1)];
    while (((j > i) && (i >= start))) {
      if ((this.a[i] >= this.a[j])) {
        k = this.binary_search(start, (i + 1), this.a[j], true);
        this.rotate(k, (i + 1), (j + 1));
        j -= ((i + 1) - k);
        i = (k - 1);
      } else {
        j -= 1;
      }
    }
  }
  in_place_merge2(start, middle, end) {
    let i, k, m, q;
    [i, m, k] = [start, middle, middle];
    while ((m < end)) {
      if ((this.a[(m - 1)] <= this.a[m])) {
        return;
      }
      while (((i < (m - 1)) && (this.a[i] <= this.a[m]))) {
        i += 1;
      }
      this.swap(i, k);
      i += 1;
      k += 1;
      while ((i < m)) {
        while (((i < m) && (k < end) && (this.a[m] > this.a[k]))) {
          this.swap(i, k);
          i += 1;
          k += 1;
        }
        if ((i >= m)) {
          break;
        }
        if ((k >= end)) {
          this.rotate(i, m, end);
          return;
        }
        if (((k - m) >= (m - i))) {
          this.rotate(i, m, k);
          break;
        }
        q = m;
        while (((i < m) && (q < k) && (this.a[q] <= this.a[k]))) {
          this.swap(i, q);
          i += 1;
          q += 1;
        }
        this.rotate(m, q, k);
      }
      m = k;
    }
  }
  in_place_merge_sort2(start, end) {
    let position, width;
    width = 1;
    while ((width < (end - start))) {
      position = start;
      while (((position + (2 * width)) < end)) {
        this.in_place_merge2(position, (position + width), (position + (2 * width)));
        position += (2 * width);
      }
      if (((position + width) < end)) {
        this.in_place_merge2(position, (position + width), end);
      }
      width *= 2;
    }
  }
  merge_with_buf(start, middle, end, length) {
    let i, j, k;
    [i, j, k] = [start, middle, (start - length)];
    while (((i < middle) && (j < end))) {
      if ((this.a[i] <= this.a[j])) {
        this.swap(k, i);
        i += 1;
      } else {
        this.swap(k, j);
        j += 1;
      }
      k += 1;
    }
    while ((j < end)) {
      this.swap(k, j);
      k += 1;
      j += 1;
    }
    this.shift(k, i, middle, false);
  }
  dual_merge(start, middle, end, length) {
    let i, i2, j, j2, k;
    if (((end - middle) <= length)) {
      this.merge_with_buf(start, middle, end, length);
      return;
    }
    [i, j, k] = [start, middle, (start - length)];
    while (((k < i) && (i < middle))) {
      if ((this.a[i] <= this.a[j])) {
        this.swap(k, i);
        i += 1;
      } else {
        this.swap(k, j);
        j += 1;
      }
      k += 1;
    }
    if ((k < i)) {
      this.shift((j - length), j, end, false);
    } else {
      [i2, j2] = [(middle - 1), (end - 1)];
      k = (((middle - 1) + end) - j);
      while (((i2 >= i) && (j2 >= j))) {
        if ((this.a[i2] > this.a[j2])) {
          this.swap(k, i2);
          i2 -= 1;
        } else {
          this.swap(k, j2);
          j2 -= 1;
        }
        k -= 1;
      }
      while ((j2 >= j)) {
        this.swap(k, j2);
        k -= 1;
        j2 -= 1;
      }
    }
  }
  dual_merge_backward(start, middle, end, length) {
    let first_end, i, i2, j, j2, k, second_end;
    [i, j, k] = [(middle - 1), (end - 1), ((end - 1) + length)];
    while (((k > j) && (j >= middle))) {
      if ((this.a[i] > this.a[j])) {
        this.swap(k, i);
        i -= 1;
      } else {
        this.swap(k, j);
        j -= 1;
      }
      k -= 1;
    }
    if ((j < middle)) {
      this.shift(start, (i + 1), ((i + 1) + length), true);
    } else {
      [first_end, second_end] = [(i + 1), (j + 1)];
      [i2, j2] = [start, middle];
      k = (middle - (first_end - start));
      while (((i2 < first_end) && (j2 < second_end))) {
        if ((this.a[i2] <= this.a[j2])) {
          this.swap(k, i2);
          i2 += 1;
        } else {
          this.swap(k, j2);
          j2 += 1;
        }
        k += 1;
      }
      while ((i2 < first_end)) {
        this.swap(k, i2);
        k += 1;
        i2 += 1;
      }
    }
  }
  merge_with_buf_static(start, middle, end, position, backward) {
    let i, j, k, q;
    if ((((middle - start) <= 0) || ((end - middle) <= 0))) {
      return;
    }
    if (backward) {
      [i, j, k] = [((end - middle) - 1), (middle - 1), (end - 1)];
      while (((i >= 0) && (j >= start))) {
        if ((this.a[j] >= this.a[(position + i)])) {
          q = this.binary_search(start, (j + 1), this.a[(position + i)], true);
          while ((j >= q)) {
            this.swap(k, j);
            k -= 1;
            j -= 1;
          }
        }
        this.swap(k, (position + i));
        k -= 1;
        i -= 1;
      }
      while ((i >= 0)) {
        this.swap(k, (position + i));
        k -= 1;
        i -= 1;
      }
    } else {
      [i, j, k] = [0, middle, start];
      while (((i < (middle - start)) && (j < end))) {
        if ((this.a[j] < this.a[(position + i)])) {
          q = this.binary_search(j, end, this.a[(position + i)], true);
          while ((j < q)) {
            this.swap(k, j);
            k += 1;
            j += 1;
          }
        }
        this.swap(k, (position + i));
        k += 1;
        i += 1;
      }
      while ((i < (middle - start))) {
        this.swap(k, (position + i));
        k += 1;
        i += 1;
      }
    }
  }
  block_merge(start, middle, end) {
    let count, first, i, j, left, left_available, right, right_available, selection_start, tag_count;
    if (((end - middle) <= (2 * this.buf_len))) {
      this.dual_merge(start, middle, end, this.buf_len);
      return;
    }
    [i, j] = [start, middle];
    [left_available, right_available] = [this.buf_len, 0];
    [left, right, tag_count] = [(i - this.buf_len), j, 0];
    while (((i < middle) && (left_available >= right_available))) {
      count = 0;
      while (((i < middle) && (count < this.block_len))) {
        if ((this.a[i] <= this.a[j])) {
          this.swap(left, i);
          i += 1;
        } else {
          this.swap(left, j);
          j += 1;
          right_available += 1;
          left_available -= 1;
        }
        left += 1;
        count += 1;
      }
    }
    selection_start = left;
    while (((i < middle) && (j < end))) {
      while (((i < middle) && (j < end) && (right_available > left_available))) {
        first = right;
        count = 0;
        while (((i < middle) && (j < end) && (count < this.block_len))) {
          if ((this.a[i] <= this.a[j])) {
            this.swap(right, i);
            i += 1;
            right_available -= 1;
            left_available += 1;
          } else {
            this.swap(right, j);
            j += 1;
          }
          right += 1;
          count += 1;
        }
        while (((i < middle) && (count < this.block_len))) {
          this.swap(right, i);
          right += 1;
          i += 1;
          right_available -= 1;
          left_available += 1;
          count += 1;
        }
        while (((j < end) && (count < this.block_len))) {
          this.swap(right, j);
          right += 1;
          j += 1;
          count += 1;
        }
        if ((count === this.block_len)) {
          this.swap_to_tags(first, tag_count);
          tag_count += 1;
        } else {
          this.shift(first, (first + count), end, true);
          j = (end - count);
          right = first;
        }
      }
      while (((i < middle) && (j < end) && (left_available >= right_available))) {
        first = left;
        count = 0;
        while (((i < middle) && (j < end) && (count < this.block_len))) {
          if ((this.a[i] <= this.a[j])) {
            this.swap(left, i);
            i += 1;
          } else {
            this.swap(left, j);
            j += 1;
            right_available += 1;
            left_available -= 1;
          }
          left += 1;
          count += 1;
        }
        while (((i < middle) && (count < this.block_len))) {
          this.swap(left, i);
          left += 1;
          i += 1;
          count += 1;
        }
        while (((j < end) && (count < this.block_len))) {
          this.swap(left, j);
          left += 1;
          j += 1;
          right_available += 1;
          left_available -= 1;
          count += 1;
        }
        if ((count === this.block_len)) {
          this.swap_to_tags(first, tag_count);
          tag_count += 1;
        } else {
          this.rotate(first, middle, right);
          left += (right - middle);
          left_available = 0;
        }
      }
    }
    if (((i >= middle) && (left_available === this.block_len) && (tag_count > 0))) {
      this.multi_swap(left, (right - this.block_len), this.block_len);
    } else {
      if ((i < middle)) {
        this.rotate(left, middle, right);
        left += (right - middle);
      }
      this.shift(left, (left + left_available), right, false);
    }
    if ((j < end)) {
      this.shift((j - this.buf_len), j, end, false);
    }
    this.block_select(selection_start, tag_count);
  }
  block_merge_backward(start, middle, end) {
    let count, first, i, j, left, left_available, right, right_available, selection_start, tag_count;
    [i, j] = [(middle - 1), (end - 1)];
    [left_available, right_available] = [0, this.buf_len];
    [left, right, tag_count] = [i, (j + this.buf_len), 0];
    while (((j >= middle) && (right_available >= left_available))) {
      count = 0;
      while (((j >= middle) && (count < this.block_len))) {
        if ((this.a[i] > this.a[j])) {
          this.swap(right, i);
          i -= 1;
          left_available += 1;
          right_available -= 1;
        } else {
          this.swap(right, j);
          j -= 1;
        }
        right -= 1;
        count += 1;
      }
    }
    selection_start = right;
    while (((j >= middle) && (i >= start))) {
      while (((j >= middle) && (i >= start) && (left_available > right_available))) {
        [first, count] = [left, 0];
        while (((j >= middle) && (i >= start) && (count < this.block_len))) {
          if ((this.a[i] > this.a[j])) {
            this.swap(left, i);
            i -= 1;
          } else {
            this.swap(left, j);
            j -= 1;
            right_available += 1;
            left_available -= 1;
          }
          left -= 1;
          count += 1;
        }
        while (((j >= middle) && (count < this.block_len))) {
          this.swap(left, j);
          left -= 1;
          j -= 1;
          right_available += 1;
          left_available -= 1;
          count += 1;
        }
        while (((i >= start) && (count < this.block_len))) {
          this.swap(left, i);
          left -= 1;
          i -= 1;
          count += 1;
        }
        if ((count === this.block_len)) {
          this.swap_to_tags(first, tag_count);
          tag_count += 1;
        } else {
          this.shift(start, ((first + 1) - count), (first + 1), false);
          i = ((start - 1) + count);
          left = first;
        }
      }
      while (((j >= middle) && (i >= start) && (right_available >= left_available))) {
        [first, count] = [right, 0];
        while (((j >= middle) && (i >= start) && (count < this.block_len))) {
          if ((this.a[i] > this.a[j])) {
            this.swap(right, i);
            i -= 1;
            left_available += 1;
            right_available -= 1;
          } else {
            this.swap(right, j);
            j -= 1;
          }
          right -= 1;
          count += 1;
        }
        while (((j >= middle) && (count < this.block_len))) {
          this.swap(right, j);
          right -= 1;
          j -= 1;
          count += 1;
        }
        while (((i >= start) && (count < this.block_len))) {
          this.swap(right, i);
          right -= 1;
          i -= 1;
          left_available += 1;
          right_available -= 1;
          count += 1;
        }
        if ((count === this.block_len)) {
          this.swap_to_tags(first, tag_count);
          tag_count += 1;
        } else {
          this.rotate((left + 1), middle, (first + 1));
          right -= (middle - (left + 1));
          right_available = 0;
        }
      }
    }
    if (((j < middle) && (right_available === this.block_len) && (tag_count > 0))) {
      this.multi_swap_backward(right, (left + this.block_len), this.block_len);
    } else {
      if ((j >= middle)) {
        this.rotate((left + 1), middle, (right + 1));
        right -= (middle - (left + 1));
      }
      this.shift((left + 1), ((right + 1) - right_available), (right + 1), true);
    }
    if ((i >= start)) {
      this.shift(start, (i + 1), ((i + 1) + this.buf_len), true);
    }
    this.block_select_backward(selection_start, tag_count);
  }
  kota_iterator(start, end) {
    let effective_start, length, length_of_buffer, position, width;
    width = 1;
    effective_start = (start + this.buf_len);
    length = (end - effective_start);
    while ((width < 16)) {
      position = effective_start;
      while (((position + (2 * width)) < end)) {
        this.in_place_merge2(position, (position + width), (position + (2 * width)));
        position += (2 * width);
      }
      if (((position + width) < end)) {
        this.in_place_merge2(position, (position + width), end);
      }
      width *= 2;
    }
    while ((width <= this.buf_len)) {
      length_of_buffer = width;
      position = effective_start;
      while (((position + (2 * width)) < end)) {
        this.merge_with_buf(position, (position + width), (position + (2 * width)), length_of_buffer);
        position += (2 * width);
      }
      if (((position + width) < end)) {
        this.merge_with_buf(position, (position + width), end, length_of_buffer);
      } else {
        this.shift((position - length_of_buffer), position, end, false);
      }
      width *= 2;
      position = (effective_start - length_of_buffer);
      while (((position + (2 * width)) < (end - length_of_buffer))) {
        position += (2 * width);
      }
      if (((position + width) < (end - length_of_buffer))) {
        this.dual_merge_backward(position, (position + width), (end - length_of_buffer), length_of_buffer);
      } else {
        this.shift(position, (end - length_of_buffer), end, true);
      }
      position -= (2 * width);
      while ((position >= (effective_start - length_of_buffer))) {
        this.dual_merge_backward(position, (position + width), (position + (2 * width)), length_of_buffer);
        position -= (2 * width);
      }
      width *= 2;
    }
    while ((width < length)) {
      position = effective_start;
      while (((position + (2 * width)) < end)) {
        this.block_merge(position, (position + width), (position + (2 * width)));
        position += (2 * width);
      }
      if (((position + width) < end)) {
        this.block_merge(position, (position + width), end);
      } else {
        this.shift((position - this.buf_len), position, end, false);
      }
      width *= 2;
      if ((width >= length)) {
        return true;
      }
      position = start;
      while (((position + (2 * width)) < (end - this.buf_len))) {
        position += (2 * width);
      }
      if (((position + width) < (end - this.buf_len))) {
        this.block_merge_backward(position, (position + width), (end - this.buf_len));
      } else {
        this.shift(position, (end - this.buf_len), end, true);
      }
      position -= (2 * width);
      while ((position >= start)) {
        this.block_merge_backward(position, (position + width), (position + (2 * width)));
        position -= (2 * width);
      }
      width *= 2;
    }
    return false;
  }
  sort() {
    let backward, buffer_end, buffer_start, buffer_target, effective_start, end_start, length, middle, position, tag_target;
    length = this.a.length;
    if ((length <= 128)) {
      this.in_place_merge_sort2(0, length);
      return;
    }
    this.buf_pos = 0;
    this.block_len = 1;
    while (((this.block_len * this.block_len) < length)) {
      this.block_len *= 2;
    }
    buffer_target = (2 * this.block_len);
    this.buf_len = this.find_keys(0, length, buffer_target);
    if ((this.buf_len < buffer_target)) {
      if ((this.buf_len > 1)) {
        this.in_place_merge_sort2(0, length);
      }
      return;
    }
    tag_target = Math.floor(length / this.block_len);
    this.tag_len = this.find_keys(this.buf_len, length, tag_target);
    if ((this.tag_len < tag_target)) {
      this.in_place_merge_sort2(0, length);
      return;
    }
    buffer_start = this.tag_len;
    effective_start = (buffer_start + this.buf_len);
    buffer_end = this.buf_len;
    this.shift(0, buffer_end, effective_start, false);
    backward = this.kota_iterator(buffer_start, length);
    if (backward) {
      end_start = (length - this.buf_len);
      this.multi_swap(0, end_start, this.tag_len);
      this.merge_with_buf_static(0, buffer_start, end_start, end_start, false);
      this.in_place_merge_sort2(end_start, length);
      middle = (end_start + this.block_len);
      position = this.binary_search(0, end_start, this.a[(middle - 1)], true);
      this.rotate(position, end_start, middle);
      position += this.block_len;
      this.multi_swap_backward((length - 1), (position - 1), this.block_len);
      this.merge_with_buf_static(0, (position - this.block_len), position, middle, true);
      this.in_place_merge_sort2(middle, length);
      this.in_place_merge_backward(position, middle, length);
      this.in_place_merge(0, position, length);
    } else {
      this.merge_with_buf_static(buffer_end, effective_start, length, 0, false);
      this.in_place_merge_sort2(0, buffer_end);
      middle = this.block_len;
      position = this.binary_search(buffer_end, length, this.a[middle], true);
      this.rotate(middle, buffer_end, position);
      position -= this.block_len;
      this.multi_swap(0, position, this.block_len);
      this.merge_with_buf_static(position, (position + this.block_len), length, 0, false);
      this.in_place_merge_sort2(0, middle);
      this.in_place_merge(0, middle, position);
      this.in_place_merge2((length - (2 * this.block_len)), (length - this.block_len), length);
      this.in_place_merge(0, (length - (2 * this.block_len)), length);
    }
  }
}
function sort(values) {
  new KotaSortExample(values).sort();
}
const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
