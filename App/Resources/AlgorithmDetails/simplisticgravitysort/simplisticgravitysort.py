def sort(arr):
    n = len(arr)
    if n == 0:
        return arr

    min_value = min(arr)
    max_value = max(arr)
    aux_length = max_value - min_value
    aux = [0] * aux_length

    def transfer_to(index):
        pointer = 0
        while arr[index] > min_value:
            arr[index] -= 1
            aux[pointer] += 1
            pointer += 1

    def transfer_from(index):
        pointer = 0
        while pointer < aux_length and aux[pointer] != 0:
            arr[index] += 1
            aux[pointer] -= 1
            pointer += 1

    for i in range(n):
        transfer_to(i)
    for i in range(n - 1, -1, -1):
        transfer_from(i)

    return arr


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
