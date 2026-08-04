# Audio DSP helpers for PipeWire EQ filter rendering.
{ lib }:
{
  # Render a list of EQ filter attrsets to a PipeWire filter-chain string.
  # Each filter must have: { type, freq, q, gain }.
  # Usage: selfLib.mkEqFilterString [ { type = "Peak"; freq = 100; q = 1.0; gain = -3; } ]
  mkEqFilterString =
    filters:
    lib.concatMapStringsSep "\n                    " (
      f: "{ type = ${f.type}, freq = ${toString f.freq}, q = ${toString f.q}, gain = ${toString f.gain} }"
    ) filters;
}
