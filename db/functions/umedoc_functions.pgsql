CREATE or replace FUNCTION trigger_function_create_fee_rule_times_on_fee_rules() RETURNS trigger
    AS $function_body$
        declare
            fee_schedule_id_param int;
        begin
            raise notice 'TG_WHEN = %, TG_TABLE_NAME = %, TG_OP = %', TG_WHEN, TG_TABLE_NAME, TG_OP;
            if (TG_OP='INSERT')
                then fee_schedule_id_param = NEW.fee_schedule_id;
            end if;

            if (TG_OP='UPDATE')
                then fee_schedule_id_param = NEW.fee_schedule_id;
                if NEW.fee_schedule_id != OLD.fee_schedule_id then
                    raise notice 'OLD.fee_schedule_id: %', OLD.fee_schedule_id;
                    perform function_fee_rule_times_regenerate(OLD.fee_schedule_id );
                    raise notice 'NEW.fee_schedule_id: %', NEW.fee_schedule_id;
                end if;
            end if;

            if (TG_OP='DELETE') then fee_schedule_id_param = OLD.fee_schedule_id;
            end if;


            perform function_fee_rule_times_regenerate(fee_schedule_id_param );
            return NULL;
        end;
    $function_body$
    LANGUAGE plpgsql;


CREATE or replace FUNCTION trigger_function_create_fee_rule_times_on_fee_schedules() RETURNS trigger
    AS $function_body$
        declare
            fee_schedule_id_param int;
        begin
            raise notice 'TG_WHEN = %, TG_TABLE_NAME = %, TG_OP = %', TG_WHEN, TG_TABLE_NAME, TG_OP;
            if (TG_OP='INSERT')
                then fee_schedule_id_param = NEW.id;
            end if;

            if (TG_OP='UPDATE')
                then fee_schedule_id_param = NEW.id;
                if NEW.id != OLD.id then
                    raise notice 'OLD.id: %', OLD.id;
                    perform function_fee_rule_times_regenerate(OLD.id );
                    raise notice 'NEW.id: %', NEW.id;
                end if;
            end if;

            if (TG_OP='DELETE') then fee_schedule_id_param = OLD.id;
            end if;


            perform function_fee_rule_times_regenerate(fee_schedule_id_param );
            return NULL;
        end;
    $function_body$
    LANGUAGE plpgsql;




create or replace function function_fee_rule_times_regenerate(fee_schedule_id_param int) returns void as
    $function_body$
        declare
            fs_time_zone text;
            fee_rule fee_rules%ROWTYPE;
            fee_schedule fee_schedules%ROWTYPE;
            num_weeks int;
            oncall_time oncall_times%ROWTYPE;
            start_day_of_week int;
            day_of_week_ary int[];
            fee_rule_timerange tstzrange;
            day_offset interval;
            d int;
            week_counter int;
            initial_day_offset interval;


        begin

            select * from fee_schedules where id=fee_schedule_id_param limit 1 into fee_schedule;
            fs_time_zone = fee_schedule.time_zone;
            num_weeks = fee_schedule.weeks_ahead;

            -- select fee_schedules.time_zone from fee_schedules where id=fee_schedule_id_param into fs_time_zone;
            start_day_of_week = extract(dow from now() at time zone fs_time_zone);
            initial_day_offset =   (cast (extract(dow from now() at time zone fs_time_zone) as text) || ' days')::interval;


            week_counter = 0;

            delete from fee_rule_times where fee_schedule_id = fee_schedule_id_param;
            raise notice 'deleted old fee_rule_times for fee_schedule_id_param: %',fee_schedule_id_param;

            loop

                for d in 0..6
                    loop
                        raise notice 'd: %',d;
                        day_offset = (cast(d as text) || ' days')::interval;
                        raise notice 'day_offset: %', day_offset;
                        for fee_rule in select * from fee_rules fr
                                    where fr.fee_schedule_id = fee_schedule_id_param and
                                    fr.day_of_week = d
                                    order by fr.time_of_day_range loop
                                raise notice 'fee_rule: %', fee_rule;
                                fee_rule_timerange =  tstzrange(
                                                        (date_trunc('day',now() at time zone fs_time_zone) -
                                                            initial_day_offset +
                                                            day_offset +
                                                            (cast(week_counter as text) || ' weeks')::interval +
                                                            lower(fee_rule.time_of_day_range) || ' ' ||
                                                            fs_time_zone)::timestamptz,
                                                        (date_trunc('day',now() at time zone fs_time_zone) -
                                                            initial_day_offset +
                                                            day_offset +
                                                            (cast(week_counter as text) || ' weeks')::interval +
                                                            upper(fee_rule.time_of_day_range)  || ' ' ||
                                                            fs_time_zone)::timestamptz
                                                            );


                                insert into fee_rule_times (fee_schedule_id,
                                                            timerange,
                                                            fee,
                                                            visit_duration,
                                                            online_visit_allowed,
                                                            office_visit_allowed,
                                                            area_visit_allowed,
                                                            online_visit_fee,
                                                            office_visit_fee,
                                                            area_visit_fee
                                                            )
                                                    values (fee_rule.fee_schedule_id,
                                                            fee_rule_timerange,
                                                            fee_rule.fee,
                                                            fee_rule.duration,
                                                            fee_rule.online_visit_allowed,
                                                            fee_rule.office_visit_allowed,
                                                            fee_rule.area_visit_allowed,
                                                            fee_rule.online_visit_fee,
                                                            fee_rule.office_visit_fee,
                                                            fee_rule.area_visit_fee
                                                            );
                                raise notice 'Inserted fee_rule_time, fee_schedule_id:%, timerange:%',fee_rule.fee_schedule_id,
                                                                                                        fee_rule_timerange;

                            end loop;
                            raise notice 'No further fee_rules available for day_of_week: %, fee_schedule_id: %', d, fee_rule.fee_schedule_id;
                    end loop;
                    week_counter = week_counter + 1;
                    raise notice 'Week number % complete',week_counter;

                if week_counter >= num_weeks then
                    raise notice 'Inserted % fee_rule_times for fee_schedule_id: % ', week_counter, fee_schedule_id_param;
                    raise notice 'Calling function to merge adjacent fee_rule_times';
                    perform merge_adjacent_fee_rule_times(fee_schedule_id_param);
                    raise notice 'Completed merging fee_rule_times';
                    raise notice 'Setting up calls to regenerate free_times for fee_schedule_id: %', fee_schedule_id_param;

                    for oncall_time in
                        select * from oncall_times
                            where (oncall_times.fee_schedule_id =  fee_schedule_id_param and
                                oncall_times.timerange @> now()) or (
                                oncall_times.fee_schedule_id =   fee_schedule_id_param and
                                    lower(oncall_times.timerange) > now()) -- restrict to future
                            order by oncall_times.timerange
                loop
                    raise notice 'Calling function_oncall_times_free_times_regenerate for oncall_time.id: %', oncall_time.id;
                    perform function_oncall_times_free_times_regenerate(oncall_time);
                end loop;

                    exit;
                end if;
            end loop;
        end
    $function_body$
    LANGUAGE plpgsql;


