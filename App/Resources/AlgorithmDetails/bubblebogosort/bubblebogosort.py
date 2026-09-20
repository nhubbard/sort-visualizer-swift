def sort(a):
    n = len(a)
    if n < 2:
        return
    swapped = True
    while swapped:
        swapped = False
        for i in range(n - 1):
            if a[i] > a[i + 1]:
                a[i], a[i + 1] = a[i + 1], a[i]
                swapped = True


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23]
    sort(array)
    print(array)
