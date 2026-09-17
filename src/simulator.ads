with Scenarios;

--  Top-level simulation orchestrator.
--  Drives the Störmer-Verlet time loop, emits diagnostic output, and
--  writes CSV trajectory / energy files.
package Simulator is

    --  Run the simulation described by Cfg from t = 0 to Cfg.Duration.
    --  CSV files <scenario>_<timestamp>_trajectory.csv and
    --  <scenario>_<timestamp>_energy.csv are written to the current
    --  working directory (prefix avoids overwriting previous runs).
    --  Console progress is printed every Cfg.Output_Stride
    --  steps. Total_Steps is Duration/DT rounded (not truncated); a
    --  leftover fraction is reported.
    procedure Run (Cfg : Scenarios.Config);

end Simulator;
