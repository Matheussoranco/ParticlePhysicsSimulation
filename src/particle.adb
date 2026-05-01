with Constants;

package body Particle is

   function Make_Proton (ID : Positive; Pos, Vel : Vec3.Vector) return State is
   begin
      return (Position => Pos,
              Velocity => Vel,
              Force    => Vec3.Zero,
              Mass     => Constants.M_Proton,
              Charge   => Constants.Q_E,
              Kind     => Proton,
              ID       => ID);
   end Make_Proton;

   function Make_Electron (ID : Positive; Pos, Vel : Vec3.Vector) return State is
   begin
      return (Position => Pos,
              Velocity => Vel,
              Force    => Vec3.Zero,
              Mass     => Constants.M_Electron,
              Charge   => -Constants.Q_E,
              Kind     => Electron,
              ID       => ID);
   end Make_Electron;

   function Make_Neutron (ID : Positive; Pos, Vel : Vec3.Vector) return State is
   begin
      return (Position => Pos,
              Velocity => Vel,
              Force    => Vec3.Zero,
              Mass     => Constants.M_Neutron,
              Charge   => 0.0,
              Kind     => Neutron,
              ID       => ID);
   end Make_Neutron;

   function Make_Muon (ID : Positive; Pos, Vel : Vec3.Vector) return State is
   begin
      return (Position => Pos,
              Velocity => Vel,
              Force    => Vec3.Zero,
              Mass     => Constants.M_Muon,
              Charge   => -Constants.Q_E,
              Kind     => Muon,
              ID       => ID);
   end Make_Muon;

end Particle;
