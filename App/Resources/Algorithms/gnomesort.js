function sort(engine) {
    const n = engine.count();
    let i = 1;
    while (i < n) {
        if (engine.compare(i, i - 1)) {
            i++;
        } else {
            engine.swap(i, i - 1);
            if (i > 1) {
                i--;
            }
        }
    }
}
