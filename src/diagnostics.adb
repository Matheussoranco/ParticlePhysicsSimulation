with Constants; use Constants;
with Vec3;      use Vec3;
with Ada.Numerics.Long_Elementary_Functions;
use  Ada.Numerics.Long_Elementary_Functions;

package body Diagnostics is

   function Kinetic_Energy (Particles : Particle.Array_Type; N : Positive) return Long_Float is
      KE : Long_Float := 0.0;
   begin
      for I in 1 .. N loop
         KE := KE + 0.5 * Particles (I).Mass * Norm_Sq (Particles (I).Velocity);
      end loop;
      return KE;
   end Kinetic_Energy;

   function Potential_Energy (Particles : Particle.Array_Type; N : Positive) return Long_Float is
      PE    : Long_Float    := 0.0;
      R_Vec : Vec3.Vector;
      R_Soft : Long_Float;
   begin
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            R_Vec  := Particles (J).Position - Particles (I).Position;
            R_Soft := Sqrt (Dot (R_Vec, R_Vec) + Epsilon_Soft * Epsilon_Soft);
            PE := PE
                  - G   * Particles (I).Mass   * Particles (J).Mass   / R_Soft
                  + K_E * Particles (I).Charge * Particles (J).Charge / R_Soft;
         end loop;
      end loop;
      return PE;
   end Potential_Energy;

   function Compute
     (Particles      : Particle.Array_Type;
      N              : Positive;
      Initial_Energy : Long_Float) return Snapshot
   is
      S     : Snapshot;
      R_COM : Vec3.Vector := Vec3.Zero;
      M_Tot : Long_Float  := 0.0;
   begin
      S.Kinetic_Energy   := Kinetic_Energy   (Particles, N);
      S.Potential_Energy := Potential_Energy (Particles, N);
      S.Total_Energy     := S.Kinetic_Energy + S.Potential_Energy;

      for I in 1 .. N loop
         S.Linear_Momentum  :=
           S.Linear_Momentum
           + Particles (I).Mass * Particles (I).Velocity;
         S.Angular_Momentum :=
           S.Angular_Momentum
           + Particles (I).Mass
             * Cross (Particles (I).Position, Particles (I).Velocity);
         R_COM := R_COM + Particles (I).Mass * Particles (I).Position;
         M_Tot := M_Tot + Particles (I).Mass;
      end loop;

      if M_Tot > 0.0 then
         S.COM_Position := R_COM / M_Tot;
      end if;

      if Initial_Energy /= 0.0 then
         S.Relative_Energy_Drift :=
           abs (S.Total_Energy - Initial_Energy) / abs (Initial_Energy);
      end if;

      return S;
   end Compute;

end Diagnostics;