create or replace function function_all_fee_rule_times_regenerate() returns void as
    $function_body$
        declare
            fee_schedule fee_schedules%ROWTYPE;
        begin
            FOR fee_schedule in
                select * from fee_schedules
                loop
                    perform function_fee_rule_times_regenerate(fee_schedule.id);
                end loop;

        end;
    $function_body$
    LANGUAGE plpgsql;


create or replace function merge_adjacent_fee_rule_times(fee_schedule_id_param int) returns void as
    $function_body$
        declare
            id_array  integer[];
            fee_rule_time1 fee_rule_times%ROWTYPE;
            fee_rule_time2 fee_rule_times%ROWTYPE;
            fee_rule_time_new fee_rule_times%ROWTYPE;
            id_in_array integer;

        begin
            id_array = array(select frt.id from fee_rule_times as frt
                                where fee_schedule_id = fee_schedule_id_param
                                order by timerange);
            foreach id_in_array in array id_array
                LOOP
                    select * from fee_rule_times as frt
                                where frt.id = id_in_array
                                limit 1
                                into fee_rule_time1;
                    select * from fee_rule_times as frt
                                where timerange > fee_rule_time1.timerange
                                order by timerange ASC
                                limit 1
                                into fee_rule_time2;
                    if (fee_rule_time1.timerange -|- fee_rule_time2.timerange)
                    then
                        if ((fee_rule_time1.fee = fee_rule_time2.fee) AND
                            (fee_rule_time1.visit_duration = fee_rule_time2.visit_duration) AND
                            (fee_rule_time1.online_visit_allowed = fee_rule_time2.online_visit_allowed) AND
                            (fee_rule_time1.office_visit_allowed = fee_rule_time2.office_visit_allowed) AND
                            (fee_rule_time1.area_visit_allowed = fee_rule_time2.area_visit_allowed) AND
                            (fee_rule_time1.online_visit_fee = fee_rule_time2.online_visit_fee) AND
                            (fee_rule_time1.office_visit_fee = fee_rule_time2.office_visit_fee) AND
                            (fee_rule_time1.area_visit_fee = fee_rule_time2.area_visit_fee) AND
                            (fee_rule_time1.fee_schedule_id = fee_rule_time2.fee_schedule_id))
                        then
                            raise notice 'fee_rule_times id: % and id: % suitable for merging', fee_rule_time1.id, fee_rule_time2.id;
                            raise notice 'fee_rule_time1 timerange: % fee_rule_time2 timerange: %',
                                 fee_rule_time1.timerange, fee_rule_time2.timerange;
                            delete from fee_rule_times where id = fee_rule_time1.id;
                            -- delete 1, not 2, otherwise next value from array will
                            -- give error due to deleted record
                            raise notice 'fee_rule_time with id: % deleted', fee_rule_time1.id;

                            update fee_rule_times
                                set timerange = tstzrange(lower(fee_rule_time1.timerange),
                                                            upper(fee_rule_time2.timerange))
                                where id = fee_rule_time2.id;
                            raise notice 'fee_rule_time id: % now updated with timerange start: %, end: %',
                                fee_rule_time2.id, lower(fee_rule_time1.timerange), upper(fee_rule_time2.timerange);

                        end if;

                    end if;

                END LOOP;
        end;

    $function_body$
    LANGUAGE plpgsql;


