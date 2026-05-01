with Forces;
with Vec3;      use Vec3;
with Constants; use Constants;
with Ada.Numerics.Long_Elementary_Functions;
use  Ada.Numerics.Long_Elementary_Functions;

package body Integrator is

   procedure Step
     (Particles : in out Particle.Array_Type;
      N         : Positive;
      DT        : Long_Float;
      B_Field   : Vec3.Vector)
   is
      Half_DT : constant Long_Float := 0.5 * DT;
      Accel   : Vec3.Vector;
   begin
      --  Steps 1 & 2: half-kick then drift
      for I in 1 .. N loop
         Accel := Particles (I).Force * (1.0 / Particles (I).Mass);
         Particles (I).Velocity :=
           Particles (I).Velocity + Half_DT * Accel;
         Particles (I).Position :=
           Particles (I).Position + DT * Particles (I).Velocity;
      end loop;

      --  Step 3: re-evaluate forces at updated positions
      Forces.Compute_All (Particles, N, B_Field);

      --  Step 4: second half-kick using new forces
      for I in 1 .. N loop
         Accel := Particles (I).Force * (1.0 / Particles (I).Mass);
         Particles (I).Velocity :=
           Particles (I).Velocity + Half_DT * Accel;
      end loop;
   end Step;

   function Adaptive_DT
     (Particles : Particle.Array_Type;
      N         : Positive) return Long_Float
   is
      Eta      : constant Long_Float := 0.01;
      DT_Floor : constant Long_Float := 1.0E-25;
      DT_Ceil  : constant Long_Float := 1.0E-10;
      A_Mag    : Long_Float;
      DT_I     : Long_Float;
      DT_Best  : Long_Float := DT_Ceil;
   begin
      for I in 1 .. N loop
         A_Mag := Norm (Particles (I).Force) / Particles (I).Mass;
         if A_Mag > 0.0 then
            DT_I := Eta * Sqrt (Epsilon_Soft / A_Mag);
            if DT_I < DT_Best then
               DT_Best := DT_I;
            end if;
         end if;
      end loop;
      return Long_Float'Max (DT_Floor, Long_Float'Min (DT_Best, DT_Ceil));
   end Adaptive_DT;

end Integrator;
