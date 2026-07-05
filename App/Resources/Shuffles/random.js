function shuffle(engine) {
    const n = engine.count();
    for (let i = n - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        engine.swap(i, j);
    }
}
