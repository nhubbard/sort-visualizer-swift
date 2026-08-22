def sort(arr):
    n = len(arr)
    if n == 0:
        return arr
    max_value = max(arr)
    transpose = [0] * max_value

    for i in range(n):
        value = arr[i]
        for j in range(value):
            transpose[j] += 1

    for i in range(n):
        total = 0
        for j in range(max_value):
            if transpose[j] > 0:
                total += 1
        arr[n - i - 1] = total
        for j in range(max_value):
            transpose[j] -= 1
    return arr


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
