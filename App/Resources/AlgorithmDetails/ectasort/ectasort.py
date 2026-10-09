def sort(arr):
    n = len(arr)
    if n < 2:
        return

    run = n
    while run >= 32:
        run = (run + 1) // 2

    def insertion(start, end):
        for i in range(start + 1, end):
            value = arr[i]
            lo, hi = start, i
            while lo < hi:
                mid = (lo + hi) // 2
                if arr[mid] > value:
                    hi = mid
                else:
                    lo = mid + 1
            for j in range(i, lo, -1):
                arr[j] = arr[j - 1]
            arr[lo] = value

    if n <= 32:
        insertion(0, n)
        return

    half = n // 2
    buffer = arr[half : 2 * half]

    def merge_backward(start, middle, end, workspace):
        count = end - middle
        arr[workspace : workspace + count] = arr[middle:end]
        left, right, output = middle - 1, workspace + count - 1, end - 1
        while left >= start and right >= workspace:
            if arr[left] > arr[right]:
                arr[output] = arr[left]
                left -= 1
            else:
                arr[output] = arr[right]
                right -= 1
            output -= 1
        while right >= workspace:
            arr[output] = arr[right]
            right -= 1
            output -= 1

    def sort_segment(start, end, workspace):
        for lower in range(start, end, run):
            insertion(lower, min(lower + run, end))
        width = run
        while width < end - start:
            for lower in range(start, end, 2 * width):
                middle = min(lower + width, end)
                upper = min(lower + 2 * width, end)
                if middle < upper:
                    merge_backward(lower, middle, upper, workspace)
            width *= 2

    sort_segment(0, half, half)
    arr[half : 2 * half] = buffer
    buffer = arr[:half]
    sort_segment(half, n, 0)

    left, right, output = 0, half, 0
    while left < half and right < n:
        if buffer[left] <= arr[right]:
            arr[output] = buffer[left]
            left += 1
        else:
            arr[output] = arr[right]
            right += 1
        output += 1
    while left < half:
        arr[output] = buffer[left]
        left += 1
        output += 1


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
