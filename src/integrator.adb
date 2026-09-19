with Forces;
with Vec3;      use Vec3;
with Constants; use Constants;
with Ada.Numerics.Long_Elementary_Functions;
use  Ada.Numerics.Long_Elementary_Functions;

package body Integrator is

   --  Boris (1970) magnetic rotation: exact gyro-rotation of V by the
   --  angle implied by B over DT, preserving |V_perp| to round-off.
   --    t = (q Δt / 2m) B ;  s = 2t / (1 + |t|²)
   --    v' = v⁻ + v⁻ × t ;  v⁺ = v⁻ + v' × s
   procedure Boris_Rotate
     (V       : in out Vec3.Vector;
      Charge  : Long_Float;
      Mass    : Long_Float;
      DT      : Long_Float;
      B_Field : Vec3.Vector)
   is
      Factor : constant Long_Float := Charge * DT / (2.0 * Mass);
      T      : constant Vec3.Vector := Factor * B_Field;
      T_Sq   : constant Long_Float := Norm_Sq (T);
      S      : constant Vec3.Vector := (2.0 / (1.0 + T_Sq)) * T;
      Vp     : Vec3.Vector;
   begin
      if Charge = 0.0 or else (T_Sq = 0.0) then
         return;
      end if;
      Vp := V + Cross (V, T);
      V  := V + Cross (Vp, S);
   end Boris_Rotate;

   function Has_B (B : Vec3.Vector) return Boolean is
   begin
      return B /= Vec3.Zero;
   end Has_B;

   procedure Step_Verlet_No_B
     (Particles : in out Particle.Array_Type;
      N         : Positive;
      DT        : Long_Float)
   is
      Half_DT : constant Long_Float := 0.5 * DT;
      Accel   : Vec3.Vector;
   begin
      for I in 1 .. N loop
         Accel := Particles (I).Force * (1.0 / Particles (I).Mass);
         Particles (I).Velocity :=
           Particles (I).Velocity + Half_DT * Accel;
         Particles (I).Position :=
           Particles (I).Position + DT * Particles (I).Velocity;
      end loop;

      Forces.Compute_Electric (Particles, N);

      for I in 1 .. N loop
         Accel := Particles (I).Force * (1.0 / Particles (I).Mass);
         Particles (I).Velocity :=
           Particles (I).Velocity + Half_DT * Accel;
      end loop;
   end Step_Verlet_No_B;

   --  Boris pusher with electric/gravity Verlet kicks:
   --    (1) half E-kick at x(t), rotate by B  → v(+)
   --    (2) drift x(t+Δt) = x(t) + Δt · v(+)
   --    (3) re-evaluate E/gravity at x(t+Δt)
   --    (4) second half E-kick → v(t+Δt)
   procedure Step_Boris
     (Particles : in out Particle.Array_Type;
      N         : Positive;
      DT        : Long_Float;
      B_Field   : Vec3.Vector)
   is
      Half_DT : constant Long_Float := 0.5 * DT;
      Accel   : Vec3.Vector;
      V_Minus : Vec3.Vector;
   begin
      --  Step 1: half E-kick + rotation, then drift at v(+).
      for I in 1 .. N loop
         Accel   := Particles (I).Force * (1.0 / Particles (I).Mass);
         V_Minus := Particles (I).Velocity + Half_DT * Accel;
         Boris_Rotate
           (V_Minus, Particles (I).Charge, Particles (I).Mass, DT, B_Field);
         Particles (I).Velocity := V_Minus;
         Particles (I).Position :=
           Particles (I).Position + DT * V_Minus;
      end loop;

      --  Step 3: re-evaluate electric/gravity forces (no Lorentz term;
      --  magnetism is handled by the rotation above).
      Forces.Compute_Electric (Particles, N);

      --  Step 4: second half E-kick using new forces.
      for I in 1 .. N loop
         Accel := Particles (I).Force * (1.0 / Particles (I).Mass);
         Particles (I).Velocity :=
           Particles (I).Velocity + Half_DT * Accel;
      end loop;
   end Step_Boris;

   procedure Step
     (Particles : in out Particle.Array_Type;
      N         : Positive;
      DT        : Long_Float;
      B_Field   : Vec3.Vector)
   is
   begin
      if Has_B (B_Field) then
         --  Ensure the cached Force holds the electric part before the
         --  first half-kick (callers may have used Compute_All).
         Forces.Compute_Electric (Particles, N);
         Step_Boris (Particles, N, DT, B_Field);
      else
         --  Caller pre-computed forces via Compute_All (= electric when
         --  B = 0); keep the classic symplectic path.
         Step_Verlet_No_B (Particles, N, DT);
      end if;
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
         --  Guard: non-positive mass is unphysical; skip instead of
         --  dividing by zero (caller validates, this is defense in depth).
         if Particles (I).Mass <= 0.0 then
            null;
         else
         A_Mag := Norm (Particles (I).Force) / Particles (I).Mass;
         if A_Mag > 0.0 then
            DT_I := Eta * Sqrt (Epsilon_Soft / A_Mag);
            if DT_I < DT_Best then
               DT_Best := DT_I;
            end if;
         end if;
         end if;
      end loop;
      return Long_Float'Max (DT_Floor, Long_Float'Min (DT_Best, DT_Ceil));
   end Adaptive_DT;

end Integrator;
