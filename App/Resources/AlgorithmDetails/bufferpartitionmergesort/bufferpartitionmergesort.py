"""ArrayV median-merge: partition and use the larger side as a swap buffer."""


def insertion(a, first, end):
    for i in range(first + 1, end):
        j = i
        while j > first and a[j - 1] > a[j]:
            a[j - 1], a[j] = a[j], a[j - 1]
            j -= 1


def binary_insertion(a, first, end):
    for i in range(first + 1, end):
        value = a[i]
        low, high = first, i
        while low < high:
            middle = low + (high - low) // 2
            if value < a[middle]:
                high = middle
            else:
                low = middle + 1
        for j in range(i, low, -1):
            a[j] = a[j - 1]
        a[low] = value


def median_three(a, first, end):
    middle = first + (end - 1 - first) // 2
    if a[first] > a[middle]:
        a[first], a[middle] = a[middle], a[first]
    if a[middle] > a[end - 1]:
        a[middle], a[end - 1] = a[end - 1], a[middle]
        if a[first] > a[middle]:
            return
    a[first], a[middle] = a[middle], a[first]


def median_medians(a, first, end):
    alternate = True
    while end - first > 1:
        write = i = first
        while i + 10 <= end:
            insertion(a, i, i + 5)
            a[write], a[i + 2] = a[i + 2], a[write]
            write += 1
            i += 5
        if i < end:
            insertion(a, i, end)
            sample = i + (end - int(alternate) - i) // 2
            a[write], a[sample] = a[sample], a[write]
            write += 1
            if (end - i) % 2 == 0:
                alternate = not alternate
        end = write


def shift_backward(a, first, middle, end):
    while middle > first:
        middle -= 1
        end -= 1
        a[middle], a[end] = a[end], a[middle]


def multi_swap(a, first, second, length):
    for offset in range(length):
        a[first + offset], a[second + offset] = a[second + offset], a[first + offset]


def rotate(a, first, middle, end):
    left, right = middle - first, end - middle
    while left > 0 and right > 0:
        if right < left:
            multi_swap(a, middle - right, middle, right)
            end -= right
            middle -= right
            left -= right
        else:
            multi_swap(a, first, middle, left)
            first += left
            middle += left
            right -= left


def in_place_merge(a, first, middle, end):
    left, right = first, middle
    while left < right and right < end:
        if a[left] > a[right]:
            upper = right + 1
            while upper < end and a[left] > a[upper]:
                upper += 1
            rotate(a, left, right, upper)
            left += upper - right
            right = upper
        else:
            left += 1


def partition(a, first, end):
    left, right = first, end
    while True:
        left += 1
        while left < right and a[left] > a[first]:
            left += 1
        right -= 1
        while right >= left and a[right] < a[first]:
            right -= 1
        if left >= right:
            return right
        a[left], a[right] = a[right], a[left]


def quick_select(a, lower, upper, target):
    bad_split = used_medians = False
    target_upper = (target + upper + 1) // 2
    while True:
        if bad_split:
            median_medians(a, lower, upper)
            used_medians = True
        else:
            median_three(a, lower, upper)
        pivot = partition(a, lower, upper)
        a[lower], a[pivot] = a[pivot], a[lower]
        left, right = max(1, pivot - lower), max(1, upper - pivot - 1)
        bad_split = not used_medians and (left // right >= 16 or right // left >= 16)
        if target <= pivot < target_upper:
            return pivot
        if pivot < target:
            lower = pivot + 1
        else:
            upper = pivot


def merge(a, first, middle, end, destination):
    i, j = first, middle
    while i < middle and j < end:
        if a[i] <= a[j]:
            a[destination], a[i] = a[i], a[destination]
            i += 1
        else:
            a[destination], a[j] = a[j], a[destination]
            j += 1
        destination += 1
    while i < middle:
        a[destination], a[i] = a[i], a[destination]
        i += 1
        destination += 1
    while j < end:
        a[destination], a[j] = a[j], a[destination]
        j += 1
        destination += 1


def merge_sort(a, first, end, buffer):
    length = end - first
    if length <= 1:
        return
    width = length
    while width >= 32:
        width = (width + 3) // 4
    i = first
    while i + width <= end:
        binary_insertion(a, i, i + width)
        i += width
    binary_insertion(a, i, end)
    while width < length:
        destination, i = buffer, first
        while i + 2 * width <= end:
            merge(a, i, i + width, i + 2 * width, destination)
            i += 2 * width
            destination += 2 * width
        if i + width < end:
            merge(a, i, i + width, end, destination)
        else:
            while i < end:
                a[i], a[destination] = a[destination], a[i]
                i += 1
                destination += 1
        width *= 2

        destination, i = first, buffer
        while i + 2 * width <= buffer + length:
            merge(a, i, i + width, i + 2 * width, destination)
            i += 2 * width
            destination += 2 * width
        if i + width < buffer + length:
            merge(a, i, i + width, buffer + length, destination)
        else:
            while i < buffer + length:
                a[i], a[destination] = a[destination], a[i]
                i += 1
                destination += 1
        width *= 2


def merge_forward(a, destination, first, middle, end):
    left, right = first, middle
    while left < middle and right < end:
        if a[left] <= a[right]:
            a[destination], a[left] = a[left], a[destination]
            left += 1
        else:
            a[destination], a[right] = a[right], a[destination]
            right += 1
        destination += 1
    return left if left < middle else right


def sort(a):
    n = len(a)
    if n <= 1:
        return
    first, middle = 0, (n + 1) // 2
    minimum = __import__("math").isqrt(n)
    merge_sort(a, middle, n, first)
    while middle - first > minimum:
        selected = quick_select(a, first, middle, (first + middle + 1) // 2)
        merge_sort(a, selected, middle, first)
        buffer_length = selected - first
        merge_end = min(selected + buffer_length, n)
        selected = merge_forward(a, first, selected, middle, merge_end)
        while selected < middle:
            shift_backward(a, selected, middle, merge_end)
            selected = merge_end - (middle - selected)
            first = selected - buffer_length
            middle = merge_end
            if middle == n:
                break
            merge_end = min(merge_end + buffer_length, n)
            selected = merge_forward(a, first, selected, middle, merge_end)
        middle = selected
        first = selected - buffer_length
    binary_insertion(a, first, middle)
    in_place_merge(a, first, middle, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
