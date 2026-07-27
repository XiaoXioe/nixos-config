{ lib, ... }:

{
  mkModule = import ./mkModule { inherit lib; };
}