create or replace function trigger_function_check_visit_contained_in_oncall_time() returns trigger as
-- function to check that visits.timerange are contained by oncall_time.timerange for that oncall_time_id
-- and that oncall_times referenced is bookable
    $function_body$
        begin
            -- check for nulls, to allow use as trigger function before insert
            if NEW.jurisdiction is NULL then
                raise not_null_violation using
                message = 'jurisdiction cannot be null';
            end if;

            if NEW.session_id is NULL then
                raise not_null_violation using
                message = 'session_id cannot be null';
            end if;

            if NEW.oncall_time_id is NULL then
                raise not_null_violation using
                message = 'oncall_time_id cannot be null';
            end if;

            if NEW.patient_id is NULL then
                raise not_null_violation using
                message = 'patient_id cannot be null';
            end if;

            if NEW.timerange is NULL then
                raise not_null_violation using
                message = 'timerange cannot be null';
            end if;

            if NEW.fee_paid is NULL then
                raise not_null_violation using
                message = 'fee_paid cannot be null';
            end if;

            -- check that oncall_times referenced by visits is bookable
            if (TG_OP = 'INSERT' and NOT (select bookable from oncall_times where id = NEW.oncall_time_id))
                THEN
                    raise integrity_constraint_violation using message = TG_TABLE_NAME ||
                    '.oncall_time_id does not reference an oncall_time that is bookable ';
            end if;

            -- check that visits.timerange is contained in oncall_time with that visits.oncall_time_id
            if NOT (NEW.timerange <@ (select timerange from oncall_times where id = NEW.oncall_time_id))
                THEN
                    raise integrity_constraint_violation using message = TG_TABLE_NAME ||
                    '.timerange is not contained within the oncall_time referenced by '
                    || TG_TABLE_NAME ||
                    '.oncall_time_id';
            end if;
            return new;
        end
    $function_body$
    LANGUAGE plpgsql;


create or replace function trigger_function_check_time_out_contained_in_oncall_time() returns trigger as
    $function_body$
        declare
            visit visits%ROWTYPE;

        begin

            -- check for nulls, to allow use as trigger function before insert
            if NEW.oncall_time_id is NULL then
                raise not_null_violation using
                message = 'oncall_time_id cannot be null';
            end if;

            if NEW.timerange is NULL then
                raise not_null_violation using
                message = 'timerange cannot be null';
            end if;

            -- check that time_outs.timerange is contained in oncall_time with that time_outs.oncall_time_id
            if NOT (NEW.timerange <@ (select timerange from oncall_times where id = NEW.oncall_time_id))
                THEN
                    raise integrity_constraint_violation using message = TG_TABLE_NAME ||
                    '.timerange is not contained within the oncall_time referenced by '
                    || TG_TABLE_NAME ||
                    '.oncall_time_id';
            end if;

            for visit in
                select * from visits where oncall_time_id = NEW.oncall_time_id
                LOOP
                    IF (NEW.timerange && visit.timerange)
                    THEN
                        raise integrity_constraint_violation using message = TG_TABLE_NAME ||
                        '.timerange: ' || NEW.timerange || ' overlaps with visit of id' || visit.id   ||' and timerange: ' || visit.timerange;
                    END IF;
                END LOOP;

            return NEW;
        end;
    $function_body$
    LANGUAGE plpgsql;

