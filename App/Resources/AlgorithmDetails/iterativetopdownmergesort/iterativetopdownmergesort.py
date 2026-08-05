def merge(array, low, mid, high):
    left = array[low:mid]
    right = array[mid:high]
    i = j = 0
    k = low
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            array[k] = left[i]
            i = i + 1
        else:
            array[k] = right[j]
            j = j + 1
        k = k + 1
    while i < len(left):
        array[k] = left[i]
        i = i + 1
        k = k + 1
    while j < len(right):
        array[k] = right[j]
        j = j + 1
        k = k + 1


def sort(arr):
    n = len(arr)
    subarray_count = 1
    while subarray_count < n:
        subarray_count = subarray_count * 2

    while subarray_count > 1:
        i = 0
        while i < subarray_count:
            low = n * i // subarray_count
            mid = n * (i + 1) // subarray_count
            high = n * (i + 2) // subarray_count
            merge(arr, low, mid, high)
            i = i + 2
        subarray_count = subarray_count // 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
