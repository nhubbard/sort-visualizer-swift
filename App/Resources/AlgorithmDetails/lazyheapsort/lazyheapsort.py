def sort(arr):
    n = len(arr)

    def max_to_front(a, b):
        best = a
        i = a + 1
        while i < b:
            if arr[i] > arr[best]:
                best = i
            i += 1
        arr[best], arr[a] = arr[a], arr[best]

    s = int((n - 1) ** 0.5) + 1

    i = 0
    while i < n:
        max_to_front(i, min(i + s, n))
        i += s

    j = n
    while j > 0:
        best = 0
        k = best + s
        while k < j:
            if arr[k] >= arr[best]:
                best = k
            k += s
        j -= 1
        arr[best], arr[j] = arr[j], arr[best]
        max_to_front(best, min(best + s, j))


array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
print(array)