create or replace function function_oncall_times_free_times_regenerate(oncall_time oncall_times) returns void as
    $function_body$
        declare
            oct_frt record;
            pft_tr tstzrange;
            pft record;
            visit_row visits%ROWTYPE;
            free_start_time timestamptz;
            free_end_time timestamptz;
            counter int :=0;

        begin


            raise notice 'Starting function_oncall_times_free_times_regenerate';

            delete from free_times where oncall_time_id = oncall_time.id;
            raise notice 'deleted free_times with oncall_time_id %', oncall_time.id;

            if oncall_time.bookable = TRUE then
                for oct_frt in
                    select
                        oct.timerange as oct_tr,
                        oct.id as oct_id,
                        frt.timerange as frt_tr,
                        frt.id as frt_id,
                        oct.fee_schedule_id,
                        frt.online_visit_allowed,
                        frt.office_visit_allowed,
                        frt.area_visit_allowed,
                        frt.online_visit_fee,
                        frt.office_visit_fee,
                        frt.area_visit_fee
                    from oncall_times as oct inner join fee_rule_times as frt
                    on (oct.fee_schedule_id = frt.fee_schedule_id)

                    where frt.timerange && oct.timerange AND
                            oct.id = oncall_time.id
                    order by frt_tr
                    loop
                        pft_tr = (oct_frt.oct_tr * oct_frt.frt_tr)::tstzrange; -- '*' is the intersection operator in this context

                        if (select count(*) from visits
                                where visits.oncall_time_id = oct_frt.oct_id and
                                    visits.timerange && pft_tr) = 0
                            then
                                raise notice 'no visits found';
                                insert into free_times (oncall_time_id,
                                                        timerange,
                                                        online_visit_allowed,
                                                        office_visit_allowed,
                                                        area_visit_allowed,
                                                        online_visit_fee,
                                                        office_visit_fee,
                                                        area_visit_fee
                                                        )
                                        values (oncall_time.id,
                                                pft_tr,
                                                oct_frt.online_visit_allowed,
                                                oct_frt.office_visit_allowed,
                                                oct_frt.area_visit_allowed,
                                                oct_frt.online_visit_fee,
                                                oct_frt.office_visit_fee,
                                                oct_frt.area_visit_fee
                                                );
                                counter = counter + 1;
                                raise notice 'inserted free_times # % with oncall_time_id %', counter, oncall_time.id;
                        else
                            raise notice 'visits found!';
                            free_start_time := lower(pft_tr);
                            for visit_row in
                                select * from visits
                                    where visits.oncall_time_id = oct_frt.oct_id and
                                        visits.timerange && pft_tr
                                    loop
                                        raise notice 'visit_row: %', visit_row;
                                        free_end_time := lower(visit_row.timerange);
                                                if (free_end_time - free_start_time) >= interval '5 minutes' then
                                                    insert into free_times (
                                                                            oncall_time_id,
                                                                            timerange,
                                                                            online_visit_allowed,
                                                                            office_visit_allowed,
                                                                            area_visit_allowed,
                                                                            online_visit_fee,
                                                                            office_visit_fee,
                                                                            area_visit_fee
                                                                            )

                                                                        values (
                                                                            oncall_time.id,
                                                                            tstzrange(free_start_time, free_end_time),
                                                                            oct_frt.online_visit_allowed,
                                                                            oct_frt.office_visit_allowed,
                                                                            oct_frt.area_visit_allowed,
                                                                            oct_frt.online_visit_fee,
                                                                            oct_frt.office_visit_fee,
                                                                            oct_frt.area_visit_fee
                                                                                );
                                                    counter = counter + 1;
                                                    raise notice 'inserted free_times # % with oncall_time_id %', counter, oncall_time.id;
                                                end if;
                                                free_start_time = upper(visit_row.timerange);
                                    end loop;

                                    free_end_time = upper(pft_tr);
                                    if (free_end_time - free_start_time) >= interval '5 minutes' then
                                        insert into free_times (
                                                                oncall_time_id,
                                                                timerange,
                                                                online_visit_allowed,
                                                                office_visit_allowed,
                                                                area_visit_allowed,
                                                                online_visit_fee,
                                                                office_visit_fee,
                                                                area_visit_fee
                                                                )
                                                        values (
                                                                oncall_time.id,
                                                                tstzrange(free_start_time, free_end_time),
                                                                oct_frt.online_visit_allowed,
                                                                oct_frt.office_visit_allowed,
                                                                oct_frt.area_visit_allowed,
                                                                oct_frt.online_visit_fee,
                                                                oct_frt.office_visit_fee,
                                                                oct_frt.area_visit_fee
                                                                );
                                        counter = counter + 1;
                                        raise notice 'inserted free_times # % with oncall_time_id %', counter, oncall_time.id;
                                    end if;
                        end if;
                    end loop;

            end if;

            perform modify_free_times_to_account_for_time_outs(oncall_time.id );
        end;
    $function_body$ language plpgsql;


