def most_significant_bit(value):
    if value == 0:
        return -1
    bit = 0
    while (value >> (bit + 1)) != 0:
        bit += 1
    return bit


def partition(arr, p, r, bit):
    i = p - 1
    j = r + 1
    while True:
        i += 1
        while i <= r and ((arr[i] >> bit) & 1) == 0:
            i += 1
        j -= 1
        while j >= p and ((arr[j] >> bit) & 1) == 1:
            j -= 1
        if i < j:
            arr[i], arr[j] = arr[j], arr[i]
        else:
            return j


def binary_quick_sort_recursive(arr, p, r, bit):
    if p < r and bit >= 0:
        q = partition(arr, p, r, bit)
        binary_quick_sort_recursive(arr, p, q, bit - 1)
        binary_quick_sort_recursive(arr, q + 1, r, bit - 1)


def sort(arr):
    n = len(arr)
    max_value = max(arr)
    bit = most_significant_bit(max_value)
    binary_quick_sort_recursive(arr, 0, n - 1, bit)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
