class ChangeVisitTableAndCreatePatientTable < ActiveRecord::Migration
  def up
    execute "
      create table patients (
        id serial primary key,
        user_id integer not null unique references users(id));

      alter table visits
        drop column start_time,
        drop column end_time,
        drop constraint visits_doctor_id_fkey,
        drop column doctor_id,
        add column oncall_time_id integer not null references oncall_times(id),
        drop constraint visits_patient_id_fkey,
        drop column patient_id,
        add column patient_id integer not null references patients(id),
        add column timerange tstzrange not null,
        add constraint oncall_time_timerange_overlap_check
          exclude using gist (oncall_time_id with =,timerange with &&),
        add constraint patient_id_timerange_overlap_check
          exclude using gist (patient_id with =,timerange with &&)
    "
  end
  def down
    execute "
      alter table visits
        drop constraint patient_id_timerange_overlap_check,
        drop constraint oncall_time_timerange_overlap_check,
        drop column timerange,
        drop column patient_id,
        add column patient_id integer references users(id),
        drop column oncall_time_id,
        add column doctor_id integer not null references doctors(id),
        add column end_time timestamp without time zone not null,
        add column start_time timestamp without time zone not null;

      drop table patients
    "
  end

end
