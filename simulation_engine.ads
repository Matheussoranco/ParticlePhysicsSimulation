with Particle_Types; use Particle_Types;

package Simulation_Engine is
   -- Inicializa um sistema de partículas
   procedure Initialize_System (Particles : in out Particle_Array);
   
   -- Executa um passo da simulação
   procedure Step_Simulation (Particles : in out Particle_Array; Time_Step : Float);
   
   -- Calcula todas as forças atuando em cada partícula
   procedure Calculate_Forces (Particles : Particle_Array; Forces : out Particle_Types.Particle_Array);
   
end Simulation_Engine;