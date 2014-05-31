class AddResetPasswordHashToUsers < ActiveRecord::Migration
	def change
		add_column :users, :password_reset_hash, :string, unique: true, default: nil
		add_index :users, [:id, :password_reset_hash]
	end
end
