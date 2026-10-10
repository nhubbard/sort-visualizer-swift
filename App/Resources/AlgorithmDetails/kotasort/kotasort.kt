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


class KotaSortExample(private val a: IntArray) {
  private var buf_pos = 0
  private var block_len = 0
  private var buf_len = 0
  private var tag_len = 0
  fun swap(left: Int, right: Int) {
    var _sim0_0 = a[right]
    var _sim0_1 = a[left]
    a[left] = _sim0_0;
    a[right] = _sim0_1;
  }
  fun rotate(startIn: Int, middle: Int, end: Int) {
    var start = startIn;
    var left_len = 0
    var offset = 0
    var right_len = 0
    var _sim1_0 = (middle - start)
    var _sim1_1 = (end - middle)
    left_len = _sim1_0;
    right_len = _sim1_1;
    while ((left_len != 0 && right_len != 0)) {
      if ((left_len <= right_len)) {
        for (offset in 0 until left_len) {
          swap((start + offset), ((start + left_len) + offset));
        }
        start += left_len;
        right_len -= left_len;
      } else {
        for (offset in 0 until right_len) {
          swap((((start + left_len) - right_len) + offset), ((start + left_len) + offset));
        }
        left_len -= right_len;
      }
    }
  }
  fun binary_search(startIn: Int, endIn: Int, value: Int, left: Boolean): Int {
    var start = startIn;
    var end = endIn;
    var middle = 0
    while ((start < end)) {
      middle = (start + ((end - start) / 2));
      if ((if (left) (a[middle] >= value) else (a[middle] > value))) {
        end = middle;
      } else {
        start = (middle + 1);
      }
    }
    return start;
  }
  fun find_keys(start: Int, end: Int, target: Int): Int {
    var count = 0
    var increase = 0
    var index = 0
    var loc = 0
    var pos = 0
    var pos_end = 0
    var value = 0
    var _sim2_0 = 1
    var _sim2_1 = start
    var _sim2_2 = (start + 1)
    var _sim2_3 = (start + 1)
    count = _sim2_0;
    pos = _sim2_1;
    pos_end = _sim2_2;
    index = _sim2_3;
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
  fun swap_to_tags(position: Int, tag: Int) {
    swap((buf_pos + tag), position);
  }
  fun shift(startIn: Int, middleIn: Int, endIn: Int, left: Boolean) {
    var start = startIn;
    var middle = middleIn;
    var end = endIn;
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
  fun multi_swap(first: Int, second: Int, length: Int) {
    var offset = 0
    for (offset in 0 until length) {
      swap((first + offset), (second + offset));
    }
  }
  fun multi_swap_backward(first: Int, second: Int, length: Int) {
    var offset = 0
    for (offset in 0 until length) {
      swap((first - offset), (second - offset));
    }
  }
  fun block_select(position: Int, count: Int) {
    var candidate = 0
    var index = 0
    var minimum = 0
    var start = 0
    var tag = 0
    for (tag in 0 until count) {
      start = (position + (tag * block_len));
      minimum = start;
      for (index in (tag + 1) until count) {
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
  fun block_select_backward(position: Int, count: Int) {
    var candidate = 0
    var index = 0
    var minimum = 0
    var start = 0
    var tag = 0
    for (tag in 0 until count) {
      start = (position - (tag * block_len));
      minimum = start;
      for (index in (tag + 1) until count) {
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
  fun in_place_merge(start: Int, middle: Int, end: Int) {
    var i = 0
    var j = 0
    var k = 0
    var _sim3_0 = start
    var _sim3_1 = middle
    i = _sim3_0;
    j = _sim3_1;
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
  fun in_place_merge_backward(start: Int, middle: Int, end: Int) {
    var i = 0
    var j = 0
    var k = 0
    var _sim4_0 = (middle - 1)
    var _sim4_1 = (end - 1)
    i = _sim4_0;
    j = _sim4_1;
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
  fun in_place_merge2(start: Int, middle: Int, end: Int) {
    var i = 0
    var k = 0
    var m = 0
    var q = 0
    var _sim5_0 = start
    var _sim5_1 = middle
    var _sim5_2 = middle
    i = _sim5_0;
    m = _sim5_1;
    k = _sim5_2;
    while ((m < end)) {
      if ((a[(m - 1)] <= a[m])) {
        return
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
          return
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
  fun in_place_merge_sort2(start: Int, end: Int) {
    var position = 0
    var width = 0
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
  fun merge_with_buf(start: Int, middle: Int, end: Int, length: Int) {
    var i = 0
    var j = 0
    var k = 0
    var _sim6_0 = start
    var _sim6_1 = middle
    var _sim6_2 = (start - length)
    i = _sim6_0;
    j = _sim6_1;
    k = _sim6_2;
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
  fun dual_merge(start: Int, middle: Int, end: Int, length: Int) {
    var i = 0
    var i2 = 0
    var j = 0
    var j2 = 0
    var k = 0
    if (((end - middle) <= length)) {
      merge_with_buf(start, middle, end, length);
      return
    }
    var _sim7_0 = start
    var _sim7_1 = middle
    var _sim7_2 = (start - length)
    i = _sim7_0;
    j = _sim7_1;
    k = _sim7_2;
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
      var _sim8_0 = (middle - 1)
      var _sim8_1 = (end - 1)
      i2 = _sim8_0;
      j2 = _sim8_1;
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
  fun dual_merge_backward(start: Int, middle: Int, end: Int, length: Int) {
    var first_end = 0
    var i = 0
    var i2 = 0
    var j = 0
    var j2 = 0
    var k = 0
    var second_end = 0
    var _sim9_0 = (middle - 1)
    var _sim9_1 = (end - 1)
    var _sim9_2 = ((end - 1) + length)
    i = _sim9_0;
    j = _sim9_1;
    k = _sim9_2;
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
      var _sim10_0 = (i + 1)
      var _sim10_1 = (j + 1)
      first_end = _sim10_0;
      second_end = _sim10_1;
      var _sim11_0 = start
      var _sim11_1 = middle
      i2 = _sim11_0;
      j2 = _sim11_1;
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
  fun merge_with_buf_static(start: Int, middle: Int, end: Int, position: Int, backward: Boolean) {
    var i = 0
    var j = 0
    var k = 0
    var q = 0
    if ((((middle - start) <= 0) || ((end - middle) <= 0))) {
      return
    }
    if (backward) {
      var _sim12_0 = ((end - middle) - 1)
      var _sim12_1 = (middle - 1)
      var _sim12_2 = (end - 1)
      i = _sim12_0;
      j = _sim12_1;
      k = _sim12_2;
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
      var _sim13_0 = 0
      var _sim13_1 = middle
      var _sim13_2 = start
      i = _sim13_0;
      j = _sim13_1;
      k = _sim13_2;
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
  fun block_merge(start: Int, middle: Int, end: Int) {
    var count = 0
    var first = 0
    var i = 0
    var j = 0
    var left = 0
    var left_available = 0
    var right = 0
    var right_available = 0
    var selection_start = 0
    var tag_count = 0
    if (((end - middle) <= (2 * buf_len))) {
      dual_merge(start, middle, end, buf_len);
      return
    }
    var _sim14_0 = start
    var _sim14_1 = middle
    i = _sim14_0;
    j = _sim14_1;
    var _sim15_0 = buf_len
    var _sim15_1 = 0
    left_available = _sim15_0;
    right_available = _sim15_1;
    var _sim16_0 = (i - buf_len)
    var _sim16_1 = j
    var _sim16_2 = 0
    left = _sim16_0;
    right = _sim16_1;
    tag_count = _sim16_2;
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
  fun block_merge_backward(start: Int, middle: Int, end: Int) {
    var count = 0
    var first = 0
    var i = 0
    var j = 0
    var left = 0
    var left_available = 0
    var right = 0
    var right_available = 0
    var selection_start = 0
    var tag_count = 0
    var _sim17_0 = (middle - 1)
    var _sim17_1 = (end - 1)
    i = _sim17_0;
    j = _sim17_1;
    var _sim18_0 = 0
    var _sim18_1 = buf_len
    left_available = _sim18_0;
    right_available = _sim18_1;
    var _sim19_0 = i
    var _sim19_1 = (j + buf_len)
    var _sim19_2 = 0
    left = _sim19_0;
    right = _sim19_1;
    tag_count = _sim19_2;
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
        var _sim20_0 = left
        var _sim20_1 = 0
        first = _sim20_0;
        count = _sim20_1;
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
        var _sim21_0 = right
        var _sim21_1 = 0
        first = _sim21_0;
        count = _sim21_1;
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
  fun kota_iterator(start: Int, end: Int): Boolean {
    var effective_start = 0
    var length = 0
    var length_of_buffer = 0
    var position = 0
    var width = 0
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
  fun sort() {
    var backward = false
    var buffer_end = 0
    var buffer_start = 0
    var buffer_target = 0
    var effective_start = 0
    var end_start = 0
    var length = 0
    var middle = 0
    var position = 0
    var tag_target = 0
    length = a.size;
    if ((length <= 128)) {
      in_place_merge_sort2(0, length);
      return
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
      return
    }
    tag_target = (length / block_len);
    tag_len = find_keys(buf_len, length, tag_target);
    if ((tag_len < tag_target)) {
      in_place_merge_sort2(0, length);
      return
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
}

fun kotaSort(values: IntArray) { KotaSortExample(values).sort() }

fun main() {
  val values = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
  kotaSort(values)
  println(values.joinToString(prefix = "[", postfix = "]"))
}
