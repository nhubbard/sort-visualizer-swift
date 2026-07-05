function sort(engine) {
    quicksort(0, engine.count() - 1);

    function quicksort(left, right) {
        if (left >= right) return;
        const pivot = left;
        let i = left;
        let j = right;
        while (i < j) {
            while (engine.compare(pivot, i) && i < j) {
                i++;
            }
            while (!engine.compare(pivot, j)) {
                j--;
            }
            if (i < j) {
                engine.swap(i, j);
            }
        }
        engine.swap(pivot, j);
        quicksort(left, j - 1);
        quicksort(j + 1, right);
    }
}
