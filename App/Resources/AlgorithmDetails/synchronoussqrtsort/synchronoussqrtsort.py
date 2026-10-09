"""Synchronous square-root block merge sort by aphitorite.

MIT License. Copyright (c) 2021 The Holy Grail Sort Project, implemented by
aphitorite; Copyright (c) 2020-2021 aphitorite.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""


def sort(a):
    n = len(a)

    def binary_insertion(first, end):
        for i in range(first + 1, end):
            value = a[i]
            low, high = first, i
            while low < high:
                middle = low + (high - low) // 2
                if a[middle] <= value:
                    low = middle + 1
                else:
                    high = middle
            for j in range(i, low, -1):
                a[j] = a[j - 1]
            if low != i:
                a[low] = value

    if n <= 16:
        binary_insertion(0, n)
        return

    def shift_forward(destination, source, end):
        while source < end:
            a[destination] = a[source]
            destination += 1
            source += 1

    def shift_backward(first, source_end, destination_end):
        while source_end > first:
            source_end -= 1
            destination_end -= 1
            a[destination_end] = a[source_end]

    def merge_forward(first, middle, end, output):
        left, right = first, middle
        while left < middle and right < end:
            if a[left] <= a[right]:
                a[output] = a[left]
                left += 1
            else:
                a[output] = a[right]
                right += 1
            output += 1
        if left > output:
            shift_forward(output, left, middle)
        shift_forward(output, right, end)

    def merge_backward(first, middle, end, output):
        left, right = middle - 1, end - 1
        while right >= middle and left >= first:
            output -= 1
            if a[right] >= a[left]:
                a[output] = a[right]
                right -= 1
            else:
                a[output] = a[left]
                left -= 1
        if output > right:
            shift_backward(middle, right + 1, output)
        shift_backward(first, left + 1, output)

    def smart_merge_backward(first, middle, end, output, reversed_order):
        left, right = middle - 1, end - 1
        while left >= first and right >= middle:
            take_left = a[left] >= a[right] if reversed_order else a[left] > a[right]
            output -= 1
            if take_left:
                a[output] = a[left]
                left -= 1
            else:
                a[output] = a[right]
                right -= 1
        return left + 1

    block = 1
    while block * block < n:
        block *= 2
    remainder = n % block
    first, end = block + remainder, n
    work_length, run = end - first, 1
    prefix = [0] * first
    tags = [0] * ((n - 1) // block + 1)
    tag_length = len(tags)

    def block_selection(start, end, block_length, tag_start, tag_count):
        available = min(tag_count + 1, tag_length - tag_start)
        for i in range(available):
            tags[tag_start + i] = i + (0 if i <= tag_count // 2 else tag_length)
        vacant = current = start
        while current < end - block_length:
            minimum = current + block_length if vacant == current else current
            candidate = minimum + block_length
            while candidate < end:
                if candidate != vacant and (
                    a[candidate] < a[minimum] or
                    (a[candidate] == a[minimum] and
                     tags[tag_start + (candidate - start) // block_length] <
                     tags[tag_start + (minimum - start) // block_length])
                ):
                    minimum = candidate
                candidate += block_length
            if minimum > current:
                if vacant == current:
                    for i in range(block_length):
                        a[current + i] = a[minimum + i]
                    tags[tag_start + (current - start) // block_length] = (
                        tags[tag_start + (minimum - start) // block_length]
                    )
                    vacant = minimum
                else:
                    for i in range(block_length):
                        a[current + i], a[minimum + i] = a[minimum + i], a[current + i]
                    current_tag = tag_start + (current - start) // block_length
                    minimum_tag = tag_start + (minimum - start) // block_length
                    tags[current_tag], tags[minimum_tag] = tags[minimum_tag], tags[current_tag]
            current += block_length

    def merge_blocks_backward(start, end, first_tag, past_last_tag, block_length):
        tag = past_last_tag - 1
        frontier = end
        block_start = frontier - block_length
        reversed_order = tags[tag] < tag_length
        while True:
            tag -= 1
            block_start -= block_length
            while tag >= first_tag and (tags[tag] < tag_length) == reversed_order:
                tag -= 1
                block_start -= block_length
            if tag < first_tag:
                shift_backward(start, frontier, frontier + block_length)
                break
            frontier = smart_merge_backward(
                block_start, block_start + block_length,
                frontier, frontier + block_length, reversed_order
            )
            reversed_order = not reversed_order

    binary_insertion(0, first)
    for i in range(first):
        prefix[i] = a[i]

    while run < block:
        distance = max(2, run)
        index = first
        while index + 2 * run < end:
            merge_forward(index, index + run, index + 2 * run, index - distance)
            index += 2 * run
        if index + run < end:
            merge_forward(index, index + run, end, index - distance)
        else:
            shift_forward(index - distance, index, end)
        first -= distance
        end -= distance
        run *= 2

    fragment = work_length % (2 * run)
    index = end - fragment
    if index + run < end:
        merge_backward(index, index + run, end, end + run)
    else:
        shift_backward(index, end, end + run)
    index -= 2 * run
    while index >= first:
        merge_backward(index, index + run, index + 2 * run, index + 3 * run)
        index -= 2 * run
    first += run
    end += run
    run *= 2

    tag_count = 4
    while run < work_length:
        index = first
        tag_index = 0
        while index + 2 * run < end:
            block_selection(index - block, index + 2 * run, block, tag_index, tag_count)
            index += 2 * run
            tag_index += tag_count
        has_fragment = index + run < end
        fragment = (end - index) // block
        if has_fragment:
            block_selection(index - block, end, block, tag_index, tag_count)
        first -= block
        end -= block
        index -= block
        if has_fragment:
            merge_blocks_backward(index, end, tag_index, tag_index + fragment, block)
        index -= 2 * run
        tag_index -= tag_count
        while index >= first:
            merge_blocks_backward(index, index + 2 * run, tag_index,
                                  tag_index + tag_count, block)
            index -= 2 * run
            tag_index -= tag_count
        first += block
        end += block
        run *= 2
        tag_count *= 2

    left, right, output = 0, first, 0
    while left < first and right < end:
        if prefix[left] <= a[right]:
            a[output] = prefix[left]
            left += 1
        else:
            a[output] = a[right]
            right += 1
        output += 1
    while left < first:
        a[output] = prefix[left]
        left += 1
        output += 1


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
