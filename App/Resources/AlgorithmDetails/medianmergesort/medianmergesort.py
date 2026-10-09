def sort(arr):
    n = len(arr)
    scratch = [0] * n

    def merge_sort(start, end):
        if end - start < 2:
            return
        middle = (start + end) // 2
        merge_sort(start, middle)
        merge_sort(middle, end)
        left, right, dest = start, middle, start
        while left < middle and right < end:
            if arr[left] <= arr[right]:
                scratch[dest] = arr[left]
                left += 1
            else:
                scratch[dest] = arr[right]
                right += 1
            dest += 1
        while left < middle:
            scratch[dest] = arr[left]
            left += 1
            dest += 1
        while right < end:
            scratch[dest] = arr[right]
            right += 1
            dest += 1
        arr[start:end] = scratch[start:end]

    start, end = 0, n
    while end - start > 16:
        pivot = sorted((arr[start], arr[(start + end - 1) // 2], arr[end - 1]))[1]
        left, right = start, end - 1
        while left <= right:
            while left <= right and arr[left] < pivot:
                left += 1
            while left <= right and arr[right] > pivot:
                right -= 1
            if left <= right:
                arr[left], arr[right] = arr[right], arr[left]
                left += 1
                right -= 1
        if left == start or left == end:
            merge_sort(start, end)
            return
        if left - start <= end - left:
            merge_sort(start, left)
            start = left
        else:
            merge_sort(left, end)
            end = left

    for i in range(start + 1, end):
        value = arr[i]
        j = i
        while j > start and arr[j - 1] > value:
            arr[j] = arr[j - 1]
            j -= 1
        arr[j] = value


if __name__ == "__main__":
    array = [
        0,
        39,
        21,
        62,
        91,
        77,
        14,
        23,
        90,
        69,
        51,
        81,
        68,
        83,
        32,
        56,
        10,
        2,
        95,
        46,
        21,
        74,
        6,
        38,
    ]
    sort(array)
    print(array)
