with Vec3;

--  Defines the canonical particle state record and the fixed-capacity array
--  that acts as the system's particle buffer throughout a simulation run.
package Particle is

   type Kind_Type is (Proton, Electron, Neutron, Muon, Pion, Custom);

   type State is record
      Position : Vec3.Vector := Vec3.Zero;  --  [m]
      Velocity : Vec3.Vector := Vec3.Zero;  --  [m s⁻¹]
      Force    : Vec3.Vector := Vec3.Zero;  --  net force, reset each step [N]
      Mass     : Long_Float  := 1.0;        --  rest mass [kg]
      Charge   : Long_Float  := 0.0;        --  electric charge [C]
      Kind     : Kind_Type   := Custom;
      ID       : Positive    := 1;
   end record;

   --  Static upper bound; chosen large enough for all built-in scenarios.
   Max_N : constant := 512;

   type Array_Type is array (Positive range 1 .. Max_N) of State;

   --  ── Factory functions ─────────────────────────────────────────────────
   function Make_Proton   (ID : Positive; Pos, Vel : Vec3.Vector) return State;
   function Make_Electron (ID : Positive; Pos, Vel : Vec3.Vector) return State;
   function Make_Neutron  (ID : Positive; Pos, Vel : Vec3.Vector) return State;
   function Make_Muon     (ID : Positive; Pos, Vel : Vec3.Vector) return State;

end Particle;
