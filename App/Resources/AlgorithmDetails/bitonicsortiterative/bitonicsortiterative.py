def sort(arr):
    n = len(arr)
    k = 2
    while k < 2 * n:
        m = ((n + k - 1) // k) % 2 != 0
        j = k // 2
        while j > 0:
            i = 0
            while i < n:
                l = i ^ j
                if l > i and l < n:
                    ascending = ((i & k) == 0) == m
                    if (ascending and arr[i] > arr[l]) or (
                        not ascending and arr[i] < arr[l]
                    ):
                        arr[i], arr[l] = arr[l], arr[i]
                i += 1
            j //= 2
        k *= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
