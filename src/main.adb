with Scenarios;
with Simulator;
with Ada.Text_IO;      use Ada.Text_IO;
with Ada.Command_Line; use Ada.Command_Line;

--  Entry point.  Usage:
--    particle_sim [scenario] [options]
--
--  scenario:
--    hydrogen   – hydrogen atom (default)
--    ep         – electron-positron pair orbit
--    cyclotron  – single electron in uniform B field
--    alpha      – Rutherford alpha scattering off gold
--    nbody [N]  – random N-body (optional particle count, default 20)
procedure Main is

   procedure Print_Usage is
   begin
      Put_Line ("Usage: particle_sim [hydrogen|ep|cyclotron|alpha|nbody [N]]");
      Put_Line ("  hydrogen   Classical H atom: 1p + 1e- at Bohr radius");
      Put_Line ("  ep         e-/e+ symmetric orbit at 2a0 separation");
      Put_Line ("  cyclotron  Electron in 1T uniform axial magnetic field");
      Put_Line ("  alpha      Rutherford alpha scattering off gold nucleus");
      Put_Line ("  nbody N    Random N-body mixed plasma (default N=20)");
   end Print_Usage;

   Cfg : Scenarios.Config;
   N   : Positive := 20;

begin
   if Argument_Count = 0 then
      Cfg := Scenarios.Hydrogen_Atom_Config;

   elsif Argument (1) = "hydrogen" then
      Cfg := Scenarios.Hydrogen_Atom_Config;

   elsif Argument (1) = "ep" then
      Cfg := Scenarios.Electron_Positron_Config;

   elsif Argument (1) = "cyclotron" then
      Cfg := Scenarios.Cyclotron_Config;

   elsif Argument (1) = "alpha" then
      Cfg := Scenarios.Alpha_Scattering_Config;

   elsif Argument (1) = "nbody" then
      if Argument_Count >= 2 then
         N := Positive'Value (Argument (2));
      end if;
      Cfg := Scenarios.Random_N_Body_Config (N);

   else
      Put_Line ("Unknown scenario: " & Argument (1));
      Print_Usage;
      Set_Exit_Status (Failure);
      return;
   end if;

   Simulator.Run (Cfg);
end Main;
