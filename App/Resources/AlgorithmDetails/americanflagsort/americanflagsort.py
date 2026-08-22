def digit_at(value, divisor, radix):
    return (value // divisor) % radix


def flag_sort(arr, low, high, divisor, radix):
    if high - low <= 1:
        return

    count = [0] * radix
    offset = [0] * radix

    for i in range(low, high):
        count[digit_at(arr[i], divisor, radix)] += 1

    offset[0] = low
    for d in range(1, radix):
        offset[d] = offset[d - 1] + count[d - 1]
    bucket_start = list(offset)

    for d in range(radix):
        while count[d] > 0:
            origin = offset[d]
            frm = origin
            value = arr[frm]

            while True:
                digit = digit_at(value, divisor, radix)
                dest = offset[digit]
                offset[digit] += 1
                count[digit] -= 1
                displaced = arr[dest]
                arr[dest] = value
                value = displaced
                frm = dest
                if frm == origin:
                    break

    if divisor > 1:
        for d in range(radix):
            begin = bucket_start[d]
            end = offset[d]
            if end - begin > 1:
                flag_sort(arr, begin, end, divisor // radix, radix)


def sort(arr):
    n = len(arr)
    if n <= 1:
        return

    radix = 10
    max_value = max(arr)

    divisor = 1
    while max_value // divisor >= radix:
        divisor *= radix

    flag_sort(arr, 0, n, divisor, radix)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
