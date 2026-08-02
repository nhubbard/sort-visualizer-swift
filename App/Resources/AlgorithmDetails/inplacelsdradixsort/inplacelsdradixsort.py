def int_pow(base, exponent):
    result = 1
    for _ in range(exponent):
        result *= base
    return result


def get_digit(value, power, radix):
    return (value // int_pow(radix, power)) % radix


def multi_swap(arr, pos, to):
    if to > pos:
        for k in range(pos, to):
            arr[k], arr[k + 1] = arr[k + 1], arr[k]
    elif to < pos:
        for k in range(pos, to, -1):
            arr[k], arr[k - 1] = arr[k - 1], arr[k]


def sort(arr):
    n = len(arr)
    if n == 0:
        return arr
    radix = 4
    max_value = max(arr)

    max_power = 0
    probe = radix
    while probe <= max_value:
        max_power += 1
        probe *= radix

    vregs = [0] * (radix - 1)

    for power in range(max_power + 1):
        for i in range(len(vregs)):
            vregs[i] = n - 1

        pos = 0
        for _ in range(n):
            digit = get_digit(arr[pos], power, radix)
            if digit == 0:
                pos += 1
            else:
                to = vregs[digit - 1]
                multi_swap(arr, pos, to)
                for j in range(digit - 1, 0, -1):
                    vregs[j - 1] -= 1
    return arr


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
