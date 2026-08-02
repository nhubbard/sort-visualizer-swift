def sort(arr):
    end = len(arr)

    def comp_swap(a, b):
        if b < end and arr[a] > arr[b]:
            arr[a], arr[b] = arr[b], arr[a]

    def circle(pos, ln, gap):
        if ln < 2:
            return
        i = 0
        while 2 * i < (ln - 1) * gap:
            comp_swap(pos + i, pos + (ln - 1) * gap - i)
            i += gap
        circle(pos, ln // 2, gap)
        if pos + ln * gap // 2 < end:
            circle(pos + ln * gap // 2, ln // 2, gap)

    def weave_circle(pos, ln, gap):
        if ln < 2:
            return
        weave_circle(pos, ln // 2, 2 * gap)
        weave_circle(pos + gap, ln // 2, 2 * gap)
        circle(pos, ln, gap)

    padded = 1
    while padded < end:
        padded *= 2

    weave_circle(0, padded, 1)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
