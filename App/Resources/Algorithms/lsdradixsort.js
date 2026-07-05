// Aux arrays are write-only from the engine's perspective (matching RecordingEngine's read-via-
// tape-only design), so counts/values are tracked in plain JS arrays alongside the recorded
// writeAux calls used purely for visualization.
function sort(engine) {
    const n = engine.count();
    const radix = 4;

    function getDigit(value, place) {
        return Math.floor(value / Math.pow(radix, place)) % radix;
    }

    let maxValue = 0;
    for (let i = 0; i < n; i++) {
        maxValue = Math.max(maxValue, engine.getValue(i));
    }
    let highestPlace = 1;
    while (Math.pow(radix, highestPlace) <= maxValue) {
        highestPlace++;
    }

    const outputHandle = engine.createAuxArray(n);

    for (let place = 0; place < highestPlace; place++) {
        const counts = new Array(radix).fill(0);
        const values = [];
        for (let i = 0; i < n; i++) {
            values.push(engine.getValue(i));
        }
        for (let i = 0; i < n; i++) {
            counts[getDigit(values[i], place)]++;
        }
        for (let d = 1; d < radix; d++) {
            counts[d] += counts[d - 1];
        }
        const output = new Array(n);
        for (let i = n - 1; i >= 0; i--) {
            const digit = getDigit(values[i], place);
            counts[digit]--;
            output[counts[digit]] = values[i];
            engine.writeAux(outputHandle, counts[digit], values[i]);
        }
        for (let i = 0; i < n; i++) {
            engine.setValue(i, output[i]);
        }
    }

    engine.deleteAuxArray(outputHandle);
}
