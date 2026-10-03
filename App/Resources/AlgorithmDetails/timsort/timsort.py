def min_run_length(n):
    remainder = 0
    while n >= 32:
        remainder |= n & 1
        n >>= 1
    return n + remainder


def count_run(values, start):
    end = start + 1
    if end == len(values):
        return 1
    descending = values[end] < values[start]
    end += 1
    if descending:
        while end < len(values) and values[end] < values[end - 1]:
            end += 1
        values[start:end] = reversed(values[start:end])
    else:
        while end < len(values) and values[end] >= values[end - 1]:
            end += 1
    return end - start


def binary_insertion(values, start, end, sorted_end):
    for index in range(sorted_end, end):
        pivot = values[index]
        low, high = start, index
        while low < high:
            middle = (low + high) // 2
            if values[middle] <= pivot:
                low = middle + 1
            else:
                high = middle
        values[low + 1 : index + 1] = values[low:index]
        values[low] = pivot


def merge(values, runs, index):
    start, left_length = runs[index]
    right_start, right_length = runs[index + 1]
    left = values[start:right_start]
    right = values[right_start : right_start + right_length]
    i = j = 0
    destination = start
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            values[destination] = left[i]
            i += 1
        else:
            values[destination] = right[j]
            j += 1
        destination += 1
    values[destination : destination + len(left) - i] = left[i:]
    destination += len(left) - i
    values[destination : destination + len(right) - j] = right[j:]
    runs[index : index + 2] = [(start, left_length + right_length)]


def sort(values):
    n = len(values)
    if n < 2:
        return
    minimum = min_run_length(n)
    runs = []
    cursor = 0
    while cursor < n:
        length = count_run(values, cursor)
        forced = min(minimum, n - cursor)
        if length < forced:
            binary_insertion(values, cursor, cursor + forced, cursor + length)
            length = forced
        runs.append((cursor, length))
        while len(runs) > 1:
            index = len(runs) - 2
            if (
                index >= 1 and runs[index - 1][1] <= runs[index][1] + runs[index + 1][1]
            ) or (
                index >= 2 and runs[index - 2][1] <= runs[index][1] + runs[index - 1][1]
            ):
                if runs[index - 1][1] < runs[index + 1][1]:
                    index -= 1
            elif runs[index][1] > runs[index + 1][1]:
                break
            merge(values, runs, index)
        cursor += length
    while len(runs) > 1:
        index = len(runs) - 2
        if index > 0 and runs[index - 1][1] < runs[index + 1][1]:
            index -= 1
        merge(values, runs, index)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
