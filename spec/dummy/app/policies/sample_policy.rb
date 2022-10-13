class SamplePolicy # < Hyperstack::ApplicationPolicy
  regulate_class_connection { true }
  # # regulate_class_connection(auto_connect: false) { self if is_a?(::User) }
  # # #regulate_instance_connections{self if is_a?(GuestUser)}
  # # #regulate_instance_connections{self if is_a?(::User)}
  regulate_instance_connections { self }

  regulate_broadcast do |policy|
    #policy.send_all_but(:uuid).to(acting_user) if acting_user.is_a?(User)
    policy.send_all.to(policy.obj,policy.obj.class)
  end
  allow_change { true }
  # # #allow_change { acting_user==self || acting_user.is_a?(::User) }
end