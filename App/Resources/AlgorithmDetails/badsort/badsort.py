def sort(array):
    current_len = len(array)
    for i in range(current_len):
        shortest = i

        j = i
        while j < current_len:
            is_shortest = True
            k = j + 1
            while k < current_len:
                if array[j] > array[k]:
                    is_shortest = False
                    break
                k += 1

            if is_shortest:
                shortest = j
                break
            j += 1

        array[i], array[shortest] = array[shortest], array[i]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
