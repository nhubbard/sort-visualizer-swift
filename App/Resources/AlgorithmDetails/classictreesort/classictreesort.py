def traverse(arr, temp, lower, upper, state, r):
    if lower[r] != 0:
        traverse(arr, temp, lower, upper, state, lower[r])
    temp[state[0]] = arr[r]
    state[0] += 1
    if upper[r] != 0:
        traverse(arr, temp, lower, upper, state, upper[r])


def sort(arr):
    n = len(arr)
    if n <= 1:
        return

    lower = [0] * n
    upper = [0] * n

    for i in range(1, n):
        c = 0
        while True:
            next_arr = lower if arr[i] < arr[c] else upper
            if next_arr[c] == 0:
                next_arr[c] = i
                break
            else:
                c = next_arr[c]

    temp = [0] * n
    traverse(arr, temp, lower, upper, [0], 0)
    for i in range(n):
        arr[i] = temp[i]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
