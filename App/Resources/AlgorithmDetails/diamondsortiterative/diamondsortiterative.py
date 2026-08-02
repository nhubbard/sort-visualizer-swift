def sort(arr):
    n = len(arr)

    def comp_swap(a, b):
        if arr[a] > arr[b]:
            arr[a], arr[b] = arr[b], arr[a]

    p = 1
    while p < n:
        p *= 2

    m = 4
    while m <= p:
        for k in range(m // 2):
            cnt = k if k <= m // 4 else m // 2 - k
            j = 0
            while j < n:
                if j + cnt + 1 < n:
                    i = j + cnt
                    while i + 1 < min(n, j + m - cnt):
                        comp_swap(i, i + 1)
                        i += 2
                j += m
        m *= 2
    m //= 2
    for k in range(m // 2 + 1):
        i = k
        while i + 1 < min(n, m - k):
            comp_swap(i, i + 1)
            i += 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
