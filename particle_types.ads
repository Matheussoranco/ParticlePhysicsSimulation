with Ada.Numerics.Float_Arrays; use Ada.Numerics.Float_Arrays;

package Particle_Types is
   type Particle is record
      Position  : Real_Vector (1 .. 3);  -- Posição 3D (x, y, z)
      Velocity  : Real_Vector (1 .. 3);  -- Velocidade 3D
      Mass      : Float;                -- Massa da partícula
      Charge    : Float;                -- Carga elétrica
      Particle_Type : Integer;          -- Tipo de partícula (próton, elétron, etc.)
   end record;
   
   type Particle_Array is array (Positive range <>) of Particle;
   
   PROTON   : constant Integer := 1;
   ELECTRON : constant Integer := 2;
   NEUTRON  : constant Integer := 3;
   
end Particle_Types;