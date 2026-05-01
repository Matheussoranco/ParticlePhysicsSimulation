with Particle;
with Forces;
with Integrator;
with Diagnostics;
with Output;
with Vec3;
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

   procedure Run (Cfg : Scenarios.Config) is
      Particles   : Particle.Array_Type;
      N           : Positive;
      Time        : Long_Float := 0.0;
      Initial_E   : Long_Float;
      Total_Steps : Natural;
      Snap        : Diagnostics.Snapshot;
   begin
      --  ── Initialise scenario ───────────────────────────────────────────
      Scenarios.Setup (Cfg, Particles, N);
      Forces.Compute_All (Particles, N, Cfg.B_Field);
      Initial_E   := Diagnostics.Kinetic_Energy   (Particles, N)
                   + Diagnostics.Potential_Energy (Particles, N);
      Total_Steps := Natural (Cfg.Duration / Cfg.DT);

      --  ── Console banner ────────────────────────────────────────────────
      Put_Line (Bar);
      Put_Line ("  " & Scenarios.Name (Cfg.Kind));
      Put_Line (Bar);
      Put_Line ("  N        = " & Img (N));
      Put_Line ("  dt       = " & Img (Cfg.DT)         & " s");
      Put_Line ("  duration = " & Img (Cfg.Duration)   & " s");
      Put_Line ("  steps    = " & Img (Total_Steps));
      Put_Line ("  E0       = " & Img (Initial_E)      & " J");
      Put_Line (Bar);

      --  ── Open CSV files and write t = 0 snapshot ───────────────────────
      Output.Open_Files;
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
