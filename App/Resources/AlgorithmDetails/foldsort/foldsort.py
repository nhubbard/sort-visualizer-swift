def sort(arr):
    n = len(arr)

    def comp_swap(a, b, end):
        if b < end and arr[a] > arr[b]:
            arr[a], arr[b] = arr[b], arr[a]

    def halver(low, high, end):
        while low < high:
            comp_swap(low, high, end)
            low += 1
            high -= 1

    ceil_log = 1
    while (1 << ceil_log) < n:
        ceil_log += 1

    end = n
    size2 = 1 << ceil_log

    k = size2 >> 1
    while k > 0:
        i = size2
        while i >= k:
            j = 0
            while j < end:
                halver(j, j + i - 1, end)
                j += i
            i >>= 1
        k >>= 1


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
