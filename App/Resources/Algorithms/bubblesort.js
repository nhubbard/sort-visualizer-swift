function sort(engine) {
    const n = engine.count();
    for (let i = 1; i < n; i++) {
        for (let j = 0; j < n - i; j++) {
            if (engine.compare(j, j + 1)) {
                engine.swap(j, j + 1);
            }
        }
    }
}
