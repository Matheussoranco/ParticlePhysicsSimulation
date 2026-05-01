with Constants; use Constants;
with Vec3;      use Vec3;
with Ada.Numerics.Long_Elementary_Functions;
use  Ada.Numerics.Long_Elementary_Functions;

package body Forces is

   function Pair_Force (Pi, Pj : Particle.State) return Vec3.Vector is
      R_Ij    : constant Vec3.Vector := Pj.Position - Pi.Position;
      R_Sq    : constant Long_Float  := Dot (R_Ij, R_Ij) + Epsilon_Soft * Epsilon_Soft;
      R_Cb    : constant Long_Float  := R_Sq * Sqrt (R_Sq);  --  (|r|² + ε²)^(3/2)
      F_Grav  : constant Long_Float  := G   * Pi.Mass   * Pj.Mass   / R_Cb;
      F_EM    : constant Long_Float  := K_E * Pi.Charge * Pj.Charge / R_Cb;
   begin
      --  Gravity is along +R_Ij (attractive).
      --  Coulomb is along −R_Ij when like-charge (repulsive), +R_Ij when unlike.
      return (F_Grav - F_EM) * R_Ij;
   end Pair_Force;

   procedure Compute_All
     (Particles : in out Particle.Array_Type;
      N         : Positive;
      B_Field   : Vec3.Vector)
   is
      F_Ij : Vec3.Vector;
   begin
      --  Zero accumulated forces
      for I in 1 .. N loop
         Particles (I).Force := Vec3.Zero;
      end loop;

      --  Pairwise interactions — Newton's 3rd law: compute once, apply twice
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            F_Ij := Pair_Force (Particles (I), Particles (J));
            Particles (I).Force := Particles (I).Force + F_Ij;
            Particles (J).Force := Particles (J).Force - F_Ij;
         end loop;
      end loop;

      --  Lorentz term: F_mag = q (v × B)
      for I in 1 .. N loop
         if Particles (I).Charge /= 0.0 then
            Particles (I).Force :=
              Particles (I).Force
              + Particles (I).Charge
                * Cross (Particles (I).Velocity, B_Field);
         end if;
      end loop;
   end Compute_All;

end Forces;