create or replace function modify_free_times_to_account_for_time_outs(oncall_time_id integer   ) returns void as

    $function_body$
     -- all free_times have been created by this point, accounting for visits,
                        -- but NOT accounting for time_outs. The exclusion constraints on time_outs
                        -- together with trigger functions on insert/update on time_outs ensure that
                        -- any time_out is 1) within a single oncall_time
                        --                 2) not overlapping with any visits or time_outs on THAT
                        --                       oncall_time
        declare
            oncall_time oncall_times%ROWTYPE;
            time_out time_outs%ROWTYPE;
            free_time free_times%ROWTYPE;
            new_free_time_1 free_times%ROWTYPE;
            new_free_time_2 free_times%ROWTYPE;
            free_start_time_1 timestamptz;
            free_end_time_1 timestamptz;
            free_start_time_2 timestamptz;
            free_end_time_2 timestamptz;



        begin

            select * into oncall_time from oncall_times where oncall_times.id=oncall_time_id;

            raise notice 'starting time_out block for oncall_time id %', oncall_time_id ;

            for time_out in select * from time_outs
                                    where time_outs.oncall_time_id = oncall_time.id
                loop
                    raise notice 'time_out id %, timerange %', time_out.id, time_out.timerange;

                    for free_time in select * from free_times
                                        where free_times.oncall_time_id = oncall_time.id and
                                              free_times.timerange && time_out.timerange
                                        order by free_times.timerange
                        loop
                            raise notice 'free_time id %, timerange %', free_time.id, free_time.timerange;
                            if (time_out.timerange @> free_time.timerange)
                                then
                                delete from free_times where id=free_time.id;
                                raise notice 'deleted free_time with oncall_time_id %', free_time.id;
                            elsif (time_out.timerange <@ free_time.timerange)
                                then
                                    if (lower(time_out.timerange) = lower(free_time.timerange) and
                                         (upper(time_out.timerange) = upper(free_time.timerange)))
                                        then
                                            continue;
                                    elsif (lower(time_out.timerange) <> lower(free_time.timerange)) and
                                            (upper(time_out.timerange) = upper(free_time.timerange))
                                        then
                                            free_start_time_1 = lower(free_time.timerange);
                                            free_end_time_1 = lower(time_out.timerange);

                                            delete from free_times where id = free_time.id;
                                            raise notice 'deleted free_time with oncall_time_id %', free_time.id;

                                            new_free_time_1 = free_time;
                                            if (free_end_time_1 - free_start_time_1)::interval >= '5 minutes'::interval
                                             then
                                                new_free_time_1.timerange=tstzrange(free_start_time_1,free_end_time_1);
                                                insert into free_times values (new_free_time_1.*);
                                                raise notice 'inserted free_time with id % and timerange %', free_time.id,new_free_time_1.timerange;
                                             else
                                                continue;
                                            end if;

                                    elsif (lower(time_out.timerange) = lower(free_time.timerange)) and
                                            (upper(time_out.timerange) <> upper(free_time.timerange))
                                        then
                                            free_start_time_1 = upper(time_out.timerange);
                                            free_end_time_1 = upper(free_time.timerange );
                                            new_free_time_1 = free_time;

                                            delete from free_times where id = free_time.id;
                                            raise notice 'deleted free_time with oncall_time_id %', free_time.id;

                                            if (free_end_time_1 - free_start_time_1)::interval >= '5 minutes'::interval
                                             then
                                                new_free_time_1.timerange=tstzrange(free_start_time_1,free_end_time_1);
                                                insert into free_times values (new_free_time_1.*);
                                                raise notice 'inserted free_time with id % and timerange %', free_time.id,new_free_time_1.timerange;
                                             else
                                                continue;
                                            end if;

                                    else
                                            new_free_time_1 = free_time;
                                            new_free_time_2 = free_time;
                                            new_free_time_2.id = nextval('time_outs_id_seq');
                                            free_start_time_1 = lower(free_time.timerange);
                                            free_end_time_1 = lower(time_out.timerange);
                                            free_start_time_2 = upper(time_out.timerange);
                                            free_end_time_2 = upper(new_free_time_2.timerange);

                                            delete from free_times where id = free_time.id;
                                            raise notice 'deleted free_time with oncall_time_id %', free_time.id;


                                            if (free_end_time_1 - free_start_time_1)::interval >= '5 minutes'::interval
                                             then
                                                new_free_time_1.timerange=tstzrange(free_start_time_1,free_end_time_1);
                                                insert into free_times values (new_free_time_1.*);
                                                raise notice 'inserted free_time with id % and timerange %', free_time.id,new_free_time_1.timerange;
                                            end if;

                                            if (free_end_time_2 - free_start_time_2)::interval >= '5 minutes'::interval
                                             then
                                                new_free_time_2.timerange=tstzrange(free_start_time_2,free_end_time_2);
                                                insert into free_times values (new_free_time_2.*);
                                                raise notice 'inserted free_time with id % and timerange %', free_time.id,new_free_time_2.timerange;
                                            end if;
                                    end if;
                            elsif (time_out.timerange &< free_time.timerange)
                                then
                                free_start_time_1 = upper(time_out.timerange);
                                free_end_time_1 = upper(free_time.timerange );
                                if (free_end_time_1 - free_start_time_1)::interval >= '5 minutes'::interval
                                 then
                                    free_time.timerange = tstzrange(free_start_time_1,free_end_time_1);
                                    update free_times set timerange=free_time.timerange
                                        where free_times.id=free_time.id;
                                    raise notice 'updated free_time with id % to timerange %', free_time.id,free_time.timerange;
                                end if;

                            elsif (time_out.timerange &> free_time.timerange)
                                then
                                free_start_time_1 = lower(free_time.timerange );
                                free_end_time_1 = lower(time_out.timerange );


                                if (free_end_time_1 - free_start_time_1)::interval >= '5 minutes'::interval
                                 then
                                    free_time.timerange = tstzrange(free_start_time_1,free_end_time_1);
                                    update free_times set timerange=free_time.timerange
                                        where free_times.id=free_time.id;
                                    raise notice 'updated free_time with id % to timerange %', free_time.id,free_time.timerange;
                                end if;
                            end if;
                        end loop;
                    end loop;
        end;


        $function_body$
    LANGUAGE plpgsql;


