CAPACITY = 64


def sort(values):
    if len(values) < 2:
        return
    buffer = [0] * CAPACITY

    def lower_bound(start, end, value):
        while start < end:
            middle = (start + end) // 2
            if values[middle] < value:
                start = middle + 1
            else:
                end = middle
        return start

    def upper_bound(start, end, value):
        while start < end:
            middle = (start + end) // 2
            if values[middle] <= value:
                start = middle + 1
            else:
                end = middle
        return start

    def reverse(start, end):
        end -= 1
        while start < end:
            values[start], values[end] = values[end], values[start]
            start += 1
            end -= 1

    def rotate(start, middle, end):
        if start >= middle or middle >= end:
            return
        left = middle - start
        right = end - middle
        if left <= CAPACITY:
            for i in range(left):
                buffer[i] = values[start + i]
            for i in range(middle, end):
                values[i - left] = values[i]
            for i in range(left):
                values[end - left + i] = buffer[i]
        elif right <= CAPACITY:
            for i in range(right):
                buffer[i] = values[middle + i]
            for i in range(middle - 1, start - 1, -1):
                values[i + right] = values[i]
            for i in range(right):
                values[start + i] = buffer[i]
        else:
            reverse(start, middle)
            reverse(middle, end)
            reverse(start, end)

    def buffered_merge(start, middle, end):
        left_length = middle - start
        right_length = end - middle
        if left_length <= right_length:
            for i in range(left_length):
                buffer[i] = values[start + i]
            left, right, destination = 0, middle, start
            while left < left_length and right < end:
                if values[right] < buffer[left]:
                    values[destination] = values[right]
                    right += 1
                else:
                    values[destination] = buffer[left]
                    left += 1
                destination += 1
            while left < left_length:
                values[destination] = buffer[left]
                left += 1
                destination += 1
        else:
            for i in range(right_length):
                buffer[i] = values[middle + i]
            left, right, destination = middle - 1, right_length - 1, end - 1
            while left >= start and right >= 0:
                if values[left] > buffer[right]:
                    values[destination] = values[left]
                    left -= 1
                else:
                    values[destination] = buffer[right]
                    right -= 1
                destination -= 1
            while right >= 0:
                values[destination] = buffer[right]
                right -= 1
                destination -= 1

    def merge(start, middle, end):
        if start >= middle or middle >= end or values[middle - 1] <= values[middle]:
            return
        if min(middle - start, end - middle) <= CAPACITY:
            buffered_merge(start, middle, end)
            return
        if middle - start >= end - middle:
            left_split = start + (middle - start) // 2
            right_split = lower_bound(middle, end, values[left_split])
        else:
            right_split = middle + (end - middle) // 2
            left_split = upper_bound(start, middle, values[right_split])
        rotate(left_split, middle, right_split)
        new_middle = left_split + right_split - middle
        merge(start, left_split, new_middle)
        merge(new_middle, right_split, end)

    def insertion(start, end):
        for index in range(start + 1, end):
            value = values[index]
            destination = upper_bound(start, index, value)
            for cursor in range(index, destination, -1):
                values[cursor] = values[cursor - 1]
            values[destination] = value

    count = len(values)
    for start in range(0, count, 32):
        insertion(start, min(start + 32, count))
    run = 32
    while run < count:
        for start in range(0, count - run, 2 * run):
            merge(start, start + run, min(start + 2 * run, count))
        run *= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
