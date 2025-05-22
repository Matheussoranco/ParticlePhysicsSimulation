with Physics_Simulator;
with Simulation_Engine; use Simulation_Engine;
with Ada.Text_IO; use Ada.Text_IO;
with Particle_Types; use Particle_Types;

package body Physics_Simulator is
   procedure Run_Simulation is
      Particles : Simulation_Particles;
   begin
      for I in Particles'Range loop
         Particles(I).Particle_Type := (I mod 3) + 1;
      end loop;

      Initialize_System (Particles);

      Put_Line("Starting simulation with" & Particles 'Length'Image & " particles");

      for Step in 1 .. NUM_STEPS loop
         Step_Simulation (Particles, TIME_STEP);

         if Step mod 100 = 0 then
            Put_Line("Step" & Step'Image);
            for I in 1 .. Integer'Min(3, Particles'Length) loop
               Put_Line("Particle" & I'Image & ": Position = (" &
                        Particles(I).Position(1)'Image & "," &
                        Particles(I).Position(2)'Image & "," &
                        Particles(I).Position(3)'Image & ")");
            end loop;
         end if;
      end loop;

      Put_Line("Simulation Completed");
   end Run_Simulation;
   
end Physics_Simulator;