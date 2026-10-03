"""Stable TimSort with corrected run-stack invariants and galloping merges.

Copyright (C) 2008 The Android Open Source Project.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""


class TimSort:
    def __init__(self, values):
        self.a = values
        self.n = len(values)
        capacity = 5 if self.n < 120 else 10 if self.n < 1542 else 19 if self.n < 119151 else 40
        self.base = [0] * capacity
        self.length = [0] * capacity
        self.stack_size = 0
        self.temp = []
        self.min_gallop = 7

    def ensure_capacity(self, needed):
        if len(self.temp) >= needed:
            return
        capacity = max(1, len(self.temp))
        while capacity < needed:
            capacity *= 2
        capacity = min(capacity, max(1, self.n // 2))
        self.temp = [0] * capacity

    @staticmethod
    def min_run_length(value):
        remainder = 0
        while value >= 32:
            remainder |= value & 1
            value >>= 1
        return value + remainder

    def count_run(self, first, end):
        if first + 1 >= end:
            return 1
        cursor = first + 2
        if self.a[first + 1] < self.a[first]:
            while cursor < end and self.a[cursor] < self.a[cursor - 1]:
                cursor += 1
            left, right = first, cursor - 1
            while left < right:
                self.a[left], self.a[right] = self.a[right], self.a[left]
                left += 1
                right -= 1
        else:
            while cursor < end and self.a[cursor] >= self.a[cursor - 1]:
                cursor += 1
        return cursor - first

    def binary_insertion(self, first, end, sorted_end):
        cursor = max(first + 1, sorted_end)
        while cursor < end:
            pivot = self.a[cursor]
            low, high = first, cursor
            while low < high:
                middle = low + (high - low) // 2
                if self.a[middle] <= pivot:
                    low = middle + 1
                else:
                    high = middle
            for shift in range(cursor, low, -1):
                self.a[shift] = self.a[shift - 1]
            self.a[low] = pivot
            cursor += 1

    def gallop(self, first, end, key, upper, from_end, use_temp):
        if first >= end:
            return first
        source = self.temp if use_temp else self.a

        def before(index):
            value = source[index]
            return value <= key if upper else value < key

        if from_end:
            high = end
            low = end - 1
            step = 1
            while not before(low):
                high = low
                if low == first:
                    break
                step = min(end - first, step * 2)
                low = max(first, end - step)
        else:
            low, high = first, first + 1
            while before(high - 1) and high < end:
                low = high
                high = min(end, first + (high - first) * 2)
        while low < high:
            middle = low + (high - low) // 2
            if before(middle):
                low = middle + 1
            else:
                high = middle
        return low

    def merge_low(self, first, left_length, right_start, right_length):
        self.ensure_capacity(left_length)
        for i in range(left_length):
            self.temp[i] = self.a[first + i]
        left, right, destination = 0, right_start, first
        right_end = right_start + right_length
        left_wins = right_wins = 0
        galloped = False
        while left < left_length and right < right_end:
            if self.a[right] < self.temp[left]:
                self.a[destination] = self.a[right]
                right += 1
                right_wins += 1
                left_wins = 0
            else:
                self.a[destination] = self.temp[left]
                left += 1
                left_wins += 1
                right_wins = 0
            destination += 1
            if left >= left_length or right >= right_end:
                break
            if max(left_wins, right_wins) < self.min_gallop:
                continue
            galloped = True
            left_stop = self.gallop(left, left_length, self.a[right], True, False, True)
            while left < left_stop:
                self.a[destination] = self.temp[left]
                left += 1
                destination += 1
            if left == left_length:
                break
            self.a[destination] = self.a[right]
            right += 1
            destination += 1
            if right == right_end:
                break
            right_stop = self.gallop(right, right_end, self.temp[left], False, False, False)
            while right < right_stop:
                self.a[destination] = self.a[right]
                right += 1
                destination += 1
            if right == right_end:
                break
            self.a[destination] = self.temp[left]
            left += 1
            destination += 1
            self.min_gallop = max(1, self.min_gallop - 1)
            left_wins = right_wins = 0
        while left < left_length:
            self.a[destination] = self.temp[left]
            left += 1
            destination += 1
        if galloped:
            self.min_gallop += 2

    def merge_high(self, first, left_length, right_start, right_length):
        self.ensure_capacity(right_length)
        for i in range(right_length):
            self.temp[i] = self.a[right_start + i]
        left, right = right_start - 1, right_length - 1
        destination = right_start + right_length - 1
        left_wins = right_wins = 0
        galloped = False
        while left >= first and right >= 0:
            if self.temp[right] < self.a[left]:
                self.a[destination] = self.a[left]
                left -= 1
                left_wins += 1
                right_wins = 0
            else:
                self.a[destination] = self.temp[right]
                right -= 1
                right_wins += 1
                left_wins = 0
            destination -= 1
            if left < first or right < 0:
                break
            if max(left_wins, right_wins) < self.min_gallop:
                continue
            galloped = True
            left_stop = self.gallop(first, left + 1, self.temp[right], True, True, False)
            while left >= left_stop:
                self.a[destination] = self.a[left]
                left -= 1
                destination -= 1
            if left < first:
                break
            self.a[destination] = self.temp[right]
            right -= 1
            destination -= 1
            if right < 0:
                break
            right_stop = self.gallop(0, right + 1, self.a[left], False, True, True)
            while right >= right_stop:
                self.a[destination] = self.temp[right]
                right -= 1
                destination -= 1
            if right < 0:
                break
            self.a[destination] = self.a[left]
            left -= 1
            destination -= 1
            self.min_gallop = max(1, self.min_gallop - 1)
            left_wins = right_wins = 0
        while right >= 0:
            self.a[destination] = self.temp[right]
            right -= 1
            destination -= 1
        if galloped:
            self.min_gallop += 2

    def merge_at(self, index):
        left_start, left_length = self.base[index], self.length[index]
        right_start, right_length = self.base[index + 1], self.length[index + 1]
        self.length[index] = left_length + right_length
        if index == self.stack_size - 3:
            self.base[index + 1] = self.base[index + 2]
            self.length[index + 1] = self.length[index + 2]
        self.stack_size -= 1
        skipped = self.gallop(left_start, right_start, self.a[right_start], True, False, False)
        left_length -= skipped - left_start
        left_start = skipped
        if left_length == 0:
            return
        right_length = (
            self.gallop(right_start, right_start + right_length,
                        self.a[right_start - 1], False, False, False) - right_start
        )
        if right_length == 0:
            return
        if left_length <= right_length:
            self.merge_low(left_start, left_length, right_start, right_length)
        else:
            self.merge_high(left_start, left_length, right_start, right_length)

    def collapse(self):
        while self.stack_size > 1:
            index = self.stack_size - 2
            if ((index >= 1 and
                 self.length[index - 1] <= self.length[index] + self.length[index + 1]) or
                (index >= 2 and
                 self.length[index - 2] <= self.length[index] + self.length[index - 1])):
                if self.length[index - 1] < self.length[index + 1]:
                    index -= 1
            elif self.length[index] > self.length[index + 1]:
                break
            self.merge_at(index)

    def force_collapse(self):
        while self.stack_size > 1:
            index = self.stack_size - 2
            if index > 0 and self.length[index - 1] < self.length[index + 1]:
                index -= 1
            self.merge_at(index)

    def sort(self):
        if self.n < 32:
            run = self.count_run(0, self.n)
            self.binary_insertion(0, self.n, run)
            return
        min_run = self.min_run_length(self.n)
        cursor = 0
        while cursor < self.n:
            run = self.count_run(cursor, self.n)
            if run < min_run:
                forced = min(min_run, self.n - cursor)
                self.binary_insertion(cursor, cursor + forced, cursor + run)
                run = forced
            self.base[self.stack_size] = cursor
            self.length[self.stack_size] = run
            self.stack_size += 1
            self.collapse()
            cursor += run
        self.force_collapse()


def sort(values):
    if len(values) > 1:
        TimSort(values).sort()


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
