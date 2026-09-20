def sort(arr):
    n = len(arr)
    if n < 2:
        return

    def reverse(a, b):
        b -= 1
        while a < b:
            arr[a], arr[b] = arr[b], arr[a]
            a += 1
            b -= 1

    def rotate(a, m, b):
        reverse(a, m)
        reverse(m, b)
        reverse(a, b)

    def lower(a, b, value):
        while a < b:
            mid = (a + b) // 2
            if value <= arr[mid]:
                b = mid
            else:
                a = mid + 1
        return a

    def upper(a, b, value):
        while a < b:
            mid = (a + b) // 2
            if value < arr[mid]:
                b = mid
            else:
                a = mid + 1
        return a

    def left_gallop(a, b, value):
        step = 1
        while a - 1 + step < b and value > arr[a - 1 + step]:
            step *= 2
        return lower(a + step // 2, min(b, a - 1 + step), value)

    def right_gallop(a, b, value):
        step = 1
        while b - step >= a and value < arr[b - step]:
            step *= 2
        return upper(max(a, b - step + 1), b - step // 2, value)

    def insertion(a, b):
        for i in range(a + 1, b):
            value = arr[i]
            position = upper(a, i, value)
            for j in range(i, position, -1):
                arr[j] = arr[j - 1]
            arr[position] = value

    def forward(a, m, b):
        i, j = a, m
        while i < j < b:
            if arr[i] > arr[j]:
                k = left_gallop(j + 1, b, arr[i])
                rotate(i, j, k)
                i += k - j
                j = k
            else:
                i += 1

    def backward(a, m, b):
        i, j = m - 1, b - 1
        while j > i >= a:
            if arr[i] > arr[j]:
                k = right_gallop(a, i, arr[j])
                rotate(k, i + 1, j + 1)
                j -= i + 1 - k
                i = k - 1
            else:
                j -= 1

    def merge(a, m, b):
        if b - m < m - a:
            backward(a, m, b)
        else:
            forward(a, m, b)

    def fragmented(a, m, b, size):
        i = a + (m - a) % size
        while i < m:
            j = left_gallop(m, b, arr[i])
            rotate(i, m, j)
            length = j - m
            boundary = i
            i += length
            m += length
            merge(a, boundary, i)
            a = i
            i += size
        merge(max(a, i - size), i, b)

    if n <= 16:
        insertion(0, n)
        return
    size = 1
    while size**3 < n:
        size += 1
    group = size * size
    for i in range(n % size, n + 1, size):
        insertion(max(0, i - size), i)
    i, j = n - size, n
    while i > 0:
        if j - i == group:
            j -= group
            i -= size
        forward(max(0, i - size), i, j)
        i -= size
    for i in range(n - group, 0, -group):
        fragmented(max(0, i - group), i, n, size)


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
