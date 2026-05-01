with Scenarios;

--  Top-level simulation orchestrator.
--  Drives the Störmer-Verlet time loop, emits diagnostic output, and
--  writes CSV trajectory / energy files.
package Simulator is

   --  Run the simulation described by Cfg from t = 0 to Cfg.Duration.
   --  CSV files trajectory.csv and energy.csv are written to the current
   --  working directory.  Console progress is printed every Cfg.Output_Stride
   --  steps.
   procedure Run (Cfg : Scenarios.Config);

end Simulator;
