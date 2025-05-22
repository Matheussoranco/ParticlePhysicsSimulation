with Ada.Numerics.Float_Arrays; use Ada.Numerics.Float_Arrays;

package Vector_Math is
   function Distance (P1, P2 : Real_Vector) return Float;
   
   function Gravitational_Force (P1, P2 : Particle) return Real_Vector;
   
   function Electrostatic_Force (P1, P2 : Particle) return Real_Vector;
   
   function Normalize (V : Real_Vector) return Real_Vector;
   
   function "*" (Scalar : Float; V : Real_Vector) return Real_Vector;
   
end Vector_Math;