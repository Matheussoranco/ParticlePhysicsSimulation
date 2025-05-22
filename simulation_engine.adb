with Vector_Math; use Vector_Math;

package body Simulation_Engine is
   procedure Initialize_System (Particles : in out Particle_Array) is
   begin
      for I in Particles'Range loop
         Particles(I).Position := (Float(I), Float(I mod 3), Float((I+1) mod 2));
         Particles(I).Velocity := (0.0, 0.0, 0.0);

         case Particles(I).Particle_Type is
            when PROTON =>
               Particles(I).Mass := 1.6726219e-27;
               Particles(I).Charge := 1.60217662e-19;
            when ELECTRON =>
               Particles(I).Mass := 9.10938356e-31;
               Particles(I).Charge := -1.60217662e-19;
            when NEUTRON =>
               Particles(I).Mass := 1.674927498e-27;
               Particles(I).Charge := 0.0;
            when others =>
               Particles(I).Mass := 1.0;
               Particles(I).Charge := 0.0;
         end case;
      end loop;
   end Initialize_System;

   procedure Calculate_Forces (Particles : Particle_Array; Forces : out Particle_Types.Particle_Array) is
      Total_Force : Real_Vector (1 .. 3);
   begin
      for I in Particles'Range loop
         Total_Force := (others => 0.0);

         for J in Particles'Range loop
            if I /= J then
               Total_Force := Total_Force + Gravitational_Force (Particles(I), Particles(J));
               Total_Force := Total_Force + Electrostatic_Force (Particle(I), Particles(J));
            end if;
         end loop;

         Forces(I).Position := Particles(I).Position;
         Forces(I).Velocity := Total_Force;
      end loop;
   end Calculate_Forces;

   procedure Step_Simulation (Particles : in out Particle_Array; Time_Step : Float) is
      Forces : Particle_Array (Particles'Range);
      Acceleration : Real_Vector (1 .. 3);
   begin
      Calculate_Forces (Particles, Forces);

      for I in Particles'Range loop
         Acceleration := (1.0/Particles(I).Mass) * Forces.Velocity;

         Particles(I).Velocity := Particles(I).Velocity + Time_step * Acceleration;

         Particles(I).Position := Particles(I).Position + Time_step * Particles(I).Velocity;
      end loop;
   end Step_Simulation;
   
end Simulation_Engine;