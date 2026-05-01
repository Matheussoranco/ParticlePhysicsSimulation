--  CODATA 2018 fundamental physical constants (SI units throughout).
--  All values are Long_Float (IEEE-754 binary64) for maximum precision.
package Constants is

   --  ── Fundamental constants ─────────────────────────────────────────────
   G        : constant Long_Float := 6.674_30E-11;         --  gravitational constant   [m³ kg⁻¹ s⁻²]
   K_E      : constant Long_Float := 8.987_551_792_3E+09;  --  Coulomb constant         [N m² C⁻²]
   C_Light  : constant Long_Float := 2.997_924_58E+08;     --  speed of light           [m s⁻¹]
   Mu_0     : constant Long_Float := 1.256_637_062_12E-06; --  vacuum permeability      [H m⁻¹]
   Eps_0    : constant Long_Float := 8.854_187_812_8E-12;  --  vacuum permittivity      [F m⁻¹]
   H_Bar    : constant Long_Float := 1.054_571_817E-34;    --  reduced Planck constant  [J s]
   K_B      : constant Long_Float := 1.380_649E-23;        --  Boltzmann constant       [J K⁻¹]

   --  ── Particle rest masses [kg] ──────────────────────────────────────────
   M_Proton   : constant Long_Float := 1.672_621_923_69E-27;
   M_Electron : constant Long_Float := 9.109_383_701_5E-31;
   M_Neutron  : constant Long_Float := 1.674_927_498_04E-27;
   M_Muon     : constant Long_Float := 1.883_531_627E-28;
   M_Pion     : constant Long_Float := 2.406_179_8E-28;    --  charged pion π±

   --  ── Elementary charge [C] ──────────────────────────────────────────────
   Q_E : constant Long_Float := 1.602_176_634E-19;

   --  ── Derived / atomic-scale constants ──────────────────────────────────
   Bohr_Radius    : constant Long_Float := 5.291_772_109_03E-11; --  a₀  [m]
   Fine_Structure : constant Long_Float := 7.297_352_569_3E-03;  --  α  (dimensionless)
   Bohr_Velocity  : constant Long_Float := 2.187_691_262_77E+06; --  v₀ = α c  [m s⁻¹]
   Bohr_Period    : constant Long_Float := 1.519_829_846_23E-16; --  T₀ = 2πa₀/v₀  [s]
   Rydberg_Energy : constant Long_Float := 2.179_872_361E-18;    --  Ry = ½ m_e v₀²  [J]

   --  ── Numerical regularisation ──────────────────────────────────────────
   --  Plummer softening length ε: replaces 1/r with 1/√(r²+ε²).
   --  Default 1 fm — appropriate for atomic / sub-nuclear simulations.
   Epsilon_Soft : constant Long_Float := 1.0E-15; --  [m]

end Constants;
