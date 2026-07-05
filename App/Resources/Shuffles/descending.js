function shuffle(engine) {
    const n = engine.count();
    for (let i = 0; i < Math.floor(n / 2); i++) {
        engine.swap(i, n - 1 - i);
    }
}
