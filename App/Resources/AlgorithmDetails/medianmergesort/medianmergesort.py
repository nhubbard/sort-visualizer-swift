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


def partition(a, first, end, pivot):
    i, j = first - 1, end
    while True:
        i += 1
        while i < j and a[i] < a[pivot]:
            i += 1
        j -= 1
        while j >= i and a[j] > a[pivot]:
            j -= 1
        if i >= j:
            return j
        a[i], a[j] = a[j], a[i]


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


def sort(a):
    first, end = 0, len(a)
    bad_split = used_medians = False
    while end - first > 16:
        if bad_split:
            median_medians(a, first, end)
            used_medians = True
        else:
            median_three(a, first, end)
        pivot = partition(a, first + 1, end, first)
        a[first], a[pivot] = a[pivot], a[first]
        left, right = pivot - first, end - pivot - 1
        bad_split = not used_medians and (
            left == 0 or right == 0 or
            (left > 0 and right > 0 and
             (left // right >= 16 or right // left >= 16))
        )
        if left <= right:
            merge_sort(a, first, pivot, pivot + 1)
            first = pivot + 1
        else:
            merge_sort(a, pivot + 1, end, 2 * pivot + 1 - end)
            end = pivot
    binary_insertion(a, first, end)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
             68, 83, 32, 56, 10, 2, 95, 46, 21, 74, 6, 38]
    sort(array)
    print(array)
