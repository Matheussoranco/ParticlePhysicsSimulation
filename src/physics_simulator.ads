with Particle_Types;

package Physics_Simulator is
   -- Configuração básica da simulação
   NUM_PARTICLES : constant := 10;
   TIME_STEP     : constant Float := 0.01;
   NUM_STEPS     : constant := 1000;
   
   -- Tipo para o sistema de partículas
   subtype Simulation_Particles is Particle_Types.Particle_Array (1 .. NUM_PARTICLES);
   
   -- Inicializa e executa a simulação
   procedure Run_Simulation;
   
end Physics_Simulator;