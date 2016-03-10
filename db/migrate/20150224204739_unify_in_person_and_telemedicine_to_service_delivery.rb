class UnifyInPersonAndTelemedicineToServiceDelivery < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table malpractices
        drop column if exists in_person,
        drop column if exists telemedicine,
        add column service_delivery text
          not null
          check (service_delivery = any(array['online', 'offline']));

                SQL
  end

  def down
    execute  <<-SQL
      alter table malpractices
        drop column if exists service_delivery,
        add column in_person boolean
          not null
          default false,
        add column telemedicine boolean
          not null
          default true;

                SQL
  end
end
