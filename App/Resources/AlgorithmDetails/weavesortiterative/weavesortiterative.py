def sort(arr):
    end = len(arr)

    def comp_swap(a, b):
        if b < end and arr[a] > arr[b]:
            arr[a], arr[b] = arr[b], arr[a]

    padded = 1
    while padded < end:
        padded *= 2

    i = 1
    while i < padded:
        j = 1
        while j <= i:
            k = 0
            while k < padded:
                d = padded // i // 2
                m = 0
                l = padded // j - d
                while l >= padded // j // 2:
                    p = 0
                    while p < d:
                        comp_swap(k + m, k + l + p)
                        p += 1
                        m += 1
                    l -= d
                k += padded // j
            j *= 2
        i *= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
