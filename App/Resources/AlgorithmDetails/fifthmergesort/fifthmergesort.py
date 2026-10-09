"""Five-way stable merge with a one-fifth external buffer."""


def sort(a):
    n = len(a)
    if n <= 1:
        return
    fifth = n // 5
    buffer_length = n - 4 * fifth
    buffer = [0] * buffer_length

    def binary_insertion(first, end):
        for i in range(first + 1, end):
            value = a[i]
            low, high = first, i
            while low < high:
                middle = low + (high - low) // 2
                if a[middle] > value:
                    high = middle
                else:
                    low = middle + 1
            for j in range(i, low, -1):
                a[j] = a[j - 1]
            a[low] = value

    def source(index, offset, from_buffer):
        return buffer[index - offset] if from_buffer else a[index]

    def merge(offset, first, middle, end, from_buffer):
        left, right = first, middle
        destination = first if from_buffer else first - offset
        while left < middle and right < end:
            if source(left, offset, from_buffer) <= source(right, offset, from_buffer):
                value = source(left, offset, from_buffer)
                left += 1
            else:
                value = source(right, offset, from_buffer)
                right += 1
            if from_buffer:
                a[destination] = value
            else:
                buffer[destination] = value
            destination += 1
        while left < middle:
            value = source(left, offset, from_buffer)
            if from_buffer:
                a[destination] = value
            else:
                buffer[destination] = value
            left += 1
            destination += 1
        while right < end:
            value = source(right, offset, from_buffer)
            if from_buffer:
                a[destination] = value
            else:
                buffer[destination] = value
            right += 1
            destination += 1

    def ping_pong(first, end):
        i = first
        while i + 8 < end:
            binary_insertion(i, i + 8)
            i += 8
        if end - i > 1:
            binary_insertion(i, end)
        length = end - first
        from_buffer = False
        gap = 8
        while gap < length:
            full = gap * 2
            i = first
            while i + full < end:
                merge(first, i, i + gap, i + full, from_buffer)
                i += full
            if i + gap < end:
                merge(first, i, i + gap, end, from_buffer)
            elif from_buffer:
                for j in range(i, end):
                    a[j] = buffer[j - first]
            else:
                for j in range(i, end):
                    buffer[j - first] = a[j]
            from_buffer = not from_buffer
            gap *= 2
        if from_buffer:
            for j in range(length):
                a[first + j] = buffer[j]

    def merge_forward(destination, first, middle, end):
        left, right = first, middle
        while left < middle and right < end:
            if a[left] <= a[right]:
                a[destination] = a[left]
                left += 1
            else:
                a[destination] = a[right]
                right += 1
            destination += 1
        while left < middle:
            a[destination] = a[left]
            destination += 1
            left += 1
        while right < end:
            a[destination] = a[right]
            destination += 1
            right += 1

    def merge_backward(destination, middle, end):
        left, right = middle - 1, end - 1
        while destination > right and right >= middle and left >= 0:
            if a[left] > a[right]:
                a[destination] = a[left]
                left -= 1
            else:
                a[destination] = a[right]
                right -= 1
            destination -= 1
        if left < 0:
            while right >= middle:
                a[destination] = a[right]
                destination -= 1
                right -= 1
        elif right == left:
            while right >= 0:
                a[destination] = a[right]
                destination -= 1
                right -= 1
        elif right < middle:
            while left >= 0:
                a[destination] = a[left]
                destination -= 1
                left -= 1
        return left + 1, right + 1

    def merge_main_prefix(destination, left_end, middle, end):
        left, right = 0, middle
        while left < left_end and right < end:
            if a[left] <= a[right]:
                a[destination] = a[left]
                left += 1
            else:
                a[destination] = a[right]
                right += 1
            destination += 1
        while left < left_end:
            a[destination] = a[left]
            destination += 1
            left += 1

    def merge_external(destination, middle, end):
        left, right = 0, middle
        while left < buffer_length and right < end:
            if buffer[left] <= a[right]:
                a[destination] = buffer[left]
                left += 1
            else:
                a[destination] = a[right]
                right += 1
            destination += 1
        while left < buffer_length:
            a[destination] = buffer[left]
            destination += 1
            left += 1

    ping_pong(0, buffer_length)
    first = buffer_length
    for _ in range(4):
        ping_pong(first, first + fifth)
        first += fifth
    for i in range(buffer_length):
        buffer[i] = a[i]
    two_fifths = 2 * fifth
    first = buffer_length
    for _ in range(2):
        merge_forward(first - buffer_length, first, first + fifth, first + two_fifths)
        first += two_fifths
    left, right = merge_backward(n - 1, two_fifths, 2 * two_fifths)
    if right > 0:
        merge_main_prefix(buffer_length, left, two_fifths, n)
    merge_external(0, buffer_length, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
