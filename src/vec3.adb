with Ada.Numerics.Long_Elementary_Functions;
use  Ada.Numerics.Long_Elementary_Functions;

package body Vec3 is

   function "+" (A, B : Vector) return Vector is
   begin
      return (X => A.X + B.X, Y => A.Y + B.Y, Z => A.Z + B.Z);
   end "+";

   function "-" (A, B : Vector) return Vector is
   begin
      return (X => A.X - B.X, Y => A.Y - B.Y, Z => A.Z - B.Z);
   end "-";

   function "-" (A : Vector) return Vector is
   begin
      return (X => -A.X, Y => -A.Y, Z => -A.Z);
   end "-";

   function "*" (S : Long_Float; V : Vector) return Vector is
   begin
      return (X => S * V.X, Y => S * V.Y, Z => S * V.Z);
   end "*";

   function "*" (V : Vector; S : Long_Float) return Vector is
   begin
      return (X => V.X * S, Y => V.Y * S, Z => V.Z * S);
   end "*";

   function "/" (V : Vector; S : Long_Float) return Vector is
   begin
      return (X => V.X / S, Y => V.Y / S, Z => V.Z / S);
   end "/";

   function Dot (A, B : Vector) return Long_Float is
   begin
      return A.X * B.X + A.Y * B.Y + A.Z * B.Z;
   end Dot;

   function Cross (A, B : Vector) return Vector is
   begin
      return (X => A.Y * B.Z - A.Z * B.Y,
              Y => A.Z * B.X - A.X * B.Z,
              Z => A.X * B.Y - A.Y * B.X);
   end Cross;

   function Norm_Sq (V : Vector) return Long_Float is
   begin
      return V.X * V.X + V.Y * V.Y + V.Z * V.Z;
   end Norm_Sq;

   function Norm (V : Vector) return Long_Float is
   begin
      return Sqrt (Norm_Sq (V));
   end Norm;

   function Normalize (V : Vector) return Vector is
      N : constant Long_Float := Norm (V);
   begin
      if N = 0.0 then
         return Zero;
      end if;
      return V / N;
   end Normalize;

end Vec3;
