# MIT License
# Copyright (c) 2014 Andrey Astrelin
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


class SqrtSortExample:
    def __init__(self, values):
        self.values = values
        self.buffer = []
        self.tags = []

    def read(self, storage, index):
        return (self.buffer if storage else self.values)[index]

    def write(self, storage, index, value):
        (self.buffer if storage else self.values)[index] = value

    def compare(self, storage, left, right, other_storage=None):
        if other_storage is None:
            other_storage = storage
        a = self.read(storage, left)
        b = self.read(other_storage, right)
        return (a > b) - (a < b)

    def copy(self, source_storage, source, target_storage, target, count):
        if count <= 0:
            return
        if source_storage == target_storage and source < target < source + count:
            offsets = range(count - 1, -1, -1)
        else:
            offsets = range(count)
        for offset in offsets:
            self.write(target_storage, target + offset,
                       self.read(source_storage, source + offset))

    def swap(self, storage, a, b):
        if a != b:
            first = self.read(storage, a)
            self.write(storage, a, self.read(storage, b))
            self.write(storage, b, first)

    def insertion(self, storage, position, length):
        for index in range(position + 1, position + length):
            value = self.read(storage, index)
            cursor = index
            while cursor > position and self.read(storage, cursor - 1) > value:
                self.write(storage, cursor, self.read(storage, cursor - 1))
                cursor -= 1
            self.write(storage, cursor, value)

    def merge_right(self, storage, position, left_length, right_length, distance):
        destination = position + left_length + right_length + distance - 1
        right = position + left_length + right_length - 1
        left = position + left_length - 1
        while left >= position:
            if right < position + left_length or self.compare(storage, left, right) > 0:
                self.write(storage, destination, self.read(storage, left))
                left -= 1
            else:
                self.write(storage, destination, self.read(storage, right))
                right -= 1
            destination -= 1
        if right != destination:
            while right >= position + left_length:
                self.write(storage, destination, self.read(storage, right))
                right -= 1
                destination -= 1

    def merge_left(self, storage, position, left_length, right_length, distance):
        left = position
        right = position + left_length
        destination = position + distance
        left_end = right
        right_end = right + right_length
        while right < right_end:
            if left == left_end or self.compare(storage, left, right) > 0:
                self.write(storage, destination, self.read(storage, right))
                right += 1
            else:
                self.write(storage, destination, self.read(storage, left))
                left += 1
            destination += 1
        if destination != left:
            while left < left_end:
                self.write(storage, destination, self.read(storage, left))
                left += 1
                destination += 1

    def merge_down(self, storage, position, prefix, prefix_position, left_length, prefix_length):
        left = right = 0
        destination = position - prefix_length
        while right < prefix_length:
            if left == left_length or self.compare(storage, position + left, prefix_position + right, prefix) >= 0:
                self.write(storage, destination, self.read(prefix, prefix_position + right))
                right += 1
            else:
                self.write(storage, destination, self.read(storage, position + left))
                left += 1
            destination += 1
        if destination != position + left:
            while left < left_length:
                self.write(storage, destination, self.read(storage, position + left))
                left += 1
                destination += 1

    def smart_merge(self, storage, position, prior_length, prior_fragment, block_length):
        left = position
        right = position + prior_length
        destination = position - block_length
        left_end = right
        right_end = right + block_length
        opposite = 1 - prior_fragment
        while left < left_end and right < right_end:
            order = self.compare(storage, left, right)
            if order < 0 or (order == 0 and opposite == 1):
                self.write(storage, destination, self.read(storage, left))
                left += 1
            else:
                self.write(storage, destination, self.read(storage, right))
                right += 1
            destination += 1
        if left < left_end:
            remaining = left_end - left
            while left < left_end:
                left_end -= 1
                right_end -= 1
                self.write(storage, right_end, self.read(storage, left_end))
            return remaining, prior_fragment
        return right_end - right, opposite

    def merge_buffers(self, storage, position, middle_tag, block_count,
                      block_length, trailing_a_blocks, tail_length):
        if block_count == 0:
            self.merge_left(storage, position, trailing_a_blocks * block_length,
                            tail_length, -block_length)
            return
        prior_length = block_length
        prior_fragment = 0 if self.tags[0] < middle_tag else 1
        process = block_length
        for tag_index in range(1, block_count):
            rest = process - prior_length
            next_fragment = 0 if self.tags[tag_index] < middle_tag else 1
            if next_fragment == prior_fragment:
                self.copy(storage, position + rest, storage,
                          position + rest - block_length, prior_length)
                rest = process
                prior_length = block_length
            else:
                prior_length, prior_fragment = self.smart_merge(
                    storage, position + rest, prior_length, prior_fragment, block_length)
            process += block_length
        rest = process - prior_length
        if tail_length != 0:
            if prior_fragment != 0:
                self.copy(storage, position + rest, storage,
                          position + rest - block_length, prior_length)
                rest = process
                prior_length = block_length * trailing_a_blocks
            else:
                prior_length += block_length * trailing_a_blocks
            self.merge_left(storage, position + rest, prior_length,
                            tail_length, -block_length)
        else:
            self.copy(storage, position + rest, storage,
                      position + rest - block_length, prior_length)

    def build_blocks(self, storage, position, length, block_length):
        pair = 1
        while pair < length:
            lower = 1 if self.compare(storage, position + pair - 1, position + pair) > 0 else 0
            self.write(storage, position + pair - 3,
                       self.read(storage, position + pair - 1 + lower))
            self.write(storage, position + pair - 2,
                       self.read(storage, position + pair - lower))
            pair += 2
        if length % 2:
            self.write(storage, position + length - 3,
                       self.read(storage, position + length - 1))
        position -= 2
        part = 2
        while part < block_length:
            left = 0
            right = length - 2 * part
            while left <= right:
                self.merge_left(storage, position + left, part, part, -part)
                left += 2 * part
            rest = length - left
            if rest > part:
                self.merge_left(storage, position + left, part, rest - part, -part)
            else:
                while left < length:
                    self.write(storage, position + left - part,
                               self.read(storage, position + left))
                    left += 1
            position -= part
            part *= 2
        remainder = length % (2 * block_length)
        leftover = length - remainder
        if remainder <= block_length:
            self.copy(storage, position + leftover, storage,
                      position + leftover + block_length, remainder)
        else:
            self.merge_right(storage, position + leftover, block_length,
                             remainder - block_length, block_length)
        while leftover > 0:
            leftover -= 2 * block_length
            self.merge_right(storage, position + leftover,
                             block_length, block_length, block_length)

    def combine_blocks(self, storage, position, length, run_length, block_length):
        combine_count = length // (2 * run_length)
        remainder = length % (2 * run_length)
        if remainder <= run_length:
            length -= remainder
            remainder = 0
        for group in range(combine_count + 1):
            if group == combine_count and remainder == 0:
                break
            group_position = position + group * 2 * run_length
            count = (remainder if group == combine_count else 2 * run_length) // block_length
            tag_end = count + (1 if group == combine_count else 0)
            for tag in range(tag_end + 1):
                self.tags[tag] = tag
            middle = run_length // block_length
            for tag_index in range(1, count):
                selected = tag_index - 1
                for candidate in range(tag_index, count):
                    order = self.compare(storage, group_position + selected * block_length,
                                         group_position + candidate * block_length)
                    if order > 0 or (order == 0 and self.tags[selected] > self.tags[candidate]):
                        selected = candidate
                if selected != tag_index - 1:
                    for offset in range(block_length):
                        self.swap(storage, group_position + (tag_index - 1) * block_length + offset,
                                  group_position + selected * block_length + offset)
                    self.tags[tag_index - 1], self.tags[selected] = (
                        self.tags[selected], self.tags[tag_index - 1])
            trailing_a = 0
            tail = remainder % block_length if group == combine_count else 0
            if tail:
                while trailing_a < count and self.compare(
                    storage, group_position + count * block_length,
                    group_position + (count - trailing_a - 1) * block_length) < 0:
                    trailing_a += 1
            self.merge_buffers(storage, group_position, middle, count - trailing_a,
                               block_length, trailing_a, tail)
        if length > 0:
            for index in range(length - 1, -1, -1):
                self.write(storage, position + index,
                           self.read(storage, position + index - block_length))

    def common_sort(self, storage, position, length, prefix, prefix_position):
        if length <= 16:
            self.insertion(storage, position, length)
            return
        block_length = 1
        while block_length * block_length < length:
            block_length *= 2
        self.copy(storage, position, prefix, prefix_position, block_length)
        self.common_sort(prefix, prefix_position, block_length, storage, position)
        self.build_blocks(storage, position + block_length, length - block_length,
                          block_length)
        run_length = block_length
        while True:
            run_length *= 2
            if length <= run_length:
                break
            self.combine_blocks(storage, position + block_length, length - block_length,
                                run_length, block_length)
        self.merge_down(storage, position + block_length, prefix, prefix_position,
                        length - block_length, block_length)

    def sort(self):
        length = len(self.values)
        if length < 2:
            return
        buffer_length = 1
        while buffer_length * buffer_length < length:
            buffer_length *= 2
        self.buffer = [0] * buffer_length
        self.tags = [0] * ((length - 1) // buffer_length + 2)
        self.common_sort(False, 0, length, True, 0)


def sort(values):
    SqrtSortExample(values).sort()


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
