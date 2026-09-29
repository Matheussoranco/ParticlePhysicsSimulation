with Constants; use Constants;
with Vec3;      use Vec3;

package body Scenarios is

   --  ─── Minimal LCG for deterministic pseudo-random initial conditions ───
   --  xorshift32 variant: period 2³²−1, zero-free.
   type U32 is mod 2 ** 32;

   procedure LCG_Next (S : in out U32) is
   begin
      S := S xor (S * 2 ** 13);
      S := S xor (S / 2 ** 17);
      S := S xor (S * 2 ** 5);
   end LCG_Next;

    --  Returns value in (−1, 1)
    function Rand_Sym (S : in out U32) return Long_Float is
    begin
       LCG_Next (S);
       return Long_Float (S) / Long_Float (U32'Last) * 2.0 - 1.0;
    end Rand_Sym;

    --  Rejection sampling gives a uniform point inside the unit sphere.
    --  Each component still comes from the deterministic scenario seed.
    function Random_In_Unit_Ball (S : in out U32) return Vec3.Vector is
       Candidate : Vec3.Vector;
    begin
       loop
          Candidate := (X => Rand_Sym (S),
                        Y => Rand_Sym (S),
                        Z => Rand_Sym (S));
          exit when Vec3.Norm_Sq (Candidate) <= 1.0;
       end loop;
       return Candidate;
    end Random_In_Unit_Ball;

    --  Configurable LCG seed (default preserves historic runs).
    Current_Seed : U32 := 20240101;

    procedure Set_Random_Seed (Seed : Natural) is
    begin
       if Seed = 0 then
          Current_Seed := 1;
       else
          Current_Seed := U32 (Seed mod 2 ** 32);
          if Current_Seed = 0 then
             Current_Seed := 1;
          end if;
       end if;
    end Set_Random_Seed;

   --  ─── Config factories ─────────────────────────────────────────────────

   function Hydrogen_Atom_Config return Config is
   begin
       return (Kind          => Hydrogen_Atom,
               N             => 2,
               DT            => 5.0E-19,   --  ~1/304 of orbital period T₀
               Duration      => 2.0E-15,   --  ~13 orbits (T₀ ≈ 152 as)
               B_Field       => Vec3.Zero,
               Output_Stride => 200);
   end Hydrogen_Atom_Config;

   function Electron_Positron_Config return Config is
   begin
      return (Kind          => Electron_Positron,
              N             => 2,
              DT            => 5.0E-19,
              Duration      => 1.0E-15,
              B_Field       => Vec3.Zero,
              Output_Stride => 200);
   end Electron_Positron_Config;

   function Cyclotron_Config return Config is
   begin
      return (Kind          => Cyclotron,
              N             => 1,
              --  T_c ≈ 35.7 ps; DT = T_c/3570 ≈ 1e-14 s
              DT            => 1.0E-14,
              Duration      => 3.57E-10,  --  ~10 cyclotron orbits
              B_Field       => (X => 0.0, Y => 0.0, Z => 1.0),  --  1 T along z
              Output_Stride => 100);
   end Cyclotron_Config;

   function Alpha_Scattering_Config return Config is
   begin
      return (Kind          => Alpha_Scattering,
              N             => 2,
              DT            => 5.0E-23,   --  sub-zeptosecond steps
              Duration      => 3.0E-19,   --  fly-by window ~ 300 as
              B_Field       => Vec3.Zero,
              Output_Stride => 50);
   end Alpha_Scattering_Config;

    function Random_N_Body_Config (N : Positive := 20) return Config is
    begin
       if N > Particle.Max_N then
          raise Constraint_Error with
            "Random_N_Body_Config: N =" & Positive'Image (N)
            & " exceeds Particle.Max_N =" & Positive'Image (Particle.Max_N);
       end if;
       return (Kind          => Random_N_Body,
               N             => N,
               DT            => 1.0E-18,
               Duration      => 1.0E-14,
               B_Field       => Vec3.Zero,
               Output_Stride => 500);
    end Random_N_Body_Config;

   --  ─── Setup routines ───────────────────────────────────────────────────

   procedure Setup_Hydrogen_Atom (Particles : out Particle.Array_Type) is
      --  Electron circular orbit at a₀; proton essentially fixed (M_p/M_e ≈ 1836)
      V_E : constant Long_Float := Bohr_Velocity;   --  v₀ = αc
   begin
      Particles (1) := Particle.Make_Proton
        (ID  => 1,
         Pos => Vec3.Zero,
         Vel => Vec3.Zero);
      Particles (2) := Particle.Make_Electron
        (ID  => 2,
         Pos => (X => Bohr_Radius, Y => 0.0, Z => 0.0),
         Vel => (X => 0.0,         Y => V_E,  Z => 0.0));
   end Setup_Hydrogen_Atom;

   procedure Setup_Electron_Positron (Particles : out Particle.Array_Type) is
      --  Separation d = 2 a₀; reduced-mass circular orbit.
      --  F = K_E q²/d²,  μ = M_e/2,  μ v²/(d/2) = F  ⟹  v = v₀/2
      D   : constant Long_Float := 2.0 * Bohr_Radius;
      V_C : constant Long_Float := Bohr_Velocity / 2.0;
   begin
      --  Electron at (−a₀, 0, 0), orbiting CCW: velocity (0, −v, 0)
      Particles (1) := Particle.Make_Electron
        (ID  => 1,
         Pos => (X => -(D / 2.0), Y => 0.0, Z => 0.0),
         Vel => (X => 0.0,        Y => -V_C, Z => 0.0));
      --  Positron at (+a₀, 0, 0), velocity (0, +v, 0)
      Particles (2) :=
        (Position => (X => D / 2.0, Y => 0.0, Z => 0.0),
         Velocity => (X => 0.0,     Y => V_C,  Z => 0.0),
         Force    => Vec3.Zero,
         Mass     => M_Electron,
         Charge   => Q_E,           --  positron: +e
         Kind     => Particle.Custom,
         ID       => 2);
   end Setup_Electron_Positron;

   procedure Setup_Cyclotron (Particles : out Particle.Array_Type) is
      --  v₀ = 1e6 m/s, B₀ = 1 T along z.
      --  r_L = m_e v₀ / (e B₀) ≈ 5.69 pm
      V0  : constant Long_Float := 1.0E+06;
      R_L : constant Long_Float := M_Electron * V0 / (Q_E * 1.0);
   begin
      Particles (1) := Particle.Make_Electron
        (ID  => 1,
         Pos => (X => R_L,  Y => 0.0, Z => 0.0),
         Vel => (X => 0.0,  Y => V0,  Z => 0.0));
   end Setup_Cyclotron;

   procedure Setup_Alpha_Scattering (Particles : out Particle.Array_Type) is
      --  Gold nucleus at origin; α-particle approaches from −x with b = 10 fm.
      --  KE_α ≈ 4.27 MeV → v ≈ 1.43e7 m/s
      Alpha_Mass   : constant Long_Float := 4.0   * M_Proton;
      Alpha_Charge : constant Long_Float := 2.0   * Q_E;
      Gold_Mass    : constant Long_Float := 197.0 * M_Proton;
      Gold_Charge  : constant Long_Float := 79.0  * Q_E;
      V_Alpha      : constant Long_Float := 1.43E+07;    --  [m/s]
      B_Impact     : constant Long_Float := 1.0E-14;     --  b = 10 fm
      X_Start      : constant Long_Float := -3.0E-13;    --  300 fm upstream
   begin
      --  Gold nucleus: essentially stationary (ratio M_Au/M_α ≈ 49)
      Particles (1) :=
        (Position => Vec3.Zero,
         Velocity => Vec3.Zero,
         Force    => Vec3.Zero,
         Mass     => Gold_Mass,
         Charge   => Gold_Charge,
         Kind     => Particle.Custom,
         ID       => 1);
      --  Alpha particle approaching in +x direction
      Particles (2) :=
        (Position => (X => X_Start,  Y => B_Impact, Z => 0.0),
         Velocity => (X => V_Alpha,  Y => 0.0,      Z => 0.0),
         Force    => Vec3.Zero,
         Mass     => Alpha_Mass,
         Charge   => Alpha_Charge,
         Kind     => Particle.Custom,
         ID       => 2);
   end Setup_Alpha_Scattering;

    procedure Setup_Random_N_Body
      (Particles : out Particle.Array_Type;
       N         :     Positive)
    is
       Seed   : U32     := Current_Seed;
      R_Max  : constant Long_Float := 50.0 * Bohr_Radius;
       V_Max  : constant Long_Float := 0.1  * Bohr_Velocity;
       Kind   : Particle.Kind_Type;
       Mass   : Long_Float;
       Charge : Long_Float;
    begin
       if N > Particle.Max_N then
          raise Constraint_Error with
            "Setup_Random_N_Body: N =" & Positive'Image (N)
            & " exceeds Particle.Max_N =" & Positive'Image (Particle.Max_N);
       end if;
       for I in 1 .. N loop
         --  Alternate proton / electron
         if I mod 2 = 1 then
            Kind   := Particle.Proton;
            Mass   := M_Proton;
            Charge := Q_E;
         else
            Kind   := Particle.Electron;
            Mass   := M_Electron;
            Charge := -Q_E;
         end if;

         Particles (I) :=
           (Position => R_Max * Random_In_Unit_Ball (Seed),
            Velocity => V_Max * Random_In_Unit_Ball (Seed),
            Force    => Vec3.Zero,
            Mass     => Mass,
            Charge   => Charge,
            Kind     => Kind,
            ID       => I);
      end loop;
   end Setup_Random_N_Body;

   --  ─── Public dispatch ──────────────────────────────────────────────────

   procedure Setup
     (Cfg       :     Config;
      Particles : out Particle.Array_Type;
      N_Out     : out Positive)
   is
   begin
      Particles := (others => (Position => Vec3.Zero,
                               Velocity => Vec3.Zero,
                               Force    => Vec3.Zero,
                               Mass     => 1.0,
                               Charge   => 0.0,
                               Kind     => Particle.Custom,
                               ID       => 1));
      N_Out := Cfg.N;

      case Cfg.Kind is
         when Hydrogen_Atom     => Setup_Hydrogen_Atom      (Particles);
         when Electron_Positron => Setup_Electron_Positron  (Particles);
         when Cyclotron         => Setup_Cyclotron          (Particles);
         when Alpha_Scattering  => Setup_Alpha_Scattering   (Particles);
         when Random_N_Body     => Setup_Random_N_Body      (Particles, Cfg.N);
      end case;
   end Setup;

   function Name (Kind : Scenario_Kind) return String is
   begin
      case Kind is
         when Hydrogen_Atom     => return "Hydrogen Atom (1p + 1e-)";
         when Electron_Positron => return "Electron-Positron Pair Orbit";
         when Cyclotron         => return "Cyclotron (e- in 1T axial B)";
         when Alpha_Scattering  => return "Rutherford Alpha Scattering off Au";
         when Random_N_Body     => return "Random N-Body Mixed Plasma";
      end case;
   end Name;

end Scenarios;
