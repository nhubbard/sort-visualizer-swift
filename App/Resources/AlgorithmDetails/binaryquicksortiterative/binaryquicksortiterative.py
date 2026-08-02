from collections import deque


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


def sort(arr):
    n = len(arr)
    max_value = max(arr)
    bit = most_significant_bit(max_value)

    tasks = deque([(0, n - 1, bit)])
    while tasks:
        p, r, b = tasks.popleft()
        if p < r and b >= 0:
            q = partition(arr, p, r, b)
            tasks.append((p, q, b - 1))
            tasks.append((q + 1, r, b - 1))


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
