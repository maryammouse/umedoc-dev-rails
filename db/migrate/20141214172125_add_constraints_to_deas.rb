class AddConstraintsToDeas < ActiveRecord::Migration
  def up
    execute " ALTER TABLE Deas
              DROP CONSTRAINT deas_pkey,
              ADD PRIMARY KEY (dea_number),
              DROP COLUMN IF EXISTS id RESTRICT
    "
  end

  def down
    execute " ALTER TABLE Deas
              DROP CONSTRAINT deas_pkey,
              ADD COLUMN id serial primary key,
              ADD PRIMARY KEY (id),
              ALTER dea_number DROP NOT NULL
            "
  end
end
