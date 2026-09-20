def sort(arr):
    length = len(arr)
    if length <= 1:
        return

    def block_swap(a, b, size):
        for offset in range(size):
            left, right = a - size + 1 + offset, b - size + 1 + offset
            arr[left], arr[right] = arr[right], arr[left]

    def block_insert(a, b, size):
        while a - size >= b:
            block_swap(a - size, a, size)
            a -= size

    def block_reversal(a, b, size):
        b -= size
        while b > a:
            block_swap(a, b, size)
            a += size
            b -= size

    def block_search(a, b, size, value):
        while a < b:
            middle = a + (((b - a) // size) // 2) * size
            if value < arr[middle]:
                b = middle
            else:
                a = middle + size
        return a

    def order(a, b, size):
        i, j = a, a + size
        while j < b:
            block_insert(j, i, size)
            i += size
            j += 2 * size
        middle = a + (((b - a) // size) // 2) * size
        block_reversal(middle, b, size)

    k = 1
    while 2 * k <= length:
        i = 2 * k - 1
        while i < length:
            if arr[i - k] > arr[i]:
                block_swap(i - k, i, k)
            i += 2 * k
        k *= 2

    while k > 0:
        a = k - 1
        i = a + 2 * k
        g, p = 2, 4
        while i + 2 * k * g - k <= length:
            order(i, i + 2 * k * g - k, k)
            b = a + k * (p - 1)
            i += k * g - k
            j = i
            while j < i + k * g:
                block_insert(j, block_search(a, b, k, arr[j]), k)
                j += k
            i += k * g + k
            g = p - g
            p *= 2
        while i < length:
            block_insert(i, block_search(a, i, k, arr[i]), k)
            i += 2 * k
        k //= 2


if __name__ == "__main__":
    array = [
        34,
        7,
        23,
        90,
        12,
        56,
        3,
        45,
        78,
        21,
        66,
        9,
        50,
        15,
        88,
        40,
        61,
        5,
        33,
        72,
        18,
        95,
        27,
        60,
    ]
    sort(array)
    print(array)
