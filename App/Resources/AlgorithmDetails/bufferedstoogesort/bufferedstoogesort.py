def sort(arr):
    n = len(arr)

    def compare(x, y):
        if arr[x] > arr[y]:
            return 1
        if arr[x] < arr[y]:
            return -1
        return 0

    def swap(x, y):
        arr[x], arr[y] = arr[y], arr[x]

    def wrapper(start, stop):
        if stop - start > 1:
            if stop - start == 2 and compare(start, stop - 1) == 1:
                swap(start, stop - 1)
            if stop - start > 2:
                width = stop - start
                third = (width + 2) // 3 + start
                two_third = (2 * width + 2) // 3 + start
                if two_third - third < third:
                    two_third -= 1
                if (width - 2) % 3 == 0:
                    two_third -= 1

                wrapper(third, two_third)
                wrapper(two_third, stop)

                left = third
                right = two_third
                buffer_start = start
                while left < two_third and right < stop:
                    if compare(left, right) == 1:
                        swap(buffer_start, right)
                        right += 1
                    else:
                        swap(buffer_start, left)
                        left += 1
                    buffer_start += 1
                while right < stop:
                    swap(buffer_start, right)
                    right += 1
                    buffer_start += 1

                wrapper(two_third, stop)

                left = two_third - 1
                right = stop - 1
                while right > left >= start:
                    if compare(left, right) == 1:
                        for i in range(left, right):
                            swap(i, i + 1)
                        left -= 1
                    right -= 1

    wrapper(0, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
