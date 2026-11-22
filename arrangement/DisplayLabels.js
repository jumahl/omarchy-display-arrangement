function isBuiltIn(connector) {
    return /^(eDP|LVDS|DSI)(?:-|$)/i.test(connector);
}

function displayModel(screens, connector) {
    for (let i = 0; i < screens.length; i++) {
        if (screens[i].name !== connector) continue;
        const model = String(screens[i].model || "").trim();
        return /^0x[0-9a-f]+$/i.test(model) ? "" : model;
    }
    return "";
}

function displayNumber(rows, connector) {
    const index = rows.findIndex(row => row.name === connector);
    if (index < 0) return 0;

    // Keep the arrangement and save order intact; only promote the label.
    const primary = rows.findIndex(row => isBuiltIn(row.name));
    if (index === primary) return 1;
    return index + (index < primary ? 2 : 1);
}

if (typeof module !== "undefined") module.exports = {displayModel, displayNumber, isBuiltIn};
