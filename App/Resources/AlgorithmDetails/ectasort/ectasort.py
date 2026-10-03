# MIT License
# Copyright (c) 2020-2021 aphitorite
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


def sort(arr):
    n = len(arr)
    if n < 2:
        return

    def min_run(size):
        while size >= 32:
            size = (size + 1) // 2
        return size

    def insertion(start, end):
        for index in range(start + 1, end):
            value = arr[index]
            low, high = start, index
            while low < high:
                middle = (low + high) // 2
                if arr[middle] > value:
                    high = middle
                else:
                    low = middle + 1
            for cursor in range(index, low, -1):
                arr[cursor] = arr[cursor - 1]
            arr[low] = value

    if n <= 32:
        insertion(0, n)
        return

    if n < 256:
        block = 0
        buffer_length = n // 2
    else:
        block = min_run(n)
        while block * block < n // 2:
            block *= 2
        buffer_length = 2 * block + n % block
    buffer = [None] * buffer_length
    tags = [0] * (0 if block == 0 else (n - buffer_length) // block + 1)

    def merge_to(a, middle, end, destination):
        left, right, output = a, middle, destination
        while left < middle and right < end:
            if arr[left] <= arr[right]:
                arr[output] = arr[left]
                left += 1
            else:
                arr[output] = arr[right]
                right += 1
            output += 1
        while left < middle:
            arr[output] = arr[left]
            left += 1
            output += 1
        while right < end:
            arr[output] = arr[right]
            right += 1
            output += 1

    def ping_pong(a, m1, m2, m3, end, workspace):
        second = workspace + m2 - a
        merge_to(a, m1, m2, workspace)
        merge_to(m2, m3, end, second)
        merge_to(workspace, second, workspace + end - a, a)

    def merge_backward(a, middle, end, workspace):
        count = end - middle
        arr[workspace:workspace + count] = arr[middle:end]
        left, right, output = middle - 1, workspace + count - 1, end
        while left >= a and right >= workspace:
            output -= 1
            if arr[left] > arr[right]:
                arr[output] = arr[left]
                left -= 1
            else:
                arr[output] = arr[right]
                right -= 1
        while right >= workspace:
            output -= 1
            arr[output] = arr[right]
            right -= 1

    def merge_from_buffer(start, middle, end, count):
        index, right, output = 0, middle, start
        while index < count and right < end:
            if arr[right] >= buffer[index]:
                arr[output] = buffer[index]
                index += 1
            else:
                arr[output] = arr[right]
                right += 1
            output += 1
        while index < count:
            arr[output] = buffer[index]
            index += 1
            output += 1

    def dual_merge_backward(start, first, middle, end, count):
        index = count - 1
        split = count - (end - middle)
        left, output = middle - 1, end
        while index >= split and left >= first:
            output -= 1
            if arr[left] < buffer[index]:
                arr[output] = buffer[index]
                index -= 1
            else:
                arr[output] = arr[left]
                left -= 1
        if left < first:
            while index >= 0:
                output -= 1
                arr[output] = buffer[index]
                index -= 1
        else:
            merge_from_buffer(start, first, output, split)

    def merge_sort(start, end, workspace, initial_run, capacity):
        run = initial_run
        index = start
        while index + run <= end:
            insertion(index, index + run)
            index += run
        insertion(index, end)
        while 4 * run <= capacity:
            index = start
            while index + 4 * run <= end:
                ping_pong(index, index + run, index + 2 * run,
                          index + 3 * run, index + 4 * run, workspace)
                index += 4 * run
            if index + 3 * run < end:
                ping_pong(index, index + run, index + 2 * run,
                          index + 3 * run, end, workspace)
            elif index + 2 * run < end:
                ping_pong(index, index + run, index + 2 * run,
                          end, end, workspace)
            elif index + run < end:
                merge_backward(index, index + run, end, workspace)
            run *= 4
        while run <= capacity:
            index = start
            while index + 2 * run <= end:
                merge_backward(index, index + run, index + 2 * run, workspace)
                index += 2 * run
            if index + run < end:
                merge_backward(index, index + run, end, workspace)
            run *= 2
        return run

    if n < 256:
        buffer[:] = arr[buffer_length:2 * buffer_length]
        merge_sort(0, buffer_length, buffer_length, min_run(n), buffer_length)
        arr[buffer_length:2 * buffer_length] = buffer
        buffer[:] = arr[:buffer_length]
        merge_sort(buffer_length, n, 0, min_run(n), buffer_length)
        merge_from_buffer(0, buffer_length, n, buffer_length)
        return

    def block_cycle(start, count, workspace, exclude_last, forward):
        stride = block if forward else -block
        for index in range(count):
            next_tag = tags[index]
            if index != next_tag:
                source = start + index * stride
                arr[workspace:workspace + block] = arr[source:source + block]
                current = index
                while True:
                    if not (exclude_last and current == count - 1):
                        destination = start + current * stride
                        source = start + next_tag * stride
                        arr[destination:destination + block] = arr[source:source + block]
                    tags[current] = current
                    current = next_tag
                    next_tag = tags[next_tag]
                    if next_tag == index:
                        break
                destination = start + current * stride
                arr[destination:destination + block] = arr[workspace:workspace + block]
                tags[current] = current

    def ecta_forward(start, middle, end):
        left, right = start, middle
        tag = tag_count = other = 0
        saved = 2 * block
        saved_position, other_position = start - 2 * block, middle
        while True:
            choice = 1 if saved < block else 0
            for offset in range(block):
                destination = (other_position if choice else saved_position) + offset
                if left < middle and right < end:
                    if arr[left] <= arr[right]:
                        arr[destination] = arr[left]
                        left += 1
                        saved += 1
                    else:
                        arr[destination] = arr[right]
                        right += 1
                        other += 1
                elif left < middle:
                    arr[destination] = arr[left]
                    left += 1
                    saved += 1
                else:
                    arr[destination] = arr[right]
                    right += 1
                    other += 1
            if choice == 0:
                saved_position += block
                saved -= block
            else:
                other_position += block
                other -= block
            tags[tag_count] = tag if choice == 0 else -1
            tag_count += 1
            if choice == 0:
                tag += 1
            if not (left < middle or right < end):
                break
        if saved > 0:
            tags[tag_count] = tag
            tag += 1
        for index in range(2, tag_count):
            if tags[index] == -1:
                tags[index] = tag
                tag += 1
        block_cycle(start - 2 * block, tag, end - block, saved > 0, True)

    def ecta_backward(start, middle, end):
        right, left = end - 1, middle - 1
        tag = tag_count = other = 0
        saved = 2 * block
        saved_position, other_position = end + 2 * block, middle
        while True:
            choice = 1 if saved < block else 0
            for offset in range(1, block + 1):
                destination = (other_position if choice else saved_position) - offset
                if right >= middle and left >= start:
                    if arr[right] >= arr[left]:
                        arr[destination] = arr[right]
                        right -= 1
                        saved += 1
                    else:
                        arr[destination] = arr[left]
                        left -= 1
                        other += 1
                elif right >= middle:
                    arr[destination] = arr[right]
                    right -= 1
                    saved += 1
                else:
                    arr[destination] = arr[left]
                    left -= 1
                    other += 1
            if choice == 0:
                saved_position -= block
                saved -= block
            else:
                other_position -= block
                other -= block
            tags[tag_count] = tag if choice == 0 else -1
            tag_count += 1
            if choice == 0:
                tag += 1
            if not (right >= middle or left >= start):
                break
        if saved > 0:
            tags[tag_count] = tag
            tag += 1
        for index in range(2, tag_count):
            if tags[index] == -1:
                tags[index] = tag
                tag += 1
        block_cycle(end + block, tag, start, saved > 0, False)

    start, end = buffer_length, n
    data_length = end - start
    buffer[:] = arr[start:start + buffer_length]
    merge_sort(0, start, start, min_run(buffer_length), buffer_length)
    arr[start:start + buffer_length] = buffer
    buffer[:] = arr[:buffer_length]
    run = merge_sort(start, end, 0, min_run(n), buffer_length)
    backward = False
    while run < data_length:
        index = start
        while index + 2 * run <= end:
            ecta_forward(index, index + run, index + 2 * run)
            index += 2 * run
        if index + run < end:
            ecta_forward(index, index + run, end)
        else:
            destination = index - 2 * block
            for source in range(index, end):
                arr[destination] = arr[source]
                destination += 1
        run *= 2
        start -= 2 * block
        end -= 2 * block
        if run >= data_length:
            backward = True
            break
        index = start
        while index + 2 * run <= end:
            index += 2 * run
        if index + run < end:
            ecta_backward(index, index + run, end)
        else:
            destination = end
            for source in range(end - 1, index - 1, -1):
                destination -= 1
                arr[destination + 2 * block] = arr[source]
        index -= 2 * run
        while index >= start:
            ecta_backward(index, index + run, index + 2 * run)
            index -= 2 * run
        run *= 2
        start += 2 * block
        end += 2 * block
    if backward:
        dual_merge_backward(0, start, end, n, buffer_length)
    else:
        merge_from_buffer(0, start, end, buffer_length)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
