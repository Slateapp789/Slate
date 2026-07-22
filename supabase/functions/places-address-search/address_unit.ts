export type UnitSearch = {
  unitLabel: string;
  buildingInput: string;
};

export function unitSearchFrom(input: string): UnitSearch | null {
  const match = input.match(
    /^(flat|apartment|apt|unit|suite)\s+([a-z0-9][a-z0-9/-]*)\s*,?\s+(.+)$/i,
  );
  if (!match) return null;

  const kind = match[1].toLowerCase();
  const label = kind === "apt"
    ? "Apartment"
    : `${kind[0].toUpperCase()}${kind.slice(1)}`;
  const buildingInput = match[3].trim().slice(0, 240);
  if (buildingInput.length < 3) return null;

  return {
    unitLabel: `${label} ${match[2]}`,
    buildingInput,
  };
}

export function withUnitLabel(value: string, unitLabel: string) {
  if (!unitLabel || value.toLowerCase().includes(unitLabel.toLowerCase())) {
    return value;
  }
  return `${unitLabel}, ${value}`;
}
