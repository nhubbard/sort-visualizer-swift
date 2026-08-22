def double_insertion_sort(array, start, end):
    left = start + (end - start) // 2 - 1
    right = left + 1
    if array[left] > array[right]:
        array[left], array[right] = array[right], array[left]
    left -= 1
    right += 1

    while left >= start and right < end:
        if array[left] > array[right]:
            left_item = array[right]
            right_item = array[left]

            pos = left + 1
            while pos <= right and array[pos] <= left_item:
                array[pos - 1] = array[pos]
                pos += 1
            array[pos - 1] = left_item

            pos = right - 1
            while pos >= left and array[pos] >= right_item:
                array[pos + 1] = array[pos]
                pos -= 1
            array[pos + 1] = right_item
        else:
            left_item = array[left]
            right_item = array[right]

            pos = left + 1
            while array[pos] < left_item:
                array[pos - 1] = array[pos]
                pos += 1
            array[pos - 1] = left_item

            pos = right - 1
            while array[pos] > right_item:
                array[pos + 1] = array[pos]
                pos -= 1
            array[pos + 1] = right_item

        left -= 1
        right += 1

    if right < end:
        pos = right - 1
        current = array[right]
        while pos >= start and array[pos] > current:
            array[pos + 1] = array[pos]
            pos -= 1
        array[pos + 1] = current


def sort(arr):
    if len(arr) > 1:
        double_insertion_sort(arr, 0, len(arr))


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
