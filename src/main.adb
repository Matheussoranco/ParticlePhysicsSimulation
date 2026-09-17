with Scenarios;
with Simulator;
with Particle;
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
--
--  options:
--    --seed N | --seed=N   – LCG seed for Random_N_Body (default 20240101)
procedure Main is

   procedure Print_Usage is
   begin
      Put_Line ("Usage: particle_sim [hydrogen|ep|cyclotron|alpha|nbody [N]] [--seed N]");
      Put_Line ("  hydrogen   Classical H atom: 1p + 1e- at Bohr radius");
      Put_Line ("  ep         e-/e+ symmetric orbit at 2a0 separation");
      Put_Line ("  cyclotron  Electron in 1T uniform axial magnetic field");
      Put_Line ("  alpha      Rutherford alpha scattering off gold nucleus");
      Put_Line ("  nbody N    Random N-body mixed plasma (default N=20, max"
                & Positive'Image (Particle.Max_N) & ")");
      Put_Line ("  --seed N   LCG seed for nbody (default 20240101); also --seed=N");
   end Print_Usage;

   function Starts_With (S, Prefix : String) return Boolean is
   begin
      return S'Length >= Prefix'Length
        and then S (S'First .. S'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   --  Scan argv for --seed N / --seed=N; apply via Scenarios.Set_Random_Seed.
   procedure Parse_Seed_Option is
      Seed_Val : Natural := 20240101;
      Found    : Boolean := False;
   begin
      for I in 1 .. Argument_Count loop
         declare
            A : constant String := Argument (I);
         begin
            if A = "--seed" then
               if I < Argument_Count then
                  Seed_Val := Natural'Value (Argument (I + 1));
                  Found := True;
               else
                  Put_Line ("Missing value for --seed.");
                  Print_Usage;
                  Set_Exit_Status (Failure);
                  raise Constraint_Error with "missing --seed value";
               end if;
            elsif Starts_With (A, "--seed=") then
               Seed_Val := Natural'Value
                 (A (A'First + 7 .. A'Last));
               Found := True;
            end if;
         end;
      end loop;
      if Found then
         Scenarios.Set_Random_Seed (Seed_Val);
      end if;
   exception
      when Constraint_Error =>
         Put_Line ("Invalid --seed value (expected natural number).");
         Print_Usage;
         Set_Exit_Status (Failure);
         raise;
   end Parse_Seed_Option;

   function Is_Seed_Flag_Or_Value (Idx : Positive) return Boolean is
   begin
      if Idx > Argument_Count then
         return False;
      end if;
      declare
         A : constant String := Argument (Idx);
      begin
         if A = "--seed" or else Starts_With (A, "--seed=") then
            return True;
         end if;
         --  Value following a bare "--seed" belongs to the flag.
         if Idx > 1 and then Argument (Idx - 1) = "--seed" then
            return True;
         end if;
         return False;
      end;
   end Is_Seed_Flag_Or_Value;

   Cfg : Scenarios.Config;
   N   : Positive := 20;

begin
   Parse_Seed_Option;

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
      --  Optional N is Argument(2) unless it is a --seed flag/value.
      if Argument_Count >= 2 and then not Is_Seed_Flag_Or_Value (2) then
         begin
            N := Positive'Value (Argument (2));
         exception
            when Constraint_Error =>
               Put_Line ("Invalid particle count: " & Argument (2));
               Put_Line ("Expected a Positive integer 1 .."
                         & Positive'Image (Particle.Max_N) & ".");
               Print_Usage;
               Set_Exit_Status (Failure);
               return;
         end;
      end if;
      begin
         Cfg := Scenarios.Random_N_Body_Config (N);
      exception
         when Constraint_Error =>
            Put_Line ("Invalid N for nbody (max"
                      & Positive'Image (Particle.Max_N) & ").");
            Print_Usage;
            Set_Exit_Status (Failure);
            return;
      end;

   elsif Starts_With (Argument (1), "--seed") then
      Put_Line ("No scenario given; defaulting to hydrogen.");
      Cfg := Scenarios.Hydrogen_Atom_Config;

   else
      Put_Line ("Unknown scenario: " & Argument (1));
      Print_Usage;
      Set_Exit_Status (Failure);
      return;
   end if;

   Simulator.Run (Cfg);

exception
   when Constraint_Error =>
      --  Catches Positive'Value / config errors escaping the handlers above.
      if Exit_Status = Success then
         Put_Line ("Invalid numeric argument.");
         Print_Usage;
         Set_Exit_Status (Failure);
      end if;
end Main;
