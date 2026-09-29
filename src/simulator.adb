with Particle;
with Forces;
with Integrator;
with Diagnostics;
with Output;
with Vec3;
with Ada.Calendar;
with Ada.Text_IO; use Ada.Text_IO;

package body Simulator is

   --  Strip the leading space that Ada's 'Image inserts for non-negative values.
   function Img (X : Long_Float) return String is
      S : constant String := Long_Float'Image (X);
   begin
      if S (S'First) = ' ' then return S (S'First + 1 .. S'Last); end if;
      return S;
   end Img;

   function Img (N : Natural) return String is
      S : constant String := Natural'Image (N);
   begin
      if S (S'First) = ' ' then return S (S'First + 1 .. S'Last); end if;
      return S;
   end Img;

   Bar : constant String (1 .. 66) := (others => '-');

   function Scenario_Tag (Kind : Scenarios.Scenario_Kind) return String is
   begin
      case Kind is
         when Scenarios.Hydrogen_Atom     => return "hydrogen";
         when Scenarios.Electron_Positron => return "ep";
         when Scenarios.Cyclotron         => return "cyclotron";
         when Scenarios.Alpha_Scattering  => return "alpha";
         when Scenarios.Random_N_Body     => return "nbody";
      end case;
   end Scenario_Tag;

   function Pad2 (V : Natural) return String is
      S : constant String := Natural'Image (V);
      T : constant String := S (S'First + 1 .. S'Last);  --  strip leading space
   begin
      if T'Length >= 2 then
         return T;
      else
         return "0" & T;
      end if;
   end Pad2;

   function Pad4 (V : Natural) return String is
      S : constant String := Natural'Image (V);
      T : constant String := S (S'First + 1 .. S'Last);
   begin
      if T'Length >= 4 then
         return T;
      elsif T'Length = 3 then
         return "0" & T;
      elsif T'Length = 2 then
         return "00" & T;
      else
         return "000" & T;
      end if;
   end Pad4;

   function Pad6 (V : Natural) return String is
      S : constant String := Natural'Image (V);
      T : constant String := S (S'First + 1 .. S'Last);
   begin
      if T'Length >= 6 then
         return T (T'Last - 5 .. T'Last);
      elsif T'Length = 5 then
         return "0" & T;
      elsif T'Length = 4 then
         return "00" & T;
      elsif T'Length = 3 then
         return "000" & T;
      elsif T'Length = 2 then
         return "0000" & T;
      else
         return "00000" & T;
      end if;
   end Pad6;

   --  Timestamp YYYYMMDD_HHMMSS_UUUUUU (microssegundos da fração de Seconds).
   --  Só HHMMSS (resolução 1 s) colidia quando dois runs começavam no mesmo
   --  segundo e o segundo sobrescrevia trajectory.csv/energy.csv do primeiro.
   function Timestamp return String is
      Now      : constant Ada.Calendar.Time := Ada.Calendar.Clock;
      Year     : Ada.Calendar.Year_Number;
      Month    : Ada.Calendar.Month_Number;
      Day      : Ada.Calendar.Day_Number;
      Seconds  : Ada.Calendar.Day_Duration;
      Whole    : Natural;
      Usecs    : Natural;
      H, M, S  : Natural;
   begin
      Ada.Calendar.Split (Now, Year, Month, Day, Seconds);
      Whole := Natural (Seconds);
      H := Whole / 3600;
      M := (Whole mod 3600) / 60;
      S := Whole mod 60;
      Usecs := Natural (Long_Float (Seconds - Ada.Calendar.Day_Duration (Whole))
                        * 1_000_000.0);
      if Usecs > 999_999 then
         Usecs := 999_999;
      end if;
      return Pad4 (Natural (Year)) & Pad2 (Natural (Month)) & Pad2 (Natural (Day))
        & "_" & Pad2 (H) & Pad2 (M) & Pad2 (S) & "_" & Pad6 (Usecs);
   end Timestamp;

   procedure Run (Cfg : Scenarios.Config) is
      Particles   : Particle.Array_Type;
      N           : Positive;
      Time        : Long_Float := 0.0;
      Initial_E   : Long_Float;
      Total_Steps : Natural;
      Steps_Real  : Long_Float;
      Remainder   : Long_Float;
      Snap        : Diagnostics.Snapshot;
      Prefix      : constant String :=
        Scenario_Tag (Cfg.Kind) & "_" & Timestamp & "_";
   begin
      --  ── Initialise scenario ───────────────────────────────────────────
      Scenarios.Setup (Cfg, Particles, N);
      Forces.Compute_All (Particles, N, Cfg.B_Field);
      Initial_E   := Diagnostics.Kinetic_Energy   (Particles, N)
                   + Diagnostics.Potential_Energy (Particles, N);
      --  Round (not truncate) so Duration/DT = 4000.9 → 4001 steps, and
      --  warn about the leftover fraction instead of silently dropping it.
      Steps_Real  := Cfg.Duration / Cfg.DT;
      Total_Steps := Natural (Steps_Real + 0.5);
      Remainder   := Cfg.Duration - Long_Float (Total_Steps) * Cfg.DT;

      --  ── Console banner ────────────────────────────────────────────────
      Put_Line (Bar);
      Put_Line ("  " & Scenarios.Name (Cfg.Kind));
      Put_Line (Bar);
      Put_Line ("  N        = " & Img (N));
      Put_Line ("  dt       = " & Img (Cfg.DT)         & " s");
      Put_Line ("  duration = " & Img (Cfg.Duration)   & " s");
      Put_Line ("  steps    = " & Img (Total_Steps));
      Put_Line ("  E0       = " & Img (Initial_E)      & " J");
      if abs Remainder > 0.01 * abs Cfg.DT then
         Put_Line ("  NOTE: Duration/DT =" & Img (Steps_Real)
                   & " rounded to" & Natural'Image (Total_Steps)
                   & "; leftover" & Img (Remainder) & " s not simulated.");
      end if;
      if Cfg.B_Field /= Vec3.Zero then
         Put_Line ("  B /= 0: Boris pusher active (exact gyro-rotation);");
         Put_Line ("  fixed DT = T_c/3570 keeps the E-field Verlet error bounded.");
      end if;
      --  NOTE: fixed DT is used deliberately here instead of Adaptive_DT.
      --  Each scenario ships a validated DT tied to its physics (orbital /
      --  cyclotron period) and to Output_Stride, so runs stay reproducible
      --  and energy-drift numbers comparable. Adaptive_DT remains available
      --  for exploratory runs (call it to clamp DT when close encounters
      --  spike |a|), but enabling it silently would change step counts and
      --  break the scenario contracts above.
      Put_Line (Bar);

      --  ── Open CSV files and write t = 0 snapshot ───────────────────────
      --  Prefixed per scenario + timestamp so runs never overwrite each other.
      Put_Line ("  output   = " & Prefix & "{trajectory,energy}.csv");
      Output.Open_Files (Prefix);
      Output.Write_Trajectory (0, 0.0, Particles, N);
      Snap := Diagnostics.Compute (Particles, N, Initial_E);
      Output.Write_Energy (0, 0.0, Snap);

      --  ── Main Velocity Verlet loop ─────────────────────────────────────
      for Step in 1 .. Total_Steps loop
         Integrator.Step (Particles, N, Cfg.DT, Cfg.B_Field);
         Time := Long_Float (Step) * Cfg.DT;

         if Step mod Cfg.Output_Stride = 0 then
            Snap := Diagnostics.Compute (Particles, N, Initial_E);
            Output.Write_Trajectory (Step, Time, Particles, N);
            Output.Write_Energy     (Step, Time, Snap);
            Put_Line ("  step=" & Img (Step)
                      & "  t="     & Img (Time)               & " s"
                      & "  E="     & Img (Snap.Total_Energy)  & " J"
                      & "  drift=" & Img (Snap.Relative_Energy_Drift));
         end if;
      end loop;

      --  ── Final summary ─────────────────────────────────────────────────
      if Total_Steps mod Cfg.Output_Stride /= 0 then
         Snap := Diagnostics.Compute (Particles, N, Initial_E);
         Output.Write_Trajectory (Total_Steps, Time, Particles, N);
         Output.Write_Energy (Total_Steps, Time, Snap);
      end if;
      Output.Close_Files;
      Put_Line (Bar);
      Put_Line ("  Simulation complete.");
      Put_Line ("  Final |delta_E|/|E0| = "
                & Img (Snap.Relative_Energy_Drift));
      Put_Line ("  |p| = "
                & Img (Vec3.Norm (Snap.Linear_Momentum))  & " kg m/s");
      Put_Line ("  |L| = "
                & Img (Vec3.Norm (Snap.Angular_Momentum)) & " kg m2/s");
      Put_Line (Bar);
   end Run;

end Simulator;
