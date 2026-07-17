def int_pow(base, exponent):
    result = 1
    for _ in range(exponent):
        result *= base
    return result


def get_digit(value, power, radix):
    return (value // int_pow(radix, power)) % radix


def radix_msd(array, low, high, radix, power):
    if low >= high or power < 0:
        return

    buckets = [[] for _ in range(radix)]
    for i in range(low, high):
        buckets[get_digit(array[i], power, radix)].append(array[i])

    index = low
    for bucket in buckets:
        for value in bucket:
            array[index] = value
            index += 1

    start = low
    for bucket in buckets:
        radix_msd(array, start, start + len(bucket), radix, power - 1)
        start += len(bucket)


def sort(arr):
    if len(arr) <= 1:
        return
    radix = 4
    max_value = max(arr)
    highest_power = 0
    probe = radix
    while probe <= max_value:
        highest_power += 1
        probe *= radix
    radix_msd(arr, 0, len(arr), radix, highest_power)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
