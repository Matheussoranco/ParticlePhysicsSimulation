package body Vector_Math is
   GRAVITATIONAL_CONSTANT : constant Float := 6.67430e-11;
   COULOMB_CONSTANT       : constant Float := 8.9875517873681764e9;

   function Distance (P1, P2 : Real_Vector) return Float is
      Sum : Float := 0.0;
   begin
      for I in P1'Range loop
         Sum := Sum + (P2(I) - P1(I))**2;
      end loop;
      return sqrt(Sum);
   end Distance;

   function Gravitational_Force (P1, P2 : Particle) return Real_Vector is
      R     : constant Real_Vector := P2.Position - P1.Position;
      Dist  : constant Float := Distance (P1.Position, P2.Position);
      Force : constant Float := GRAVITATIONAL_CONSTANT *P1.Mass / (Dist**2);
   begin
      if Dist = 0.0 then
         return (others => 0.0);
      end if;
      return Force * Normalize (R);
   end Gravitational_Force;

   function Eletrostatic_Force (P1, P2 : Particle) return Real_Vector is
      R     : constant Real_Vector := P2.Position - P1.Position;
      Dist  : constant Float := Distance(P1.Position, P2.Position);
      Force : constant Float := COULOMB_CONSTANT * P1.Charge * P2.Charge / (Dist**2);
   begin
      if Dist = 0.0 then
         return (others => 0.0);
      end if;
      return Force * Normalize(R);
   end Eletrostatic_Force;

   function Normalize (V : Real_Vector) return Real_Vector is
      Magnitude : constant Float := sqrt(V(1)**2 + V(2)**2 + V(3)**2);
   begin
      if Magnitude = 0.0 then
         return (others => 0.0);
      end if;
      return (1.0/Magnitude) * V;
   end Normalize;

   function "*" (Scalar : Float; V : Real_Vector) return Real_Vector is
      Result : Real_Vector (V'Range);
   begin
      for I in V'Range loop
         Result(I) := Scalar * V(I);
      end loop;
      return Result;
   end "*";
   
end Vector_Math;