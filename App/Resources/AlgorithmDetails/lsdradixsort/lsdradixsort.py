def sort(arr):
    n = len(arr)
    max_value = max(arr, default=0)
    output = [0] * n
    divisor = 1
    while True:
        counts = [0] * 4
        for value in arr:
            counts[(value // divisor) % 4] += 1
        for digit in range(1, 4):
            counts[digit] += counts[digit - 1]
        for i in range(n - 1, -1, -1):
            digit = (arr[i] // divisor) % 4
            counts[digit] -= 1
            output[counts[digit]] = arr[i]
        for i in range(n):
            arr[i] = output[i]
        if divisor > max_value // 4:
            break
        divisor *= 4


if __name__ == "__main__":
    array = [
        0, 39, 21, 62, 91, 77, 14, 23,
        90, 69, 51, 81, 68, 83, 32, 56,
    ]
    sort(array)
    print(array)
