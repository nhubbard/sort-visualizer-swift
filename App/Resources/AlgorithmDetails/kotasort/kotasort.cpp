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


#include <algorithm>
#include <cmath>
#include <iostream>
#include <tuple>
#include <vector>

class KotaSortExample {
public:
  int* a;
  int n;
  int buf_pos, block_len, buf_len, tag_len;
  KotaSortExample(int* values, int count) {
    n = count;
    a = values;
    buf_pos = 0;
    block_len = 0;
    buf_len = 0;
    tag_len = 0;
  }
  void swap(int left, int right) {
    std::tie(a[left], a[right]) = std::make_tuple(a[right], a[left]);
  }
  void rotate(int start, int middle, int end) {
    int left_len, offset, right_len;
    std::tie(left_len, right_len) = std::make_tuple((middle - start), (end - middle));
    while ((left_len && right_len)) {
      if ((left_len <= right_len)) {
        for (offset = 0; offset < left_len; offset++) {
          swap((start + offset), ((start + left_len) + offset));
        }
        start += left_len;
        right_len -= left_len;
      } else {
        for (offset = 0; offset < right_len; offset++) {
          swap((((start + left_len) - right_len) + offset), ((start + left_len) + offset));
        }
        left_len -= right_len;
      }
    }
  }
  int binary_search(int start, int end, int value, int left) {
    int middle;
    while ((start < end)) {
      middle = (start + floor((end - start) / 2));
      if ((left ? (a[middle] >= value) : (a[middle] > value))) {
        end = middle;
      } else {
        start = (middle + 1);
      }
    }
    return start;
  }
  int find_keys(int start, int end, int target) {
    int count, increase, index, loc, pos, pos_end, value;
    std::tie(count, pos, pos_end, index) = std::make_tuple(1, start, (start + 1), (start + 1));
    while (((index < end) && (count < target))) {
      value = a[index];
      loc = binary_search(pos, pos_end, value, true);
      if (((index == loc) || (value != a[loc]))) {
        rotate(pos, pos_end, index);
        increase = (index - pos_end);
        loc += increase;
        pos += increase;
        pos_end += increase;
        rotate(loc, pos_end, (pos_end + 1));
        count += 1;
        pos_end += 1;
      }
      index += 1;
    }
    rotate(start, pos, pos_end);
    return count;
  }
  void swap_to_tags(int position, int tag) {
    swap((buf_pos + tag), position);
  }
  void shift(int start, int middle, int end, int left) {
    if (left) {
      while ((middle > start)) {
        end -= 1;
        middle -= 1;
        swap(end, middle);
      }
    } else {
      while ((middle < end)) {
        swap(start, middle);
        start += 1;
        middle += 1;
      }
    }
  }
  void multi_swap(int first, int second, int length) {
    int offset;
    for (offset = 0; offset < length; offset++) {
      swap((first + offset), (second + offset));
    }
  }
  void multi_swap_backward(int first, int second, int length) {
    int offset;
    for (offset = 0; offset < length; offset++) {
      swap((first - offset), (second - offset));
    }
  }
  void block_select(int position, int count) {
    int candidate, index, minimum, start, tag;
    for (tag = 0; tag < count; tag++) {
      start = (position + (tag * block_len));
      minimum = start;
      for (index = (tag + 1); index < count; index++) {
        candidate = (position + (index * block_len));
        if ((a[candidate] < a[minimum])) {
          minimum = candidate;
        }
      }
      if ((start != minimum)) {
        multi_swap(start, minimum, block_len);
      }
      swap_to_tags(start, tag);
    }
  }
  void block_select_backward(int position, int count) {
    int candidate, index, minimum, start, tag;
    for (tag = 0; tag < count; tag++) {
      start = (position - (tag * block_len));
      minimum = start;
      for (index = (tag + 1); index < count; index++) {
        candidate = (position - (index * block_len));
        if ((a[candidate] < a[minimum])) {
          minimum = candidate;
        }
      }
      if ((start != minimum)) {
        multi_swap_backward(start, minimum, block_len);
      }
      swap_to_tags(start, tag);
    }
  }
  void in_place_merge(int start, int middle, int end) {
    int i, j, k;
    std::tie(i, j) = std::make_tuple(start, middle);
    while (((i < j) && (j < end))) {
      if ((a[i] > a[j])) {
        k = binary_search(j, end, a[i], true);
        rotate(i, j, k);
        i += (k - j);
        j = k;
      } else {
        i += 1;
      }
    }
  }
  void in_place_merge_backward(int start, int middle, int end) {
    int i, j, k;
    std::tie(i, j) = std::make_tuple((middle - 1), (end - 1));
    while (((j > i) && (i >= start))) {
      if ((a[i] >= a[j])) {
        k = binary_search(start, (i + 1), a[j], true);
        rotate(k, (i + 1), (j + 1));
        j -= ((i + 1) - k);
        i = (k - 1);
      } else {
        j -= 1;
      }
    }
  }
  void in_place_merge2(int start, int middle, int end) {
    int i, k, m, q;
    std::tie(i, m, k) = std::make_tuple(start, middle, middle);
    while ((m < end)) {
      if ((a[(m - 1)] <= a[m])) {
        return;
      }
      while (((i < (m - 1)) && (a[i] <= a[m]))) {
        i += 1;
      }
      swap(i, k);
      i += 1;
      k += 1;
      while ((i < m)) {
        while (((i < m) && (k < end) && (a[m] > a[k]))) {
          swap(i, k);
          i += 1;
          k += 1;
        }
        if ((i >= m)) {
          break;
        }
        if ((k >= end)) {
          rotate(i, m, end);
          return;
        }
        if (((k - m) >= (m - i))) {
          rotate(i, m, k);
          break;
        }
        q = m;
        while (((i < m) && (q < k) && (a[q] <= a[k]))) {
          swap(i, q);
          i += 1;
          q += 1;
        }
        rotate(m, q, k);
      }
      m = k;
    }
  }
  void in_place_merge_sort2(int start, int end) {
    int position, width;
    width = 1;
    while ((width < (end - start))) {
      position = start;
      while (((position + (2 * width)) < end)) {
        in_place_merge2(position, (position + width), (position + (2 * width)));
        position += (2 * width);
      }
      if (((position + width) < end)) {
        in_place_merge2(position, (position + width), end);
      }
      width *= 2;
    }
  }
  void merge_with_buf(int start, int middle, int end, int length) {
    int i, j, k;
    std::tie(i, j, k) = std::make_tuple(start, middle, (start - length));
    while (((i < middle) && (j < end))) {
      if ((a[i] <= a[j])) {
        swap(k, i);
        i += 1;
      } else {
        swap(k, j);
        j += 1;
      }
      k += 1;
    }
    while ((j < end)) {
      swap(k, j);
      k += 1;
      j += 1;
    }
    shift(k, i, middle, false);
  }
  void dual_merge(int start, int middle, int end, int length) {
    int i, i2, j, j2, k;
    if (((end - middle) <= length)) {
      merge_with_buf(start, middle, end, length);
      return;
    }
    std::tie(i, j, k) = std::make_tuple(start, middle, (start - length));
    while (((k < i) && (i < middle))) {
      if ((a[i] <= a[j])) {
        swap(k, i);
        i += 1;
      } else {
        swap(k, j);
        j += 1;
      }
      k += 1;
    }
    if ((k < i)) {
      shift((j - length), j, end, false);
    } else {
      std::tie(i2, j2) = std::make_tuple((middle - 1), (end - 1));
      k = (((middle - 1) + end) - j);
      while (((i2 >= i) && (j2 >= j))) {
        if ((a[i2] > a[j2])) {
          swap(k, i2);
          i2 -= 1;
        } else {
          swap(k, j2);
          j2 -= 1;
        }
        k -= 1;
      }
      while ((j2 >= j)) {
        swap(k, j2);
        k -= 1;
        j2 -= 1;
      }
    }
  }
  void dual_merge_backward(int start, int middle, int end, int length) {
    int first_end, i, i2, j, j2, k, second_end;
    std::tie(i, j, k) = std::make_tuple((middle - 1), (end - 1), ((end - 1) + length));
    while (((k > j) && (j >= middle))) {
      if ((a[i] > a[j])) {
        swap(k, i);
        i -= 1;
      } else {
        swap(k, j);
        j -= 1;
      }
      k -= 1;
    }
    if ((j < middle)) {
      shift(start, (i + 1), ((i + 1) + length), true);
    } else {
      std::tie(first_end, second_end) = std::make_tuple((i + 1), (j + 1));
      std::tie(i2, j2) = std::make_tuple(start, middle);
      k = (middle - (first_end - start));
      while (((i2 < first_end) && (j2 < second_end))) {
        if ((a[i2] <= a[j2])) {
          swap(k, i2);
          i2 += 1;
        } else {
          swap(k, j2);
          j2 += 1;
        }
        k += 1;
      }
      while ((i2 < first_end)) {
        swap(k, i2);
        k += 1;
        i2 += 1;
      }
    }
  }
  void merge_with_buf_static(int start, int middle, int end, int position, int backward) {
    int i, j, k, q;
    if ((((middle - start) <= 0) || ((end - middle) <= 0))) {
      return;
    }
    if (backward) {
      std::tie(i, j, k) = std::make_tuple(((end - middle) - 1), (middle - 1), (end - 1));
      while (((i >= 0) && (j >= start))) {
        if ((a[j] >= a[(position + i)])) {
          q = binary_search(start, (j + 1), a[(position + i)], true);
          while ((j >= q)) {
            swap(k, j);
            k -= 1;
            j -= 1;
          }
        }
        swap(k, (position + i));
        k -= 1;
        i -= 1;
      }
      while ((i >= 0)) {
        swap(k, (position + i));
        k -= 1;
        i -= 1;
      }
    } else {
      std::tie(i, j, k) = std::make_tuple(0, middle, start);
      while (((i < (middle - start)) && (j < end))) {
        if ((a[j] < a[(position + i)])) {
          q = binary_search(j, end, a[(position + i)], true);
          while ((j < q)) {
            swap(k, j);
            k += 1;
            j += 1;
          }
        }
        swap(k, (position + i));
        k += 1;
        i += 1;
      }
      while ((i < (middle - start))) {
        swap(k, (position + i));
        k += 1;
        i += 1;
      }
    }
  }
  void block_merge(int start, int middle, int end) {
    int count, first, i, j, left, left_available, right, right_available, selection_start, tag_count;
    if (((end - middle) <= (2 * buf_len))) {
      dual_merge(start, middle, end, buf_len);
      return;
    }
    std::tie(i, j) = std::make_tuple(start, middle);
    std::tie(left_available, right_available) = std::make_tuple(buf_len, 0);
    std::tie(left, right, tag_count) = std::make_tuple((i - buf_len), j, 0);
    while (((i < middle) && (left_available >= right_available))) {
      count = 0;
      while (((i < middle) && (count < block_len))) {
        if ((a[i] <= a[j])) {
          swap(left, i);
          i += 1;
        } else {
          swap(left, j);
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
        while (((i < middle) && (j < end) && (count < block_len))) {
          if ((a[i] <= a[j])) {
            swap(right, i);
            i += 1;
            right_available -= 1;
            left_available += 1;
          } else {
            swap(right, j);
            j += 1;
          }
          right += 1;
          count += 1;
        }
        while (((i < middle) && (count < block_len))) {
          swap(right, i);
          right += 1;
          i += 1;
          right_available -= 1;
          left_available += 1;
          count += 1;
        }
        while (((j < end) && (count < block_len))) {
          swap(right, j);
          right += 1;
          j += 1;
          count += 1;
        }
        if ((count == block_len)) {
          swap_to_tags(first, tag_count);
          tag_count += 1;
        } else {
          shift(first, (first + count), end, true);
          j = (end - count);
          right = first;
        }
      }
      while (((i < middle) && (j < end) && (left_available >= right_available))) {
        first = left;
        count = 0;
        while (((i < middle) && (j < end) && (count < block_len))) {
          if ((a[i] <= a[j])) {
            swap(left, i);
            i += 1;
          } else {
            swap(left, j);
            j += 1;
            right_available += 1;
            left_available -= 1;
          }
          left += 1;
          count += 1;
        }
        while (((i < middle) && (count < block_len))) {
          swap(left, i);
          left += 1;
          i += 1;
          count += 1;
        }
        while (((j < end) && (count < block_len))) {
          swap(left, j);
          left += 1;
          j += 1;
          right_available += 1;
          left_available -= 1;
          count += 1;
        }
        if ((count == block_len)) {
          swap_to_tags(first, tag_count);
          tag_count += 1;
        } else {
          rotate(first, middle, right);
          left += (right - middle);
          left_available = 0;
        }
      }
    }
    if (((i >= middle) && (left_available == block_len) && (tag_count > 0))) {
      multi_swap(left, (right - block_len), block_len);
    } else {
      if ((i < middle)) {
        rotate(left, middle, right);
        left += (right - middle);
      }
      shift(left, (left + left_available), right, false);
    }
    if ((j < end)) {
      shift((j - buf_len), j, end, false);
    }
    block_select(selection_start, tag_count);
  }
  void block_merge_backward(int start, int middle, int end) {
    int count, first, i, j, left, left_available, right, right_available, selection_start, tag_count;
    std::tie(i, j) = std::make_tuple((middle - 1), (end - 1));
    std::tie(left_available, right_available) = std::make_tuple(0, buf_len);
    std::tie(left, right, tag_count) = std::make_tuple(i, (j + buf_len), 0);
    while (((j >= middle) && (right_available >= left_available))) {
      count = 0;
      while (((j >= middle) && (count < block_len))) {
        if ((a[i] > a[j])) {
          swap(right, i);
          i -= 1;
          left_available += 1;
          right_available -= 1;
        } else {
          swap(right, j);
          j -= 1;
        }
        right -= 1;
        count += 1;
      }
    }
    selection_start = right;
    while (((j >= middle) && (i >= start))) {
      while (((j >= middle) && (i >= start) && (left_available > right_available))) {
        std::tie(first, count) = std::make_tuple(left, 0);
        while (((j >= middle) && (i >= start) && (count < block_len))) {
          if ((a[i] > a[j])) {
            swap(left, i);
            i -= 1;
          } else {
            swap(left, j);
            j -= 1;
            right_available += 1;
            left_available -= 1;
          }
          left -= 1;
          count += 1;
        }
        while (((j >= middle) && (count < block_len))) {
          swap(left, j);
          left -= 1;
          j -= 1;
          right_available += 1;
          left_available -= 1;
          count += 1;
        }
        while (((i >= start) && (count < block_len))) {
          swap(left, i);
          left -= 1;
          i -= 1;
          count += 1;
        }
        if ((count == block_len)) {
          swap_to_tags(first, tag_count);
          tag_count += 1;
        } else {
          shift(start, ((first + 1) - count), (first + 1), false);
          i = ((start - 1) + count);
          left = first;
        }
      }
      while (((j >= middle) && (i >= start) && (right_available >= left_available))) {
        std::tie(first, count) = std::make_tuple(right, 0);
        while (((j >= middle) && (i >= start) && (count < block_len))) {
          if ((a[i] > a[j])) {
            swap(right, i);
            i -= 1;
            left_available += 1;
            right_available -= 1;
          } else {
            swap(right, j);
            j -= 1;
          }
          right -= 1;
          count += 1;
        }
        while (((j >= middle) && (count < block_len))) {
          swap(right, j);
          right -= 1;
          j -= 1;
          count += 1;
        }
        while (((i >= start) && (count < block_len))) {
          swap(right, i);
          right -= 1;
          i -= 1;
          left_available += 1;
          right_available -= 1;
          count += 1;
        }
        if ((count == block_len)) {
          swap_to_tags(first, tag_count);
          tag_count += 1;
        } else {
          rotate((left + 1), middle, (first + 1));
          right -= (middle - (left + 1));
          right_available = 0;
        }
      }
    }
    if (((j < middle) && (right_available == block_len) && (tag_count > 0))) {
      multi_swap_backward(right, (left + block_len), block_len);
    } else {
      if ((j >= middle)) {
        rotate((left + 1), middle, (right + 1));
        right -= (middle - (left + 1));
      }
      shift((left + 1), ((right + 1) - right_available), (right + 1), true);
    }
    if ((i >= start)) {
      shift(start, (i + 1), ((i + 1) + buf_len), true);
    }
    block_select_backward(selection_start, tag_count);
  }
  bool kota_iterator(int start, int end) {
    int effective_start, length, length_of_buffer, position, width;
    width = 1;
    effective_start = (start + buf_len);
    length = (end - effective_start);
    while ((width < 16)) {
      position = effective_start;
      while (((position + (2 * width)) < end)) {
        in_place_merge2(position, (position + width), (position + (2 * width)));
        position += (2 * width);
      }
      if (((position + width) < end)) {
        in_place_merge2(position, (position + width), end);
      }
      width *= 2;
    }
    while ((width <= buf_len)) {
      length_of_buffer = width;
      position = effective_start;
      while (((position + (2 * width)) < end)) {
        merge_with_buf(position, (position + width), (position + (2 * width)), length_of_buffer);
        position += (2 * width);
      }
      if (((position + width) < end)) {
        merge_with_buf(position, (position + width), end, length_of_buffer);
      } else {
        shift((position - length_of_buffer), position, end, false);
      }
      width *= 2;
      position = (effective_start - length_of_buffer);
      while (((position + (2 * width)) < (end - length_of_buffer))) {
        position += (2 * width);
      }
      if (((position + width) < (end - length_of_buffer))) {
        dual_merge_backward(position, (position + width), (end - length_of_buffer), length_of_buffer);
      } else {
        shift(position, (end - length_of_buffer), end, true);
      }
      position -= (2 * width);
      while ((position >= (effective_start - length_of_buffer))) {
        dual_merge_backward(position, (position + width), (position + (2 * width)), length_of_buffer);
        position -= (2 * width);
      }
      width *= 2;
    }
    while ((width < length)) {
      position = effective_start;
      while (((position + (2 * width)) < end)) {
        block_merge(position, (position + width), (position + (2 * width)));
        position += (2 * width);
      }
      if (((position + width) < end)) {
        block_merge(position, (position + width), end);
      } else {
        shift((position - buf_len), position, end, false);
      }
      width *= 2;
      if ((width >= length)) {
        return true;
      }
      position = start;
      while (((position + (2 * width)) < (end - buf_len))) {
        position += (2 * width);
      }
      if (((position + width) < (end - buf_len))) {
        block_merge_backward(position, (position + width), (end - buf_len));
      } else {
        shift(position, (end - buf_len), end, true);
      }
      position -= (2 * width);
      while ((position >= start)) {
        block_merge_backward(position, (position + width), (position + (2 * width)));
        position -= (2 * width);
      }
      width *= 2;
    }
    return false;
  }
  void sort() {
    int backward, buffer_end, buffer_start, buffer_target, effective_start, end_start, length, middle, position, tag_target;
    length = n;
    if ((length <= 128)) {
      in_place_merge_sort2(0, length);
      return;
    }
    buf_pos = 0;
    block_len = 1;
    while (((block_len * block_len) < length)) {
      block_len *= 2;
    }
    buffer_target = (2 * block_len);
    buf_len = find_keys(0, length, buffer_target);
    if ((buf_len < buffer_target)) {
      if ((buf_len > 1)) {
        in_place_merge_sort2(0, length);
      }
      return;
    }
    tag_target = floor(length / block_len);
    tag_len = find_keys(buf_len, length, tag_target);
    if ((tag_len < tag_target)) {
      in_place_merge_sort2(0, length);
      return;
    }
    buffer_start = tag_len;
    effective_start = (buffer_start + buf_len);
    buffer_end = buf_len;
    shift(0, buffer_end, effective_start, false);
    backward = kota_iterator(buffer_start, length);
    if (backward) {
      end_start = (length - buf_len);
      multi_swap(0, end_start, tag_len);
      merge_with_buf_static(0, buffer_start, end_start, end_start, false);
      in_place_merge_sort2(end_start, length);
      middle = (end_start + block_len);
      position = binary_search(0, end_start, a[(middle - 1)], true);
      rotate(position, end_start, middle);
      position += block_len;
      multi_swap_backward((length - 1), (position - 1), block_len);
      merge_with_buf_static(0, (position - block_len), position, middle, true);
      in_place_merge_sort2(middle, length);
      in_place_merge_backward(position, middle, length);
      in_place_merge(0, position, length);
    } else {
      merge_with_buf_static(buffer_end, effective_start, length, 0, false);
      in_place_merge_sort2(0, buffer_end);
      middle = block_len;
      position = binary_search(buffer_end, length, a[middle], true);
      rotate(middle, buffer_end, position);
      position -= block_len;
      multi_swap(0, position, block_len);
      merge_with_buf_static(position, (position + block_len), length, 0, false);
      in_place_merge_sort2(0, middle);
      in_place_merge(0, middle, position);
      in_place_merge2((length - (2 * block_len)), (length - block_len), length);
      in_place_merge(0, (length - (2 * block_len)), length);
    }
  }
};

void kota_sort(int* values, int length) {
  KotaSortExample(values, length).sort();
}

int main() {
  std::vector<int> values = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  kota_sort(values.data(), static_cast<int>(values.size()));
  std::cout << "[";
  for (size_t i = 0; i < values.size(); ++i) {
    if (i) std::cout << ", ";
    std::cout << values[i];
  }
  std::cout << "]\n";
}
