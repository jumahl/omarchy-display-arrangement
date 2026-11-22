const assert = require("node:assert/strict");
const test = require("node:test");
const { displayModel, displayNumber, isBuiltIn } = require("../arrangement/DisplayLabels.js");

test("shows the reported model for the matching connector and leaves missing models blank", () => {
    const screens = [
        { name: "eDP-1", model: "" },
        { name: "HDMI-A-1", model: " HP E24 G5 " },
    ];
    assert.equal(displayModel(screens, "HDMI-A-1"), "HP E24 G5");
    assert.equal(displayModel(screens, "eDP-1"), "");
    assert.equal(displayModel(screens, "DP-1"), "");
});

test("matches the one-based tile number by connector, not screen order", () => {
    const rows = [{ name: "DP-1" }, { name: "eDP-1" }];
    assert.equal(displayNumber(rows, "eDP-1"), 1);
    assert.equal(displayNumber(rows, "DP-1"), 2);
    assert.equal(displayNumber(rows, "HDMI-A-1"), 0);
});

test("keeps desktop numbering in row order when the built-in panel is inactive", () => {
    const rows = [{ name: "DP-1" }, { name: "HDMI-A-1" }];
    assert.equal(displayNumber(rows, "DP-1"), 1);
    assert.equal(displayNumber(rows, "HDMI-A-1"), 2);
    assert.equal(displayNumber(rows, "eDP-1"), 0);
});

test("recognizes internal connectors and hides hexadecimal product codes", () => {
    for (const connector of ["eDP-1", "LVDS-1", "DSI-1"]) assert.equal(isBuiltIn(connector), true);
    assert.equal(isBuiltIn("HDMI-A-1"), false);
    assert.equal(displayModel([{name: "eDP-1", model: "0x15A2"}], "eDP-1"), "");
});
