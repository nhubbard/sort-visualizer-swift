def sort(arr):
    n = len(arr)
    ext = list(arr)
    min_value = min(ext)
    max_value = max(ext) + 1

    cur = min_value
    i = 0
    while i < n:
        for j in range(n):
            if ext[j] <= cur:
                arr[i] = ext[j]
                ext[j] = max_value
                i += 1
        cur += 1


array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
print(array)