create or replace function trigger_function_regenerate_free_times() returns trigger as
-- function to delete existing free_times and create new ones based on changes to oncall_times or visits
    $function_body$
        declare
            oncall_time oncall_times%ROWTYPE;
        begin

            raise notice 'starting trigger_function_regenerate_free_times';

            if (TG_OP = 'INSERT' AND TG_TABLE_NAME = 'oncall_times' AND TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;
                perform function_oncall_times_free_times_regenerate(NEW.*);
            end if;

            if (TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'oncall_times' AND TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;
                perform function_oncall_times_free_times_regenerate(NEW.*);
            end if;

            if (TG_OP = 'DELETE' AND TG_TABLE_NAME = 'oncall_times' AND TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;
                delete from free_times where oncall_time_id=OLD.id;
            end if;

            if (TG_OP = 'INSERT' AND TG_TABLE_NAME = 'visits' AND TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;
                select * into oncall_time from oncall_times where id=NEW.oncall_time_id;
                perform function_oncall_times_free_times_regenerate(oncall_time);
            end if;

            if (TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'visits' AND TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;
                if (NEW.oncall_time_id <> OLD.oncall_time_id) then
                    select * into oncall_time from oncall_times where id=OLD.oncall_time_id;
                    perform function_oncall_times_free_times_regenerate(oncall_time);
                end if;
                select * into oncall_time from oncall_times where id=NEW.oncall_time_id;
                perform function_oncall_times_free_times_regenerate(oncall_time);
            end if;

            if (TG_OP = 'DELETE' AND TG_TABLE_NAME = 'visits' AND TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;
                select * into oncall_time from oncall_times where id=OLD.oncall_time_id;
                perform function_oncall_times_free_times_regenerate(oncall_time);
            end if;

            if (TG_OP = 'INSERT' AND TG_TABLE_NAME = 'time_outs' AND TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;
                select * into oncall_time from oncall_times where id=NEW.oncall_time_id;
                perform function_oncall_times_free_times_regenerate(oncall_time);
            end if;

            if (TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'time_outs' AND TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;
                if (NEW.oncall_time_id <> OLD.oncall_time_id) then
                    select * into oncall_time from oncall_times where id=OLD.oncall_time_id;
                    perform function_oncall_times_free_times_regenerate(oncall_time);
                end if;
                select * into oncall_time from oncall_times where id=NEW.oncall_time_id;
                perform function_oncall_times_free_times_regenerate(oncall_time);
            end if;

            if (TG_OP = 'DELETE' AND TG_TABLE_NAME = 'time_outs' AND TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;
                select * into oncall_time from oncall_times where id=OLD.oncall_time_id;
                perform function_oncall_times_free_times_regenerate(oncall_time);
            end if;




            if (TG_OP = 'INSERT' AND TG_TABLE_NAME = 'fee_rules' and TG_WHEN = 'AFTER') then
                raise notice 'TG_WHEN = %, TG_OP = %, TG_TABLE_NAME = %', TG_WHEN, TG_OP, TG_TABLE_NAME;

                for oncall_time in 
                    select * from oncall_times 
                        where (oncall_times.fee_schedule_id = NEW.fee_schedule_id and
                            oncall_times.timerange @> now()) or (
                            oncall_times.fee_schedule_id = NEW.fee_schedule_id and
                                lower(oncall_times.timerange) > now()) -- restrict to future 
                        order by oncall_times.timerange
                loop
                    perform function_oncall_times_free_times_regenerate(oncall_time);
                end loop;
            end if;


            return NULL;
        end;
    $function_body$
    LANGUAGE plpgsql;

/*create or replace function trigger_function_time_floor_minute_add_duration() returns trigger as*/
    /*$function_body$*/
        /*declare*/
            /*start_time timestamptz;*/
            /*end_time timestamptz;*/
        /*begin*/
            /*raise notice 'TG_OP= %, TG_TABLE_NAME = %, TG_WHEN = %', TG_OP, TG_TABLE_NAME, TG_WHEN;*/
            /*raise notice 'Original timerange = %', NEW.timerange;*/
            /*select lower(NEW.timerange) into start_time;*/
            /*select upper(NEW.timerange) into end_time;*/
            /*start_time := time_floor_minute(start_time);*/
            /*end_time := time_floor_minute(end_time);*/
            /*NEW.timerange := tstzrange(start_time, end_time);*/
            /*NEW.duration = extract(epoch from (end_time - start_time));*/
            /*raise notice 'New timerange = %', NEW.timerange;*/
            /*raise notice 'Duration calculated = %', NEW.duration;*/

            /*return NEW;*/
        /*end;*/
    /*$function_body$*/
    /*LANGUAGE plpgsql;*/

create or replace function trigger_function_time_round_5_minutes_add_duration() returns trigger as
    $function_body$
        declare
            start_time timestamptz;
            end_time timestamptz;
        begin
            raise notice 'TG_OP= %, TG_TABLE_NAME = %, TG_WHEN = %', TG_OP, TG_TABLE_NAME, TG_WHEN;
            raise notice 'Original timerange = %', NEW.timerange;
            select lower(NEW.timerange) into start_time;
            select upper(NEW.timerange) into end_time;
            raise notice 'before rounding: start_time:%, end_time:%', start_time, end_time;
            start_time := time_round(start_time,'5 minutes'::interval);
            end_time := time_round(end_time,'5 minutes'::interval);
            raise notice 'after rounding: start_time:%, end_time:%', start_time, end_time;
            NEW.timerange := tstzrange(start_time, end_time);
            NEW.duration := extract(epoch from (end_time - start_time));
            raise notice 'New timerange = %', NEW.timerange;
            raise notice 'Duration calculated = %', NEW.duration;

            return NEW;
        end;
    $function_body$
    LANGUAGE plpgsql;

create or replace function trigger_function_time_round_5_minutes_on_fee_rules() returns trigger as
    $function_body$
        declare
            start_time time;
            end_time time;
        begin
            raise notice 'TG_OP= %, TG_TABLE_NAME = %, TG_WHEN = %', TG_OP, TG_TABLE_NAME, TG_WHEN;
            raise notice 'Original time_of_day_range = %', NEW.time_of_day_range;
            select lower(NEW.time_of_day_range) into start_time;
            select upper(NEW.time_of_day_range) into end_time;
            raise notice 'before rounding: start_time:%, end_time:%', start_time, end_time;
            start_time := time_round_5_minutes_time_of_day(start_time);
            end_time := time_round_5_minutes_time_of_day(end_time);
            raise notice 'after rounding: start_time:%, end_time:%', start_time, end_time;
            NEW.time_of_day_range := timerange(start_time, end_time);
            raise notice 'New time_of_day_range = %', NEW.time_of_day_range;

            return NEW;
        end;
    $function_body$
    LANGUAGE plpgsql;

create or replace function trigger_function_time_round_5_minutes_on_time_outs() returns trigger as
    $function_body$
        declare
            start_time timestamptz;
            end_time timestamptz;
        begin
            raise notice 'TG_OP= %, TG_TABLE_NAME = %, TG_WHEN = %', TG_OP, TG_TABLE_NAME, TG_WHEN;
            raise notice 'Original timerange = %', NEW.timerange;
            select lower(NEW.timerange) into start_time;
            select upper(NEW.timerange) into end_time;
            raise notice 'before rounding: start_time:%, end_time:%', start_time, end_time;
            start_time := time_round(start_time,'5 minutes'::interval);
            end_time := time_round(end_time,'5 minutes'::interval);

            raise notice 'after rounding: start_time:%, end_time:%', start_time, end_time;
            NEW.timerange := tstzrange(start_time, end_time);
            raise notice 'New timerange = %', NEW.timerange;

            return NEW;
        end;
    $function_body$
    LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION time_floor_minute(TIMESTAMP WITH TIME ZONE) 
RETURNS TIMESTAMP WITH TIME ZONE AS $$ 
  SELECT date_trunc('minute', $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION time_round(base_tstz timestamptz, round_interval INTERVAL) RETURNS timestamptz AS $BODY$
SELECT TO_TIMESTAMP((EXTRACT(epoch FROM $1)::INTEGER + EXTRACT(epoch FROM $2)::INTEGER / 2)
                / EXTRACT(epoch FROM $2)::INTEGER * EXTRACT(epoch FROM $2)::INTEGER);
$BODY$ LANGUAGE SQL STABLE;

create or replace function time_round_5_minutes_time_of_day(base_time_of_day time) returns time as
    $function_body$
    begin
        return ((extract(hours from base_time_of_day) || ' ' || 'hours')::interval +
                (extract(minutes from base_time_of_day) / 5)::integer * '5 minutes'::interval)::text::time;
                -- the ::text is necessary, as the ::time cast operator converts an interval of '24:00:00' 
                -- to '00:00:00', while converting a text value of '24:00:00' to a time of '24:00:00' as required
    end;

    $function_body$
    language plpgsql;




/* NAMING CONVENTION:
Triggers start with 'trigger_'
Trigger FUNCTIONS (the functions CALLED BY triggers) start with trigger_function_
*/

 --the following code is to make the file idempotent, to allow triggers to be updated
drop trigger if exists trigger_check_visit_contained_in_oncall_time on visits;
drop trigger if exists trigger_regenerate_free_times_on_visits on visits; --allows trigger to be updated
drop trigger if exists trigger_regenerate_free_times_on_oncall_times on oncall_times; --allows trigger to be updated
drop trigger if exists trigger_regenerate_free_times_on_fee_rules on fee_rules; --allows trigger to be updated

drop trigger if exists trigger_floor_times_to_nearest_minute on oncall_times; --allows trigger to be updated
drop trigger if exists trigger_floor_times_to_nearest_minute on visits; --allows trigger to be updated
drop trigger if exists trigger_floor_times_to_nearest_minute on free_times; --allows trigger to be updated
drop function if exists trigger_floor_times_to_nearest_minute();
-- name of function changed to account for increased responsibility
drop trigger if exists trigger_floor_times_to_nearest_minute_add_duration on oncall_times; --allows trigger to be updated
drop trigger if exists trigger_floor_times_to_nearest_minute_add_duration on visits; --allows trigger to be updated
drop trigger if exists trigger_floor_times_to_nearest_minute_add_duration on free_times; --allows trigger to be updated

drop trigger if exists trigger_floor_times_to_nearest_5_minutes_add_duration on oncall_times; --allows trigger to be updated
drop trigger if exists trigger_floor_times_to_nearest_5_minutes_add_duration on visits; --allows trigger to be updated
drop trigger if exists trigger_floor_times_to_nearest_5_minutes_add_duration on free_times; --allows trigger to be updated
drop trigger if exists trigger_floor_times_to_nearest_5_minutes on fee_rules;

drop trigger if exists trigger_round_times_to_nearest_5_minutes_add_duration on oncall_times; --allows trigger to be updated
drop trigger if exists trigger_round_times_to_nearest_5_minutes_add_duration on visits; --allows trigger to be updated
drop trigger if exists trigger_round_times_to_nearest_5_minutes_add_duration on free_times; --allows trigger to be updated
drop trigger if exists trigger_round_times_to_nearest_5_minutes on fee_rules;

drop trigger if exists trigger_a_round_times_to_nearest_5_minutes on time_outs;
drop trigger if exists trigger_b_check_time_out_contained_in_oncall_time on time_outs;
drop trigger if exists trigger_c_regenerate_free_times_on_time_outs on time_outs;

drop trigger if exists trigger_create_fee_rule_times on fee_rules;
drop trigger if exists trigger_create_fee_rule_times on fee_schedules;

drop function if exists trigger_function_time_floor_5_minutes_add_duration();
drop function if exists trigger_function_time_floor_5_minutes_on_fee_rules();


drop trigger if exists trigger_regenerate_free_times_on_fee_rule_times on fee_rule_times;



create trigger trigger_check_visit_contained_in_oncall_time
    before insert or update
    on visits
    for each row
    execute procedure trigger_function_check_visit_contained_in_oncall_time();

create trigger trigger_regenerate_free_times_on_visits
    after insert or update or delete
    on visits
    for each row
    execute procedure trigger_function_regenerate_free_times();

create trigger trigger_regenerate_free_times_on_oncall_times
    after insert or update or delete
    on oncall_times
    for each row
    execute procedure trigger_function_regenerate_free_times();

/*create trigger trigger_regenerate_free_times_on_fee_rules*/
    /*after insert or update or delete*/
    /*on fee_rules*/
    /*for each row*/
    /*execute procedure trigger_function_regenerate_free_times();*/
-- after insert, update, or delete on a fee rule, regenerate the free times
-- fee_schedule_id is common to the oncall_time and the fee_rules
-- we want to restrict the set of oncall_times for which we will rewrite free_times
-- to those from 'now' onwards (the fee_rule_times regenerated will be from now onwards
-- so the free_times will also be from now onwards)

CREATE TRIGGER trigger_create_fee_rule_times
    AFTER INSERT OR DELETE OR UPDATE
    ON fee_rules
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_function_create_fee_rule_times_on_fee_rules();

CREATE TRIGGER trigger_create_fee_rule_times
    AFTER INSERT OR DELETE OR UPDATE
    ON fee_schedules
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_function_create_fee_rule_times_on_fee_schedules();


/*CREATE TRIGGER trigger_regenerate_free_times_on_fee_rule_times*/
    /*AFTER INSERT OR DELETE OR UPDATE*/
    /*ON fee_rule_times*/
    /*FOR EACH row*/
    /*EXECUTE PROCEDURE trigger_function_regenerate_free_times();
    not needed any more, as code calling free_times_regenerate moved to end 
    of fee_rule_time_regenerate*/


/*create trigger trigger_floor_times_to_nearest_minute_add_duration*/
    /*before insert or update*/
    /*on oncall_times*/
    /*for each row*/
    /*execute procedure trigger_function_time_floor_minute_add_duration();*/

/*create trigger trigger_floor_times_to_nearest_minute_add_duration*/
    /*before insert or update*/
    /*on visits*/
    /*for each row*/
    /*execute procedure trigger_function_time_floor_minute_add_duration();*/

/*create trigger trigger_floor_times_to_nearest_minute_add_duration*/
    /*before insert or update*/
    /*on free_times*/
    /*for each row*/
    /*execute procedure trigger_function_time_round_minute_add_duration();*/


create trigger trigger_round_times_to_nearest_5_minutes_add_duration
    before insert or update
    on oncall_times
    for each row
    execute procedure trigger_function_time_round_5_minutes_add_duration();

create trigger trigger_round_times_to_nearest_5_minutes_add_duration
    before insert or update
    on visits
    for each row
    execute procedure trigger_function_time_round_5_minutes_add_duration();

create trigger trigger_round_times_to_nearest_5_minutes_add_duration
    before insert or update
    on free_times
    for each row
    execute procedure trigger_function_time_round_5_minutes_add_duration();

create trigger trigger_round_times_to_nearest_5_minutes
    before insert or update
    on fee_rules
    for each row
    execute procedure trigger_function_time_round_5_minutes_on_fee_rules();

create trigger trigger_a_round_times_to_nearest_5_minutes
    before insert or update
    on time_outs
    for each row
    execute procedure trigger_function_time_round_5_minutes_on_time_outs();


create trigger trigger_b_check_time_out_contained_in_oncall_time
    before insert or update
    on time_outs
    for each row
    execute procedure trigger_function_check_time_out_contained_in_oncall_time();

CREATE TRIGGER trigger_c_regenerate_free_times_on_time_outs
    AFTER INSERT OR DELETE OR UPDATE
    ON time_outs
    FOR EACH row
    EXECUTE PROCEDURE trigger_function_regenerate_free_times();


