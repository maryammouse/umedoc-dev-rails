class AddRestrictCascadeToVisitsOnlineLocationsAndVisitsOfficeLocations < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table visits_office_locations
        drop constraint if exists
          "visits_office_locations_office_location_id_fkey",
        drop constraint if exists
          "visits_office_locations_visit_id_fkey",
        add constraint visits_office_locations_office_location_id_fkey
          foreign key (office_location_id)
          references office_locations(id)
          on delete restrict,
        add constraint visits_office_locations_visit_id_fkey
          foreign key (visit_id)
          references visits(id)
          on delete cascade;


      alter table visits_online_locations
        drop constraint if exists
          "visits_online_locations_online_location_id_fkey",
        drop constraint if exists
          "visits_online_locations_visit_id_fkey",
        add constraint visits_online_locations_online_location_id_fkey
          foreign key (online_location_id)
          references online_locations(id)
          on delete restrict,
        add constraint visits_online_locations_visit_id_fkey
          foreign key (visit_id)
          references visits(id)
          on delete cascade;

                SQL
  end

  def down
    execute  <<-SQL
      alter table visits_office_locations
        drop constraint if exists
          "visits_office_locations_office_location_id_fkey",
        drop constraint if exists
          "visits_office_locations_visit_id_fkey",
        add constraint visits_office_locations_office_location_id_fkey
          foreign key (office_location_id)
          references office_locations(id),
        add constraint visits_office_locations_visit_id_fkey
          foreign key (visit_id) references visits(id);

      alter table visits_online_locations
        drop constraint if exists
          "visits_online_locations_online_location_id_fkey",
        drop constraint if exists
          "visits_online_locations_visit_id_fkey",
        add constraint visits_online_locations_online_location_id_fkey
          foreign key (online_location_id)
          references online_locations(id),
        add constraint visits_online_locations_visit_id_fkey
          foreign key (visit_id) references visits(id);

                SQL
  end
end
