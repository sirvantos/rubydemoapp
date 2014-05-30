class AddConfirmationHashToUsers < ActiveRecord::Migration
	def change
		add_column :users, :confirmation_hash, :string, unique: true, default: nil
	end
end
