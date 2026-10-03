def sort(arr):
    n = len(arr)
    run = 8
    for start in range(0, n, run):
        end = min(start + run, n)
        for i in range(start + 1, end):
            value = arr[i]
            j = i
            while j > start and arr[j - 1] > value:
                arr[j] = arr[j - 1]
                j -= 1
            arr[j] = value

    scratch = arr.copy()
    width = run
    while width < n:
        for start in range(0, n, 2 * width):
            middle = min(start + width, n)
            end = min(start + 2 * width, n)
            left, right = start, middle
            for out in range(start, end):
                if left < middle and (right >= end or arr[left] < arr[right]):
                    scratch[out] = arr[left]
                    left += 1
                else:
                    scratch[out] = arr[right]
                    right += 1
        arr[:] = scratch
        width *= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
