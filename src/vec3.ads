--  Immutable three-dimensional Euclidean vector over Long_Float.
--  Operators are value-semantic; no mutation, no aliasing issues.
package Vec3 is

   type Vector is record
      X : Long_Float := 0.0;
      Y : Long_Float := 0.0;
      Z : Long_Float := 0.0;
   end record;

   Zero : constant Vector := (X => 0.0, Y => 0.0, Z => 0.0);

   --  ── Linear algebra ────────────────────────────────────────────────────
   function "+" (A, B : Vector) return Vector;
   function "-" (A, B : Vector) return Vector;
   function "-" (A    : Vector) return Vector;          --  unary negation
   function "*" (S : Long_Float; V : Vector) return Vector;
   function "*" (V : Vector; S : Long_Float) return Vector;
   function "/" (V : Vector; S : Long_Float) return Vector;

   --  ── Products ──────────────────────────────────────────────────────────
   function Dot   (A, B : Vector) return Long_Float;   --  A · B
   function Cross (A, B : Vector) return Vector;       --  A × B

   --  ── Norms ─────────────────────────────────────────────────────────────
   function Norm_Sq  (V : Vector) return Long_Float;   --  |V|²
   function Norm     (V : Vector) return Long_Float;   --  |V|
   function Normalize (V : Vector) return Vector;      --  V / |V|  (0 → Zero)

end Vec3;
