class User < Sequel::Model
  plugin :timestamps
end

UserWithRole = Struct.new(:role, :user)
