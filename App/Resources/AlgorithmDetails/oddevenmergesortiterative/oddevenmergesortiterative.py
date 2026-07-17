def sort(arr):
    n = len(arr)
    p = 1
    while p < n:
        k = p
        while k > 0:
            j = k % p
            while j + k < n:
                for i in range(k):
                    if (i + j) // (p + p) == (i + j + k) // (p + p):
                        if i + j + k < n:
                            if arr[i + j] > arr[i + j + k]:
                                arr[i + j], arr[i + j + k] = arr[i + j + k], arr[i + j]
                j += k + k
            k //= 2
        p += p


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
