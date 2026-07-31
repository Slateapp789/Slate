import { unitSearchFrom, withUnitLabel } from "./address_unit.ts";

function assertEquals(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("extracts a flat label and building query", () => {
  assertEquals(unitSearchFrom("Flat 28 Wedgewood Court"), {
    unitLabel: "Flat 28",
    buildingInput: "Wedgewood Court",
  });
});

Deno.test("normalises apt labels", () => {
  assertEquals(unitSearchFrom("apt 3B, 12 High Street"), {
    unitLabel: "Apartment 3B",
    buildingInput: "12 High Street",
  });
});

Deno.test("does not reinterpret ordinary numbered streets", () => {
  assertEquals(unitSearchFrom("28 Flat Lane"), null);
});

Deno.test("adds a unit label once", () => {
  assertEquals(
    withUnitLabel("Wedgewood Court, London", "Flat 28"),
    "Flat 28, Wedgewood Court, London",
  );
  assertEquals(
    withUnitLabel("Flat 28, Wedgewood Court, London", "Flat 28"),
    "Flat 28, Wedgewood Court, London",
  );
});
