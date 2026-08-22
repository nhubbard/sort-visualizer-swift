def most_significant_bit(value):
    if value == 0:
        return -1
    bit = 0
    while (value >> (bit + 1)) != 0:
        bit += 1
    return bit


def get_bit(value, bit):
    return (value >> bit) & 1 == 1


def partition(arr, lo, hi, bit):
    i = lo - 1
    j = hi
    while True:
        i += 1
        while i < j and not get_bit(arr[i], bit):
            i += 1
        j -= 1
        while j > i and get_bit(arr[j], bit):
            j -= 1
        if i < j:
            arr[i], arr[j] = arr[j], arr[i]
        else:
            return i


def sort(arr):
    n = len(arr)
    if n <= 1:
        return

    q = most_significant_bit(max(arr))
    if q < 0:
        return

    m = 0
    i = 0
    b = n

    while i < n:
        p = i if b - i < 1 else partition(arr, i, b, q)

        if q == 0:
            m += 2
            while not get_bit(m, q + 1):
                q += 1
            i = b
            while b < n and (arr[b] >> (q + 1)) == (m >> (q + 1)):
                b += 1
        else:
            b = p
            q -= 1


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
