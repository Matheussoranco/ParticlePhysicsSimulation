with Particle;
with Vec3;

--  Pre-defined physically motivated initial conditions.
--
--  Each scenario bundles:
--    • particle layout (positions, velocities, masses, charges)
--    • a suggested fixed time step DT [s]
--    • total simulation duration [s]
--    • optional uniform external magnetic field B [T]
--    • recommended output stride (write every N steps)
--
--  Scenario physics:
--
--  Hydrogen_Atom      – proton at origin, electron at Bohr radius a₀ with
--                       tangential Bohr velocity v₀ = αc ≈ 2.19 × 10⁶ m/s,
--                       yielding a classical circular orbit of period T₀ ≈ 152 as.
--
--  Electron_Positron  – e⁻ and e⁺ of equal mass orbit their common centre of
--                       mass at separation 2a₀.  Each carries half the reduced-
--                       mass circular velocity v = v₀/2.
--
--  Cyclotron          – single electron in a 1 T uniform axial magnetic field.
--                       Larmor radius r_L = m_e v / eB ≈ 5.7 pm,
--                       cyclotron period T_c = 2π m_e / eB ≈ 35.7 ps.
--
--  Alpha_Scattering   – α particle (A=4, Z=2) approaching a gold nucleus
--                       (A=197, Z=79) with kinetic energy ≈ 6.8 × 10⁻¹³ J
--                       (~4.27 MeV) and impact parameter b = 10 fm.
--                       Closest approach for b=0 is r_min ≈ 53 fm (classical).
--
--  Random_N_Body      – N particles (alternating proton / electron) drawn from
--                       a uniform sphere of radius 50 a₀ with random velocities
--                       up to 0.1 v₀.  Uses a deterministic LCG with fixed seed.
package Scenarios is

   type Scenario_Kind is
     (Hydrogen_Atom,
      Electron_Positron,
      Cyclotron,
      Alpha_Scattering,
      Random_N_Body);

   type Config is record
      Kind          : Scenario_Kind;
      N             : Positive;       --  number of active particles
      DT            : Long_Float;     --  fixed time step [s]
      Duration      : Long_Float;     --  total simulation time [s]
      B_Field       : Vec3.Vector;    --  external magnetic field [T]
      Output_Stride : Positive;       --  write every this many steps
   end record;

   --  Configuration factories
   function Hydrogen_Atom_Config                        return Config;
   function Electron_Positron_Config                    return Config;
   function Cyclotron_Config                            return Config;
   function Alpha_Scattering_Config                     return Config;
   function Random_N_Body_Config (N : Positive := 20)  return Config;

   --  Populate particle buffer and set N_Out to the number of active particles.
   procedure Setup
     (Cfg       :     Config;
      Particles : out Particle.Array_Type;
      N_Out     : out Positive);

   --  Human-readable scenario name for console output.
   function Name (Kind : Scenario_Kind) return String;

end Scenarios;
