def sort(arr):
    def sort_range(start, end):
        length = end - start
        if length < 2:
            return

        bounds = [start + length * part // 5 for part in range(6)]
        for part in range(5):
            sort_range(bounds[part], bounds[part + 1])

        positions = bounds[:5]
        merged = []
        while len(merged) < length:
            best = None
            for part in range(5):
                if positions[part] < bounds[part + 1] and (
                    best is None or arr[positions[part]] < arr[positions[best]]
                ):
                    best = part
            merged.append(arr[positions[best]])
            positions[best] += 1
        arr[start:end] = merged

    sort_range(0, len(arr))


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
