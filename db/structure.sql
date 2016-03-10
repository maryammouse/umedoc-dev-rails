--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET search_path = public, pg_catalog;

--
-- Name: timerange; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE timerange AS RANGE (
    subtype = time without time zone
);


--
-- Name: is_timezone(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_timezone(tz text) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
        BEGIN
         PERFORM now() AT TIME ZONE tz;
         RETURN TRUE;
        EXCEPTION WHEN invalid_parameter_value THEN
         RETURN FALSE;
        END;
        $$;


--
-- Name: timezone; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN timezone AS citext
	CONSTRAINT timezone_check CHECK (is_timezone((VALUE)::text));


--
-- Name: function_all_fee_rule_times_regenerate(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION function_all_fee_rule_times_regenerate() RETURNS void
    LANGUAGE plpgsql
    AS $$
        declare
            fee_schedule fee_schedules%ROWTYPE;
        begin
            FOR fee_schedule in
                select * from fee_schedules
                loop
                    perform function_fee_rule_times_regenerate(fee_schedule.id);
                end loop;

        end;
    $$;


--
-- Name: function_fee_rule_times_regenerate(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION function_fee_rule_times_regenerate(fee_schedule_id_param integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: function_fee_rule_times_regenerate(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION function_fee_rule_times_regenerate(fee_schedule_id_param integer, num_weeks integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
        declare
            fs_time_zone text;
            fee_rule fee_rules%ROWTYPE;
            oncall_time oncall_times%ROWTYPE;
            start_day_of_week int;
            day_of_week_ary int[];
            fee_rule_timerange tstzrange;
            day_offset interval;
            d int;
            week_counter int;
            initial_day_offset interval;


        begin
            select fee_schedules.time_zone from fee_schedules where id=fee_schedule_id_param into fs_time_zone;
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
    $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: oncall_times; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oncall_times (
    id integer NOT NULL,
    doctor_id integer NOT NULL,
    fee_schedule_id integer NOT NULL,
    timerange tstzrange NOT NULL,
    bookable boolean DEFAULT false NOT NULL,
    duration integer NOT NULL
);


--
-- Name: function_oncall_times_free_times_regenerate(oncall_times); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION function_oncall_times_free_times_regenerate(oncall_time oncall_times) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: merge_adjacent_fee_rule_times(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION merge_adjacent_fee_rule_times(fee_schedule_id_param integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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

    $$;


--
-- Name: modify_free_times_to_account_for_time_outs(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION modify_free_times_to_account_for_time_outs(oncall_time_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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


        $$;


--
-- Name: time_floor_minute(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION time_floor_minute(timestamp with time zone) RETURNS timestamp with time zone
    LANGUAGE sql
    AS $_$ 
  SELECT date_trunc('minute', $1);
$_$;


--
-- Name: time_round(timestamp with time zone, interval); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION time_round(base_tstz timestamp with time zone, round_interval interval) RETURNS timestamp with time zone
    LANGUAGE sql STABLE
    AS $_$
SELECT TO_TIMESTAMP((EXTRACT(epoch FROM $1)::INTEGER + EXTRACT(epoch FROM $2)::INTEGER / 2)
                / EXTRACT(epoch FROM $2)::INTEGER * EXTRACT(epoch FROM $2)::INTEGER);
$_$;


--
-- Name: time_round_5_minutes_time_of_day(time without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION time_round_5_minutes_time_of_day(base_time_of_day time without time zone) RETURNS time without time zone
    LANGUAGE plpgsql
    AS $$
    begin
        return ((extract(hours from base_time_of_day) || ' ' || 'hours')::interval +
                (extract(minutes from base_time_of_day) / 5)::integer * '5 minutes'::interval)::text::time;
                -- the ::text is necessary, as the ::time cast operator converts an interval of '24:00:00' 
                -- to '00:00:00', while converting a text value of '24:00:00' to a time of '24:00:00' as required
    end;

    $$;


--
-- Name: trigger_function_check_time_out_contained_in_oncall_time(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_check_time_out_contained_in_oncall_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: trigger_function_check_visit_contained_in_oncall_time(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_check_visit_contained_in_oncall_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: trigger_function_create_fee_rule_times(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_create_fee_rule_times() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
                    perform function_fee_rule_times_regenerate(OLD.fee_schedule_id, 52);
                    raise notice 'NEW.fee_schedule_id: %', NEW.fee_schedule_id;
                end if;
            end if;

            if (TG_OP='DELETE') then fee_schedule_id_param = OLD.fee_schedule_id;
            end if;


            perform function_fee_rule_times_regenerate(fee_schedule_id_param, 52);
            return NULL;
        end;
    $$;


--
-- Name: trigger_function_create_fee_rule_times_on_fee_rules(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_create_fee_rule_times_on_fee_rules() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: trigger_function_create_fee_rule_times_on_fee_schedules(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_create_fee_rule_times_on_fee_schedules() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: trigger_function_regenerate_free_times(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_regenerate_free_times() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: trigger_function_time_floor_minute(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_time_floor_minute() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        declare
            start_time timestamptz;
            end_time timestamptz;
        begin
            raise notice 'TG_OP= %, TG_TABLE_NAME = %, TG_WHEN = %', TG_OP, TG_TABLE_NAME, TG_WHEN;
            raise notice 'Original timerange = %', NEW.timerange;
            select lower(NEW.timerange) into start_time;
            select upper(NEW.timerange) into end_time;
            start_time := time_floor_minute(start_time);
            end_time := time_floor_minute(end_time);
            NEW.timerange := tstzrange(start_time, end_time);
            raise notice 'New timerange = %', NEW.timerange;

            return NEW;
        end;
    $$;


--
-- Name: trigger_function_time_floor_minute_add_duration(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_time_floor_minute_add_duration() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        declare
            start_time timestamptz;
            end_time timestamptz;
        begin
            raise notice 'TG_OP= %, TG_TABLE_NAME = %, TG_WHEN = %', TG_OP, TG_TABLE_NAME, TG_WHEN;
            raise notice 'Original timerange = %', NEW.timerange;
            select lower(NEW.timerange) into start_time;
            select upper(NEW.timerange) into end_time;
            start_time := time_floor_minute(start_time);
            end_time := time_floor_minute(end_time);
            NEW.timerange := tstzrange(start_time, end_time);
            NEW.duration = extract(epoch from (end_time - start_time));
            raise notice 'New timerange = %', NEW.timerange;
            raise notice 'Duration calculated = %', NEW.duration;

            return NEW;
        end;
    $$;


--
-- Name: trigger_function_time_round_5_minutes_add_duration(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_time_round_5_minutes_add_duration() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: trigger_function_time_round_5_minutes_on_fee_rules(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_time_round_5_minutes_on_fee_rules() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: trigger_function_time_round_5_minutes_on_time_outs(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION trigger_function_time_round_5_minutes_on_time_outs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE addresses (
    id integer NOT NULL,
    address_type character varying(255),
    street_address_1 character varying(255) NOT NULL,
    street_address_2 character varying(255),
    city character varying(255) NOT NULL,
    state character varying(255) NOT NULL,
    zip_code character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    mailing_name character varying(255) NOT NULL,
    latitude double precision,
    longitude double precision,
    user_id integer NOT NULL,
    CONSTRAINT city_length CHECK ((char_length((city)::text) <= 32)),
    CONSTRAINT state_length CHECK ((char_length((state)::text) = 2)),
    CONSTRAINT street_address_1_length CHECK ((char_length((street_address_1)::text) <= 64)),
    CONSTRAINT street_address_2_length CHECK ((char_length((street_address_2)::text) <= 64)),
    CONSTRAINT zip_code_length CHECK ((char_length((zip_code)::text) = 5))
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: archived_subscriptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_subscriptions (
    id integer NOT NULL,
    subscription_id integer NOT NULL,
    stripe_data jsonb NOT NULL,
    stripe_seller_id integer NOT NULL
);


--
-- Name: archived_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_subscriptions_id_seq OWNED BY archived_subscriptions.id;


--
-- Name: area_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE area_locations (
    zipcode character(5) NOT NULL,
    id integer NOT NULL
);


--
-- Name: area_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE area_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: area_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE area_locations_id_seq OWNED BY area_locations.id;


--
-- Name: board_certifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE board_certifications (
    id integer NOT NULL,
    board_name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    certification_number character varying(255) NOT NULL,
    expiry_date date NOT NULL,
    issue_date date NOT NULL,
    specialty character varying(255) NOT NULL,
    doctor_id integer NOT NULL,
    CONSTRAINT board_name_length CHECK ((char_length((board_name)::text) <= 64)),
    CONSTRAINT specialty_length CHECK ((char_length((specialty)::text) <= 64))
);


--
-- Name: board_certifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE board_certifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: board_certifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE board_certifications_id_seq OWNED BY board_certifications.id;


--
-- Name: chat_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE chat_entries (
    id integer NOT NULL,
    body text NOT NULL,
    connectionid character varying(255) NOT NULL,
    session_id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: chat_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE chat_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE chat_entries_id_seq OWNED BY chat_entries.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries (
    name character varying(255),
    iso character varying(2) NOT NULL
);


--
-- Name: deas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE deas (
    dea_number character varying(255) NOT NULL,
    valid_in character varying(255) NOT NULL,
    issued_date date NOT NULL,
    expiry_date date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    doctor_id integer NOT NULL,
    CONSTRAINT dea_number_length CHECK ((char_length((dea_number)::text) = 9)),
    CONSTRAINT valid_in_length CHECK ((char_length((valid_in)::text) = 2))
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: doctors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE doctors (
    id integer NOT NULL,
    user_id integer NOT NULL,
    verification_status text DEFAULT 'not_verified'::text NOT NULL,
    blurb text,
    linked_in character varying(255),
    image text,
    CONSTRAINT verification_status_check CHECK ((verification_status = ANY (ARRAY['not_verified'::text, 'verified'::text])))
);


--
-- Name: doctors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE doctors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doctors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE doctors_id_seq OWNED BY doctors.id;


--
-- Name: fee_rule_times; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE fee_rule_times (
    id integer NOT NULL,
    fee_schedule_id integer NOT NULL,
    timerange tstzrange NOT NULL,
    fee numeric(4,0) NOT NULL,
    visit_duration interval DEFAULT '00:30:00'::interval,
    online_visit_allowed text DEFAULT 'not_allowed'::text NOT NULL,
    office_visit_allowed text DEFAULT 'not_allowed'::text NOT NULL,
    area_visit_allowed text DEFAULT 'not_allowed'::text NOT NULL,
    online_visit_fee numeric(4,0) DEFAULT 100 NOT NULL,
    office_visit_fee numeric(4,0) DEFAULT 100 NOT NULL,
    area_visit_fee numeric(4,0) DEFAULT 100 NOT NULL,
    CONSTRAINT area_visit_allowed_check CHECK ((area_visit_allowed = ANY (ARRAY['allowed'::text, 'not_allowed'::text]))),
    CONSTRAINT office_visit_allowed_check CHECK ((office_visit_allowed = ANY (ARRAY['allowed'::text, 'not_allowed'::text]))),
    CONSTRAINT online_visit_allowed_check CHECK ((online_visit_allowed = ANY (ARRAY['allowed'::text, 'not_allowed'::text]))),
    CONSTRAINT visit_duration_rounding_check CHECK ((date_part('minute'::text, visit_duration) = ANY (ARRAY[(0)::double precision, (5)::double precision, (10)::double precision, (15)::double precision, (20)::double precision, (25)::double precision, (30)::double precision, (35)::double precision, (40)::double precision, (45)::double precision, (50)::double precision, (55)::double precision])))
);


--
-- Name: fee_rule_times_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fee_rule_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fee_rule_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fee_rule_times_id_seq OWNED BY fee_rule_times.id;


--
-- Name: fee_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE fee_rules (
    id integer NOT NULL,
    day_of_week integer NOT NULL,
    fee numeric(4,0) NOT NULL,
    duration interval DEFAULT '00:30:00'::interval NOT NULL,
    time_of_day_range timerange NOT NULL,
    fee_schedule_id integer NOT NULL,
    online_visit_allowed text DEFAULT 'not_allowed'::text NOT NULL,
    office_visit_allowed text DEFAULT 'not_allowed'::text NOT NULL,
    area_visit_allowed text DEFAULT 'not_allowed'::text NOT NULL,
    online_visit_fee numeric(4,0) DEFAULT 100 NOT NULL,
    office_visit_fee numeric(4,0) DEFAULT 100 NOT NULL,
    area_visit_fee numeric(4,0) DEFAULT 100 NOT NULL,
    CONSTRAINT area_visit_allowed_check CHECK ((area_visit_allowed = ANY (ARRAY['allowed'::text, 'not_allowed'::text]))),
    CONSTRAINT day_of_week_check CHECK ((day_of_week = ANY (ARRAY[0, 1, 2, 3, 4, 5, 6]))),
    CONSTRAINT duration_rounding_check CHECK ((date_part('minute'::text, duration) = ANY (ARRAY[(0)::double precision, (5)::double precision, (10)::double precision, (15)::double precision, (20)::double precision, (25)::double precision, (30)::double precision, (35)::double precision, (40)::double precision, (45)::double precision, (50)::double precision, (55)::double precision]))),
    CONSTRAINT office_visit_allowed_check CHECK ((office_visit_allowed = ANY (ARRAY['allowed'::text, 'not_allowed'::text]))),
    CONSTRAINT online_visit_allowed_check CHECK ((online_visit_allowed = ANY (ARRAY['allowed'::text, 'not_allowed'::text])))
);


--
-- Name: fee_schedules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE fee_schedules (
    doctor_id integer NOT NULL,
    id integer NOT NULL,
    name text DEFAULT 'Default'::text NOT NULL,
    time_zone text DEFAULT 'US/Pacific'::text NOT NULL,
    weeks_ahead integer DEFAULT 4 NOT NULL,
    CONSTRAINT fee_schedules_weeks_ahead_check CHECK ((weeks_ahead >= 4)),
    CONSTRAINT name_check CHECK ((length(name) < 32))
);


--
-- Name: fee_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fee_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fee_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fee_schedules_id_seq OWNED BY fee_schedules.id;


--
-- Name: fees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fees_id_seq OWNED BY fee_rules.id;


--
-- Name: free_times; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE free_times (
    id integer NOT NULL,
    timerange tstzrange NOT NULL,
    oncall_time_id integer NOT NULL,
    duration integer NOT NULL,
    online_visit_allowed text DEFAULT 'not_allowed'::text NOT NULL,
    office_visit_allowed text DEFAULT 'not_allowed'::text NOT NULL,
    area_visit_allowed text DEFAULT 'not_allowed'::text NOT NULL,
    online_visit_fee numeric(4,0) DEFAULT 100 NOT NULL,
    office_visit_fee numeric(4,0) DEFAULT 100 NOT NULL,
    area_visit_fee numeric(4,0) DEFAULT 100 NOT NULL,
    CONSTRAINT area_visit_allowed_check CHECK ((area_visit_allowed = ANY (ARRAY['allowed'::text, 'not_allowed'::text]))),
    CONSTRAINT office_visit_allowed_check CHECK ((office_visit_allowed = ANY (ARRAY['allowed'::text, 'not_allowed'::text]))),
    CONSTRAINT online_visit_allowed_check CHECK ((online_visit_allowed = ANY (ARRAY['allowed'::text, 'not_allowed'::text])))
);


--
-- Name: free_times_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE free_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: free_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE free_times_id_seq OWNED BY free_times.id;


--
-- Name: mailing_lists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mailing_lists (
    email text NOT NULL,
    id integer NOT NULL,
    campaign text NOT NULL
);


--
-- Name: mailing_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mailing_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mailing_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mailing_lists_id_seq OWNED BY mailing_lists.id;


--
-- Name: malpractices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE malpractices (
    id integer NOT NULL,
    policy_number character varying(255) NOT NULL,
    valid_location character varying(255) NOT NULL,
    policy_type character varying(255) NOT NULL,
    coverage_amount integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    specialty character varying(255) NOT NULL,
    doctor_id integer NOT NULL,
    service_delivery text NOT NULL,
    CONSTRAINT malpractices_service_delivery_check CHECK ((service_delivery = ANY (ARRAY['online'::text, 'offline'::text]))),
    CONSTRAINT policy_number_length CHECK ((char_length((policy_number)::text) <= 32)),
    CONSTRAINT policy_type_within CHECK (((policy_type)::text = ANY (ARRAY[('occurrence_based'::character varying)::text, ('claims_made'::character varying)::text]))),
    CONSTRAINT specialty_length CHECK ((char_length((specialty)::text) <= 64)),
    CONSTRAINT valid_location_length CHECK ((char_length((valid_location)::text) = 2))
);


--
-- Name: malpractices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE malpractices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: malpractices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE malpractices_id_seq OWNED BY malpractices.id;


--
-- Name: medical_degrees; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE medical_degrees (
    id integer NOT NULL,
    degree_type character varying(255) NOT NULL,
    awarded_by character varying(255) NOT NULL,
    date_awarded date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT degree_type_within CHECK (((degree_type)::text = ANY (ARRAY[('Allopathic'::character varying)::text, ('Osteopathic'::character varying)::text])))
);


--
-- Name: medical_degrees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE medical_degrees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medical_degrees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE medical_degrees_id_seq OWNED BY medical_degrees.id;


--
-- Name: medical_licenses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE medical_licenses (
    id integer NOT NULL,
    license_number character varying(255) NOT NULL,
    first_issued_date date NOT NULL,
    expiry_date date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    doctor_id integer NOT NULL,
    state_medical_board_id integer NOT NULL,
    CONSTRAINT license_number_length CHECK ((char_length((license_number)::text) <= 20))
);


--
-- Name: medical_licenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE medical_licenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medical_licenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE medical_licenses_id_seq OWNED BY medical_licenses.id;


--
-- Name: medical_schools; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE medical_schools (
    name character varying(255) NOT NULL,
    city character varying(255) NOT NULL,
    country_iso character varying(2) NOT NULL
);


--
-- Name: member_boards; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE member_boards (
    name character varying(64) NOT NULL
);


--
-- Name: npis; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE npis (
    id integer NOT NULL,
    npi_number character varying(255) NOT NULL,
    valid_in character varying(255) NOT NULL,
    issued_date date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    doctor_id integer NOT NULL,
    CONSTRAINT npi_number_length CHECK ((char_length((npi_number)::text) = 10))
);


--
-- Name: npis_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE npis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: npis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE npis_id_seq OWNED BY npis.id;


--
-- Name: office_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE office_locations (
    street_address_1 character varying(64) NOT NULL,
    street_address_2 character varying(64),
    city character varying(32) NOT NULL,
    state character(2) NOT NULL,
    zip_code character(5) NOT NULL,
    id integer NOT NULL,
    country text NOT NULL,
    doctor_id integer
);


--
-- Name: office_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE office_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: office_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE office_locations_id_seq OWNED BY office_locations.id;


--
-- Name: oncall_times_area_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oncall_times_area_locations (
    oncall_times_id integer,
    area_locations_id integer
);


--
-- Name: oncall_times_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oncall_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oncall_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oncall_times_id_seq OWNED BY oncall_times.id;


--
-- Name: oncall_times_office_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oncall_times_office_locations (
    office_location_id integer NOT NULL,
    oncall_time_id integer NOT NULL
);


--
-- Name: oncall_times_online_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oncall_times_online_locations (
    id integer NOT NULL,
    oncall_time_id integer NOT NULL,
    online_location_id integer NOT NULL
);


--
-- Name: oncall_times_online_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oncall_times_online_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oncall_times_online_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oncall_times_online_locations_id_seq OWNED BY oncall_times_online_locations.id;


--
-- Name: online_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE online_locations (
    state character(2) NOT NULL,
    country character(2) NOT NULL,
    id integer NOT NULL,
    state_name text NOT NULL
);


--
-- Name: online_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE online_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: online_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE online_locations_id_seq OWNED BY online_locations.id;


--
-- Name: patients; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE patients (
    id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: patients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE patients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE patients_id_seq OWNED BY patients.id;


--
-- Name: patients_promotions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE patients_promotions (
    id integer NOT NULL,
    patient_id integer NOT NULL,
    promotion_id integer NOT NULL,
    uses_counter integer NOT NULL
);


--
-- Name: patients_promotions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE patients_promotions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patients_promotions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE patients_promotions_id_seq OWNED BY patients_promotions.id;


--
-- Name: phones; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE phones (
    id integer NOT NULL,
    number character varying(255) NOT NULL,
    phone_type character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer NOT NULL,
    CONSTRAINT number_length CHECK ((char_length((number)::text) = 10)),
    CONSTRAINT phone_type_within CHECK (((phone_type)::text = ANY (ARRAY[('home'::character varying)::text, ('mobile'::character varying)::text, ('other'::character varying)::text])))
);


--
-- Name: phones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phones_id_seq OWNED BY phones.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plans (
    id integer NOT NULL,
    plan_id text NOT NULL,
    stripe_seller_id integer NOT NULL,
    fee integer NOT NULL
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plans_id_seq OWNED BY plans.id;


--
-- Name: primary_cities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE primary_cities (
    name character varying(32) NOT NULL
);


--
-- Name: promotions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE promotions (
    discount integer NOT NULL,
    max_uses_per_patient integer NOT NULL,
    name character varying(255),
    promo_code character varying(255) NOT NULL,
    id integer NOT NULL,
    timezone text DEFAULT 'Pacific Time (US & Canada)'::text NOT NULL,
    doctor_id integer NOT NULL,
    applicable_timerange tstzrange NOT NULL,
    bookable_timerange tstzrange NOT NULL,
    applicable text NOT NULL,
    bookable text NOT NULL,
    discount_type text NOT NULL,
    CONSTRAINT promotions_applicable_check CHECK ((applicable = ANY (ARRAY['applicable'::text, 'not_applicable'::text]))),
    CONSTRAINT promotions_bookable_check CHECK ((bookable = ANY (ARRAY['bookable'::text, 'not_bookable'::text]))),
    CONSTRAINT promotions_discount_type_check CHECK ((discount_type = ANY (ARRAY['percentage'::text, 'fixed'::text])))
);


--
-- Name: promotions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE promotions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE promotions_id_seq OWNED BY promotions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: seed_migration_data_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE seed_migration_data_migrations (
    id integer NOT NULL,
    version character varying(255),
    runtime integer,
    migrated_on timestamp without time zone
);


--
-- Name: seed_migration_data_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE seed_migration_data_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seed_migration_data_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE seed_migration_data_migrations_id_seq OWNED BY seed_migration_data_migrations.id;


--
-- Name: specialties; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE specialties (
    name character varying(64) NOT NULL
);


--
-- Name: specialty_member_boards; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE specialty_member_boards (
    id integer NOT NULL,
    specialty character varying(64) NOT NULL,
    board character varying(64) NOT NULL
);


--
-- Name: specialty_member_boards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE specialty_member_boards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: specialty_member_boards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE specialty_member_boards_id_seq OWNED BY specialty_member_boards.id;


--
-- Name: state_medical_boards; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE state_medical_boards (
    name character varying(255) NOT NULL,
    state character(2) NOT NULL,
    country character varying(3) NOT NULL,
    id integer NOT NULL
);


--
-- Name: state_medical_boards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE state_medical_boards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: state_medical_boards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE state_medical_boards_id_seq OWNED BY state_medical_boards.id;


--
-- Name: states; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE states (
    name character varying(255) NOT NULL,
    country_id character varying(3) NOT NULL,
    iso character varying(16) NOT NULL
);


--
-- Name: stripe_customers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stripe_customers (
    id integer NOT NULL,
    customer_id character varying(255) NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: stripe_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stripe_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stripe_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stripe_customers_id_seq OWNED BY stripe_customers.id;


--
-- Name: stripe_events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stripe_events (
    event_id text NOT NULL
);


--
-- Name: stripe_sellers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stripe_sellers (
    id integer NOT NULL,
    user_id integer NOT NULL,
    access_token text NOT NULL,
    scope text NOT NULL,
    livemode text NOT NULL,
    refresh_token text NOT NULL,
    stripe_user_id text NOT NULL,
    stripe_publishable_key text NOT NULL,
    CONSTRAINT livemode_constraint CHECK ((livemode = ANY (ARRAY['true'::text, 'false'::text]))),
    CONSTRAINT scope_constraint CHECK ((scope = ANY (ARRAY['read_write'::text, 'read_only'::text])))
);


--
-- Name: stripe_sellers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stripe_sellers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stripe_sellers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stripe_sellers_id_seq OWNED BY stripe_sellers.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subscriptions (
    stripe_customer_id integer NOT NULL,
    id integer NOT NULL,
    subscription_id text NOT NULL,
    plan_id integer,
    status text NOT NULL,
    address_id integer,
    CONSTRAINT subscriptions_status_check CHECK ((status = ANY (ARRAY['active'::text, 'past_due'::text, 'canceled'::text, 'unpaid'::text])))
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subscriptions_id_seq OWNED BY subscriptions.id;


--
-- Name: temporary_credentials; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE temporary_credentials (
    specialty_opt1 character varying(255) NOT NULL,
    specialty_opt2 character varying(255) NOT NULL,
    license_number character varying(20) NOT NULL,
    doctor_id integer NOT NULL,
    is_general_practice text DEFAULT '0'::text NOT NULL,
    state_medical_board_id integer,
    id integer NOT NULL,
    CONSTRAINT temporary_credentials_is_general_practice_check CHECK ((is_general_practice = ANY (ARRAY['0'::text, '1'::text])))
);


--
-- Name: temporary_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE temporary_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: temporary_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE temporary_credentials_id_seq OWNED BY temporary_credentials.id;


--
-- Name: time_outs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE time_outs (
    timerange tstzrange NOT NULL,
    oncall_time_id integer NOT NULL,
    id integer NOT NULL
);


--
-- Name: time_outs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE time_outs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: time_outs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE time_outs_id_seq OWNED BY time_outs.id;


--
-- Name: tzone; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tzone (
    tzone_name text NOT NULL,
    CONSTRAINT tzone_tzone_name_check CHECK (is_timezone(tzone_name))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    firstname character varying(255) NOT NULL,
    lastname character varying(255) NOT NULL,
    dob date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    gender character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    password_digest character varying(255) NOT NULL,
    authy_id character varying(255) NOT NULL,
    cellphone character varying(50) NOT NULL,
    country_code character varying(5) DEFAULT '1'::character varying NOT NULL,
    slug text NOT NULL,
    password_reset_token character varying,
    password_reset_sent_at timestamp without time zone,
    email_confirmation text DEFAULT 'not_confirmed'::text NOT NULL,
    email_confirmation_token character varying,
    CONSTRAINT firstname_length CHECK ((char_length((firstname)::text) <= 64)),
    CONSTRAINT gender_type CHECK (((gender)::text = ANY (ARRAY[('male'::character varying)::text, ('female'::character varying)::text, ('other'::character varying)::text]))),
    CONSTRAINT lastname_length CHECK ((char_length((lastname)::text) <= 64)),
    CONSTRAINT users_email_confirmation_check CHECK ((email_confirmation = ANY (ARRAY['confirmed'::text, 'not_confirmed'::text])))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: visit_area_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visit_area_locations (
    visit_id integer NOT NULL,
    area_location_id integer NOT NULL
);


--
-- Name: visit_office_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visit_office_locations (
    visit_id integer NOT NULL,
    office_location_id integer NOT NULL
);


--
-- Name: visit_online_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visit_online_locations (
    visit_id integer NOT NULL,
    online_location_id integer NOT NULL
);


--
-- Name: visits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visits (
    id integer NOT NULL,
    session_id text NOT NULL,
    oncall_time_id integer NOT NULL,
    patient_id integer NOT NULL,
    timerange tstzrange NOT NULL,
    fee_paid integer NOT NULL,
    duration integer NOT NULL,
    jurisdiction text DEFAULT 'not_accepted'::text NOT NULL,
    authenticated character varying(1) DEFAULT '0'::character varying NOT NULL,
    CONSTRAINT fee_paid_positive_check CHECK ((fee_paid >= 0)),
    CONSTRAINT visits_jurisdiction_check CHECK ((jurisdiction = ANY (ARRAY['accepted'::text, 'not_accepted'::text])))
);


--
-- Name: visits_area_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visits_area_locations (
    visit_id integer NOT NULL,
    area_location_id integer NOT NULL,
    id integer NOT NULL
);


--
-- Name: visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE visits_id_seq OWNED BY visits.id;


--
-- Name: visits_office_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visits_office_locations (
    visit_id integer NOT NULL,
    office_location_id integer NOT NULL,
    id integer NOT NULL
);


--
-- Name: visits_office_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE visits_office_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visits_office_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE visits_office_locations_id_seq OWNED BY visits_office_locations.id;


--
-- Name: visits_online_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visits_online_locations (
    visit_id integer NOT NULL,
    online_location_id integer NOT NULL,
    id integer NOT NULL
);


--
-- Name: visits_online_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE visits_online_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visits_online_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE visits_online_locations_id_seq OWNED BY visits_online_locations.id;


--
-- Name: visits_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE visits_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visits_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE visits_session_id_seq OWNED BY visits.session_id;


--
-- Name: zip_codes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zip_codes (
    zip character(5) NOT NULL,
    zip_type character varying(8) NOT NULL,
    primary_city character varying(32) NOT NULL,
    state character varying(2) NOT NULL,
    county character varying(64),
    timezone character varying(32),
    area_codes character varying(64),
    latitude double precision,
    longitude double precision,
    country character varying(2),
    decommissioned boolean,
    estimated_population integer,
    notes character varying(255),
    CONSTRAINT zip_length CHECK ((char_length(zip) = 5)),
    CONSTRAINT zip_type_check CHECK (((zip_type)::text = ANY (ARRAY[('STANDARD'::character varying)::text, ('PO BOX'::character varying)::text, ('UNIQUE'::character varying)::text, ('MILITARY'::character varying)::text])))
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_subscriptions ALTER COLUMN id SET DEFAULT nextval('archived_subscriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY area_locations ALTER COLUMN id SET DEFAULT nextval('area_locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY board_certifications ALTER COLUMN id SET DEFAULT nextval('board_certifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY chat_entries ALTER COLUMN id SET DEFAULT nextval('chat_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY doctors ALTER COLUMN id SET DEFAULT nextval('doctors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY fee_rule_times ALTER COLUMN id SET DEFAULT nextval('fee_rule_times_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY fee_rules ALTER COLUMN id SET DEFAULT nextval('fees_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY fee_schedules ALTER COLUMN id SET DEFAULT nextval('fee_schedules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY free_times ALTER COLUMN id SET DEFAULT nextval('free_times_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mailing_lists ALTER COLUMN id SET DEFAULT nextval('mailing_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY malpractices ALTER COLUMN id SET DEFAULT nextval('malpractices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY medical_degrees ALTER COLUMN id SET DEFAULT nextval('medical_degrees_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY medical_licenses ALTER COLUMN id SET DEFAULT nextval('medical_licenses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY npis ALTER COLUMN id SET DEFAULT nextval('npis_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY office_locations ALTER COLUMN id SET DEFAULT nextval('office_locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times ALTER COLUMN id SET DEFAULT nextval('oncall_times_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times_online_locations ALTER COLUMN id SET DEFAULT nextval('oncall_times_online_locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY online_locations ALTER COLUMN id SET DEFAULT nextval('online_locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY patients ALTER COLUMN id SET DEFAULT nextval('patients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY patients_promotions ALTER COLUMN id SET DEFAULT nextval('patients_promotions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phones ALTER COLUMN id SET DEFAULT nextval('phones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plans ALTER COLUMN id SET DEFAULT nextval('plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY promotions ALTER COLUMN id SET DEFAULT nextval('promotions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY seed_migration_data_migrations ALTER COLUMN id SET DEFAULT nextval('seed_migration_data_migrations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY specialty_member_boards ALTER COLUMN id SET DEFAULT nextval('specialty_member_boards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY state_medical_boards ALTER COLUMN id SET DEFAULT nextval('state_medical_boards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY stripe_customers ALTER COLUMN id SET DEFAULT nextval('stripe_customers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY stripe_sellers ALTER COLUMN id SET DEFAULT nextval('stripe_sellers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions ALTER COLUMN id SET DEFAULT nextval('subscriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY temporary_credentials ALTER COLUMN id SET DEFAULT nextval('temporary_credentials_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY time_outs ALTER COLUMN id SET DEFAULT nextval('time_outs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits ALTER COLUMN id SET DEFAULT nextval('visits_id_seq'::regclass);


--
-- Name: session_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits ALTER COLUMN session_id SET DEFAULT nextval('visits_session_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits_office_locations ALTER COLUMN id SET DEFAULT nextval('visits_office_locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits_online_locations ALTER COLUMN id SET DEFAULT nextval('visits_online_locations_id_seq'::regclass);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: archived_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_subscriptions
    ADD CONSTRAINT archived_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: area_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY area_locations
    ADD CONSTRAINT area_locations_pkey PRIMARY KEY (id);


--
-- Name: board_certifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY board_certifications
    ADD CONSTRAINT board_certifications_pkey PRIMARY KEY (id);


--
-- Name: chat_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY chat_entries
    ADD CONSTRAINT chat_entries_pkey PRIMARY KEY (id);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (iso);


--
-- Name: deas_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY deas
    ADD CONSTRAINT deas_pkey PRIMARY KEY (dea_number);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: doctor_id_timerange_bookable_excl; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oncall_times
    ADD CONSTRAINT doctor_id_timerange_bookable_excl EXCLUDE USING gist (doctor_id WITH =, timerange WITH &&) WHERE ((bookable = true));


--
-- Name: doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY doctors
    ADD CONSTRAINT doctors_pkey PRIMARY KEY (id);


--
-- Name: doctors_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY doctors
    ADD CONSTRAINT doctors_user_id_key UNIQUE (user_id);


--
-- Name: fee_rule_times_fee_schedule_id_excl; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fee_rule_times
    ADD CONSTRAINT fee_rule_times_fee_schedule_id_excl EXCLUDE USING gist (fee_schedule_id WITH =, timerange WITH &&);


--
-- Name: fee_rule_times_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fee_rule_times
    ADD CONSTRAINT fee_rule_times_pkey PRIMARY KEY (id);


--
-- Name: fee_rules_fee_schedule_id_day_of_week_time_of_day_range_excl; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fee_rules
    ADD CONSTRAINT fee_rules_fee_schedule_id_day_of_week_time_of_day_range_excl EXCLUDE USING gist (fee_schedule_id WITH =, day_of_week WITH =, time_of_day_range WITH &&);


--
-- Name: fee_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fee_rules
    ADD CONSTRAINT fee_rules_pkey PRIMARY KEY (id);


--
-- Name: fee_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fee_schedules
    ADD CONSTRAINT fee_schedules_pkey PRIMARY KEY (id);


--
-- Name: free_times_oncall_time_id_timerange_exclusion; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY free_times
    ADD CONSTRAINT free_times_oncall_time_id_timerange_exclusion EXCLUDE USING gist (oncall_time_id WITH =, timerange WITH &&);


--
-- Name: free_times_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY free_times
    ADD CONSTRAINT free_times_pkey PRIMARY KEY (id);


--
-- Name: mailing_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mailing_lists
    ADD CONSTRAINT mailing_lists_pkey PRIMARY KEY (id);


--
-- Name: malpractices_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY malpractices
    ADD CONSTRAINT malpractices_pkey PRIMARY KEY (id);


--
-- Name: medical_degrees_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY medical_degrees
    ADD CONSTRAINT medical_degrees_pkey PRIMARY KEY (id);


--
-- Name: medical_licenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY medical_licenses
    ADD CONSTRAINT medical_licenses_pkey PRIMARY KEY (id);


--
-- Name: medical_schools_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY medical_schools
    ADD CONSTRAINT medical_schools_pkey PRIMARY KEY (name, country_iso);


--
-- Name: member_boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY member_boards
    ADD CONSTRAINT member_boards_pkey PRIMARY KEY (name);


--
-- Name: name_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fee_schedules
    ADD CONSTRAINT name_unique UNIQUE (doctor_id, name);


--
-- Name: name_unique_constraint; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY state_medical_boards
    ADD CONSTRAINT name_unique_constraint UNIQUE (name);


--
-- Name: npis_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY npis
    ADD CONSTRAINT npis_pkey PRIMARY KEY (id);


--
-- Name: office_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY office_locations
    ADD CONSTRAINT office_locations_pkey PRIMARY KEY (id);


--
-- Name: oncall_time_timerange_overlap_check; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visits
    ADD CONSTRAINT oncall_time_timerange_overlap_check EXCLUDE USING gist (oncall_time_id WITH =, timerange WITH &&);


--
-- Name: oncall_times_online_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oncall_times_online_locations
    ADD CONSTRAINT oncall_times_online_locations_pkey PRIMARY KEY (id);


--
-- Name: oncall_times_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oncall_times
    ADD CONSTRAINT oncall_times_pkey PRIMARY KEY (id);


--
-- Name: online_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY online_locations
    ADD CONSTRAINT online_locations_pkey PRIMARY KEY (id);


--
-- Name: online_locations_state_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY online_locations
    ADD CONSTRAINT online_locations_state_name_key UNIQUE (state_name);


--
-- Name: patient_id_timerange_overlap_check; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visits
    ADD CONSTRAINT patient_id_timerange_overlap_check EXCLUDE USING gist (patient_id WITH =, timerange WITH &&);


--
-- Name: patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: patients_promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY patients_promotions
    ADD CONSTRAINT patients_promotions_pkey PRIMARY KEY (id);


--
-- Name: patients_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY patients
    ADD CONSTRAINT patients_user_id_key UNIQUE (user_id);


--
-- Name: phones_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phones
    ADD CONSTRAINT phones_pkey PRIMARY KEY (id);


--
-- Name: plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: plans_stripe_seller_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plans
    ADD CONSTRAINT plans_stripe_seller_id_key UNIQUE (stripe_seller_id);


--
-- Name: primary_cities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY primary_cities
    ADD CONSTRAINT primary_cities_pkey PRIMARY KEY (name);


--
-- Name: promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY promotions
    ADD CONSTRAINT promotions_pkey PRIMARY KEY (id);


--
-- Name: promotions_promo_code_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY promotions
    ADD CONSTRAINT promotions_promo_code_key UNIQUE (promo_code);


--
-- Name: seed_migration_data_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY seed_migration_data_migrations
    ADD CONSTRAINT seed_migration_data_migrations_pkey PRIMARY KEY (id);


--
-- Name: specialties_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY specialties
    ADD CONSTRAINT specialties_pkey PRIMARY KEY (name);


--
-- Name: specialty_member_boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY specialty_member_boards
    ADD CONSTRAINT specialty_member_boards_pkey PRIMARY KEY (id);


--
-- Name: state_medical_boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY state_medical_boards
    ADD CONSTRAINT state_medical_boards_pkey PRIMARY KEY (id);


--
-- Name: states_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY states
    ADD CONSTRAINT states_pkey PRIMARY KEY (country_id, iso);


--
-- Name: stripe_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stripe_customers
    ADD CONSTRAINT stripe_customers_pkey PRIMARY KEY (id);


--
-- Name: stripe_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stripe_events
    ADD CONSTRAINT stripe_events_pkey PRIMARY KEY (event_id);


--
-- Name: stripe_sellers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stripe_sellers
    ADD CONSTRAINT stripe_sellers_pkey PRIMARY KEY (id);


--
-- Name: subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: subscriptions_stripe_customer_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_stripe_customer_id_key UNIQUE (stripe_customer_id);


--
-- Name: subscriptions_subscription_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_subscription_id_key UNIQUE (subscription_id);


--
-- Name: temporary_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY temporary_credentials
    ADD CONSTRAINT temporary_credentials_pkey PRIMARY KEY (id);


--
-- Name: time_outs_oncall_time_id_timerange_excl; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY time_outs
    ADD CONSTRAINT time_outs_oncall_time_id_timerange_excl EXCLUDE USING gist (oncall_time_id WITH =, timerange WITH &&);


--
-- Name: time_outs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY time_outs
    ADD CONSTRAINT time_outs_pkey PRIMARY KEY (id);


--
-- Name: tzone_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tzone
    ADD CONSTRAINT tzone_pkey PRIMARY KEY (tzone_name);


--
-- Name: uniqueness; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY specialty_member_boards
    ADD CONSTRAINT uniqueness UNIQUE (specialty, board);


--
-- Name: username_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT username_unique UNIQUE (username);


--
-- Name: users_authy_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_authy_id_key UNIQUE (authy_id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_slug_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_slug_key UNIQUE (slug);


--
-- Name: visits_area_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visits_area_locations
    ADD CONSTRAINT visits_area_locations_pkey PRIMARY KEY (id);


--
-- Name: visits_office_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visits_office_locations
    ADD CONSTRAINT visits_office_locations_pkey PRIMARY KEY (id);


--
-- Name: visits_online_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visits_online_locations
    ADD CONSTRAINT visits_online_locations_pkey PRIMARY KEY (id);


--
-- Name: visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (id);


--
-- Name: visits_session_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visits
    ADD CONSTRAINT visits_session_id_key UNIQUE (session_id);


--
-- Name: zip_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zip_codes
    ADD CONSTRAINT zip_codes_pkey PRIMARY KEY (zip);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: email_campaign; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX email_campaign ON mailing_lists USING btree (email, campaign);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: usr_slug_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX usr_slug_idx ON users USING btree (slug);


--
-- Name: trigger_a_round_times_to_nearest_5_minutes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_a_round_times_to_nearest_5_minutes BEFORE INSERT OR UPDATE ON time_outs FOR EACH ROW EXECUTE PROCEDURE trigger_function_time_round_5_minutes_on_time_outs();


--
-- Name: trigger_b_check_time_out_contained_in_oncall_time; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_b_check_time_out_contained_in_oncall_time BEFORE INSERT OR UPDATE ON time_outs FOR EACH ROW EXECUTE PROCEDURE trigger_function_check_time_out_contained_in_oncall_time();


--
-- Name: trigger_c_regenerate_free_times_on_time_outs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_c_regenerate_free_times_on_time_outs AFTER INSERT OR DELETE OR UPDATE ON time_outs FOR EACH ROW EXECUTE PROCEDURE trigger_function_regenerate_free_times();


--
-- Name: trigger_check_visit_contained_in_oncall_time; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_check_visit_contained_in_oncall_time BEFORE INSERT OR UPDATE ON visits FOR EACH ROW EXECUTE PROCEDURE trigger_function_check_visit_contained_in_oncall_time();


--
-- Name: trigger_create_fee_rule_times; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_create_fee_rule_times AFTER INSERT OR DELETE OR UPDATE ON fee_rules FOR EACH ROW EXECUTE PROCEDURE trigger_function_create_fee_rule_times_on_fee_rules();


--
-- Name: trigger_create_fee_rule_times; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_create_fee_rule_times AFTER INSERT OR DELETE OR UPDATE ON fee_schedules FOR EACH ROW EXECUTE PROCEDURE trigger_function_create_fee_rule_times_on_fee_schedules();


--
-- Name: trigger_regenerate_free_times_on_oncall_times; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_regenerate_free_times_on_oncall_times AFTER INSERT OR DELETE OR UPDATE ON oncall_times FOR EACH ROW EXECUTE PROCEDURE trigger_function_regenerate_free_times();


--
-- Name: trigger_regenerate_free_times_on_visits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_regenerate_free_times_on_visits AFTER INSERT OR DELETE OR UPDATE ON visits FOR EACH ROW EXECUTE PROCEDURE trigger_function_regenerate_free_times();


--
-- Name: trigger_round_times_to_nearest_5_minutes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_round_times_to_nearest_5_minutes BEFORE INSERT OR UPDATE ON fee_rules FOR EACH ROW EXECUTE PROCEDURE trigger_function_time_round_5_minutes_on_fee_rules();


--
-- Name: trigger_round_times_to_nearest_5_minutes_add_duration; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_round_times_to_nearest_5_minutes_add_duration BEFORE INSERT OR UPDATE ON oncall_times FOR EACH ROW EXECUTE PROCEDURE trigger_function_time_round_5_minutes_add_duration();


--
-- Name: trigger_round_times_to_nearest_5_minutes_add_duration; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_round_times_to_nearest_5_minutes_add_duration BEFORE INSERT OR UPDATE ON visits FOR EACH ROW EXECUTE PROCEDURE trigger_function_time_round_5_minutes_add_duration();


--
-- Name: trigger_round_times_to_nearest_5_minutes_add_duration; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_round_times_to_nearest_5_minutes_add_duration BEFORE INSERT OR UPDATE ON free_times FOR EACH ROW EXECUTE PROCEDURE trigger_function_time_round_5_minutes_add_duration();


--
-- Name: addresses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: archived_subscriptions_stripe_seller_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_subscriptions
    ADD CONSTRAINT archived_subscriptions_stripe_seller_id_fkey FOREIGN KEY (stripe_seller_id) REFERENCES stripe_sellers(id);


--
-- Name: archived_subscriptions_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_subscriptions
    ADD CONSTRAINT archived_subscriptions_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES subscriptions(id);


--
-- Name: area_locations_zipcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY area_locations
    ADD CONSTRAINT area_locations_zipcode_fkey FOREIGN KEY (zipcode) REFERENCES zip_codes(zip);


--
-- Name: board_certifications_board_specialty_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY board_certifications
    ADD CONSTRAINT board_certifications_board_specialty_fkey FOREIGN KEY (board_name, specialty) REFERENCES specialty_member_boards(board, specialty);


--
-- Name: board_certifications_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY board_certifications
    ADD CONSTRAINT board_certifications_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: chat_entries_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY chat_entries
    ADD CONSTRAINT chat_entries_session_id_fkey FOREIGN KEY (session_id) REFERENCES visits(session_id);


--
-- Name: deas_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deas
    ADD CONSTRAINT deas_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: doctors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY doctors
    ADD CONSTRAINT doctors_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fee_rule_times_fee_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fee_rule_times
    ADD CONSTRAINT fee_rule_times_fee_schedule_id_fkey FOREIGN KEY (fee_schedule_id) REFERENCES fee_schedules(id);


--
-- Name: fee_rules_fee_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fee_rules
    ADD CONSTRAINT fee_rules_fee_schedule_id_fkey FOREIGN KEY (fee_schedule_id) REFERENCES fee_schedules(id);


--
-- Name: fee_schedule_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times
    ADD CONSTRAINT fee_schedule_fk FOREIGN KEY (fee_schedule_id) REFERENCES fee_schedules(id);


--
-- Name: fee_schedules_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fee_schedules
    ADD CONSTRAINT fee_schedules_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: fee_schedules_time_zone_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fee_schedules
    ADD CONSTRAINT fee_schedules_time_zone_fkey FOREIGN KEY (time_zone) REFERENCES tzone(tzone_name);


--
-- Name: free_times_oncall_time_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY free_times
    ADD CONSTRAINT free_times_oncall_time_id_fkey FOREIGN KEY (oncall_time_id) REFERENCES oncall_times(id) ON DELETE CASCADE;


--
-- Name: malpractices_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY malpractices
    ADD CONSTRAINT malpractices_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: medical_board_states_country_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY state_medical_boards
    ADD CONSTRAINT medical_board_states_country_fkey FOREIGN KEY (country, state) REFERENCES states(country_id, iso);


--
-- Name: medical_licenses_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY medical_licenses
    ADD CONSTRAINT medical_licenses_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: medical_licenses_state_medical_board_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY medical_licenses
    ADD CONSTRAINT medical_licenses_state_medical_board_id_fkey FOREIGN KEY (state_medical_board_id) REFERENCES state_medical_boards(id);


--
-- Name: medical_schools_country_iso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY medical_schools
    ADD CONSTRAINT medical_schools_country_iso_fkey FOREIGN KEY (country_iso) REFERENCES countries(iso);


--
-- Name: npis_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY npis
    ADD CONSTRAINT npis_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: office_locations_country_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY office_locations
    ADD CONSTRAINT office_locations_country_fkey FOREIGN KEY (country) REFERENCES countries(iso);


--
-- Name: office_locations_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY office_locations
    ADD CONSTRAINT office_locations_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: oncall_times_area_locations_area_locations_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times_area_locations
    ADD CONSTRAINT oncall_times_area_locations_area_locations_id_fkey FOREIGN KEY (area_locations_id) REFERENCES area_locations(id);


--
-- Name: oncall_times_area_locations_oncall_times_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times_area_locations
    ADD CONSTRAINT oncall_times_area_locations_oncall_times_id_fkey FOREIGN KEY (oncall_times_id) REFERENCES oncall_times(id);


--
-- Name: oncall_times_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times
    ADD CONSTRAINT oncall_times_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: oncall_times_office_locations_office_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times_office_locations
    ADD CONSTRAINT oncall_times_office_locations_office_location_id_fkey FOREIGN KEY (office_location_id) REFERENCES office_locations(id) ON DELETE RESTRICT;


--
-- Name: oncall_times_office_locations_oncall_time_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times_office_locations
    ADD CONSTRAINT oncall_times_office_locations_oncall_time_id_fkey FOREIGN KEY (oncall_time_id) REFERENCES oncall_times(id) ON DELETE CASCADE;


--
-- Name: oncall_times_online_locations_oncall_time_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times_online_locations
    ADD CONSTRAINT oncall_times_online_locations_oncall_time_id_fkey FOREIGN KEY (oncall_time_id) REFERENCES oncall_times(id) ON DELETE CASCADE;


--
-- Name: oncall_times_online_locations_online_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oncall_times_online_locations
    ADD CONSTRAINT oncall_times_online_locations_online_location_id_fkey FOREIGN KEY (online_location_id) REFERENCES online_locations(id) ON DELETE RESTRICT;


--
-- Name: online_locations_license_state_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY online_locations
    ADD CONSTRAINT online_locations_license_state_fkey FOREIGN KEY (state, country) REFERENCES states(iso, country_id);


--
-- Name: patients_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY patients
    ADD CONSTRAINT patients_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: phones_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phones
    ADD CONSTRAINT phones_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: plans_stripe_seller_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plans
    ADD CONSTRAINT plans_stripe_seller_id_fkey FOREIGN KEY (stripe_seller_id) REFERENCES stripe_sellers(id);


--
-- Name: promotions_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY promotions
    ADD CONSTRAINT promotions_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: specialty_member_boards_board_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY specialty_member_boards
    ADD CONSTRAINT specialty_member_boards_board_fkey FOREIGN KEY (board) REFERENCES member_boards(name);


--
-- Name: specialty_member_boards_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY specialty_member_boards
    ADD CONSTRAINT specialty_member_boards_name_fkey FOREIGN KEY (specialty) REFERENCES specialties(name);


--
-- Name: states_country_iso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY states
    ADD CONSTRAINT states_country_iso_fkey FOREIGN KEY (country_id) REFERENCES countries(iso);


--
-- Name: stripe_customers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY stripe_customers
    ADD CONSTRAINT stripe_customers_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: stripe_sellers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY stripe_sellers
    ADD CONSTRAINT stripe_sellers_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: subscriptions_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_address_id_fkey FOREIGN KEY (address_id) REFERENCES addresses(id);


--
-- Name: subscriptions_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES plans(id);


--
-- Name: subscriptions_stripe_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_stripe_customer_id_fkey FOREIGN KEY (stripe_customer_id) REFERENCES stripe_customers(id);


--
-- Name: temporary_credentials_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY temporary_credentials
    ADD CONSTRAINT temporary_credentials_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES doctors(id);


--
-- Name: temporary_credentials_specialty_opt1_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY temporary_credentials
    ADD CONSTRAINT temporary_credentials_specialty_opt1_fkey FOREIGN KEY (specialty_opt1) REFERENCES specialties(name);


--
-- Name: temporary_credentials_specialty_opt2_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY temporary_credentials
    ADD CONSTRAINT temporary_credentials_specialty_opt2_fkey FOREIGN KEY (specialty_opt2) REFERENCES specialties(name);


--
-- Name: temporary_credentials_state_medical_board_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY temporary_credentials
    ADD CONSTRAINT temporary_credentials_state_medical_board_id_fkey FOREIGN KEY (state_medical_board_id) REFERENCES state_medical_boards(id);


--
-- Name: time_outs_oncall_time_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY time_outs
    ADD CONSTRAINT time_outs_oncall_time_id_fkey FOREIGN KEY (oncall_time_id) REFERENCES oncall_times(id);


--
-- Name: visit_area_locations_area_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visit_area_locations
    ADD CONSTRAINT visit_area_locations_area_location_id_fkey FOREIGN KEY (area_location_id) REFERENCES area_locations(id);


--
-- Name: visit_area_locations_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visit_area_locations
    ADD CONSTRAINT visit_area_locations_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES visits(id);


--
-- Name: visit_office_locations_office_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visit_office_locations
    ADD CONSTRAINT visit_office_locations_office_location_id_fkey FOREIGN KEY (office_location_id) REFERENCES office_locations(id);


--
-- Name: visit_office_locations_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visit_office_locations
    ADD CONSTRAINT visit_office_locations_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES visits(id);


--
-- Name: visit_online_locations_online_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visit_online_locations
    ADD CONSTRAINT visit_online_locations_online_location_id_fkey FOREIGN KEY (online_location_id) REFERENCES online_locations(id);


--
-- Name: visit_online_locations_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visit_online_locations
    ADD CONSTRAINT visit_online_locations_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES visits(id);


--
-- Name: visits_area_locations_area_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits_area_locations
    ADD CONSTRAINT visits_area_locations_area_location_id_fkey FOREIGN KEY (area_location_id) REFERENCES area_locations(id);


--
-- Name: visits_area_locations_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits_area_locations
    ADD CONSTRAINT visits_area_locations_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES visits(id);


--
-- Name: visits_office_locations_office_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits_office_locations
    ADD CONSTRAINT visits_office_locations_office_location_id_fkey FOREIGN KEY (office_location_id) REFERENCES office_locations(id) ON DELETE RESTRICT;


--
-- Name: visits_office_locations_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits_office_locations
    ADD CONSTRAINT visits_office_locations_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES visits(id) ON DELETE CASCADE;


--
-- Name: visits_oncall_time_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits
    ADD CONSTRAINT visits_oncall_time_id_fkey FOREIGN KEY (oncall_time_id) REFERENCES oncall_times(id);


--
-- Name: visits_online_locations_online_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits_online_locations
    ADD CONSTRAINT visits_online_locations_online_location_id_fkey FOREIGN KEY (online_location_id) REFERENCES online_locations(id) ON DELETE RESTRICT;


--
-- Name: visits_online_locations_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits_online_locations
    ADD CONSTRAINT visits_online_locations_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES visits(id) ON DELETE CASCADE;


--
-- Name: visits_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits
    ADD CONSTRAINT visits_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES patients(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20141125223807');

INSERT INTO schema_migrations (version) VALUES ('20141125232854');

INSERT INTO schema_migrations (version) VALUES ('20141126192842');

INSERT INTO schema_migrations (version) VALUES ('20141126192939');

INSERT INTO schema_migrations (version) VALUES ('20141126200200');

INSERT INTO schema_migrations (version) VALUES ('20141126200254');

INSERT INTO schema_migrations (version) VALUES ('20141127062334');

INSERT INTO schema_migrations (version) VALUES ('20141127070800');

INSERT INTO schema_migrations (version) VALUES ('20141130233448');

INSERT INTO schema_migrations (version) VALUES ('20141130234027');

INSERT INTO schema_migrations (version) VALUES ('20141201000902');

INSERT INTO schema_migrations (version) VALUES ('20141202165301');

INSERT INTO schema_migrations (version) VALUES ('20141203152442');

INSERT INTO schema_migrations (version) VALUES ('20141204014022');

INSERT INTO schema_migrations (version) VALUES ('20141204033931');

INSERT INTO schema_migrations (version) VALUES ('20141204035325');

INSERT INTO schema_migrations (version) VALUES ('20141204193935');

INSERT INTO schema_migrations (version) VALUES ('20141204223707');

INSERT INTO schema_migrations (version) VALUES ('20141204224340');

INSERT INTO schema_migrations (version) VALUES ('20141204224741');

INSERT INTO schema_migrations (version) VALUES ('20141204224758');

INSERT INTO schema_migrations (version) VALUES ('20141204224810');

INSERT INTO schema_migrations (version) VALUES ('20141205002513');

INSERT INTO schema_migrations (version) VALUES ('20141208020453');

INSERT INTO schema_migrations (version) VALUES ('20141208021020');

INSERT INTO schema_migrations (version) VALUES ('20141209012414');

INSERT INTO schema_migrations (version) VALUES ('20141209013051');

INSERT INTO schema_migrations (version) VALUES ('20141209015639');

INSERT INTO schema_migrations (version) VALUES ('20141209015756');

INSERT INTO schema_migrations (version) VALUES ('20141209015929');

INSERT INTO schema_migrations (version) VALUES ('20141209020225');

INSERT INTO schema_migrations (version) VALUES ('20141209024132');

INSERT INTO schema_migrations (version) VALUES ('20141209024521');

INSERT INTO schema_migrations (version) VALUES ('20141212171850');

INSERT INTO schema_migrations (version) VALUES ('20141214165121');

INSERT INTO schema_migrations (version) VALUES ('20141214172125');

INSERT INTO schema_migrations (version) VALUES ('20141214195254');

INSERT INTO schema_migrations (version) VALUES ('20141214222759');

INSERT INTO schema_migrations (version) VALUES ('20141214222932');

INSERT INTO schema_migrations (version) VALUES ('20141214223047');

INSERT INTO schema_migrations (version) VALUES ('20141214233840');

INSERT INTO schema_migrations (version) VALUES ('20141215001812');

INSERT INTO schema_migrations (version) VALUES ('20141215015718');

INSERT INTO schema_migrations (version) VALUES ('20141215022111');

INSERT INTO schema_migrations (version) VALUES ('20141215113912');

INSERT INTO schema_migrations (version) VALUES ('20141215150050');

INSERT INTO schema_migrations (version) VALUES ('20141215151445');

INSERT INTO schema_migrations (version) VALUES ('20141215151754');

INSERT INTO schema_migrations (version) VALUES ('20141215152510');

INSERT INTO schema_migrations (version) VALUES ('20141215185543');

INSERT INTO schema_migrations (version) VALUES ('20141215190117');

INSERT INTO schema_migrations (version) VALUES ('20141215194449');

INSERT INTO schema_migrations (version) VALUES ('20141215195041');

INSERT INTO schema_migrations (version) VALUES ('20141215195650');

INSERT INTO schema_migrations (version) VALUES ('20141215200338');

INSERT INTO schema_migrations (version) VALUES ('20141215201753');

INSERT INTO schema_migrations (version) VALUES ('20141215202706');

INSERT INTO schema_migrations (version) VALUES ('20141215220758');

INSERT INTO schema_migrations (version) VALUES ('20141216055004');

INSERT INTO schema_migrations (version) VALUES ('20141216231951');

INSERT INTO schema_migrations (version) VALUES ('20141217002116');

INSERT INTO schema_migrations (version) VALUES ('20141217014200');

INSERT INTO schema_migrations (version) VALUES ('20141217185923');

INSERT INTO schema_migrations (version) VALUES ('20141217192023');

INSERT INTO schema_migrations (version) VALUES ('20141217194031');

INSERT INTO schema_migrations (version) VALUES ('20141218025451');

INSERT INTO schema_migrations (version) VALUES ('20141218195205');

INSERT INTO schema_migrations (version) VALUES ('20141219012236');

INSERT INTO schema_migrations (version) VALUES ('20141219013809');

INSERT INTO schema_migrations (version) VALUES ('20141219175402');

INSERT INTO schema_migrations (version) VALUES ('20141219195132');

INSERT INTO schema_migrations (version) VALUES ('20141219201546');

INSERT INTO schema_migrations (version) VALUES ('20141219205004');

INSERT INTO schema_migrations (version) VALUES ('20141220055602');

INSERT INTO schema_migrations (version) VALUES ('20141220182924');

INSERT INTO schema_migrations (version) VALUES ('20141220185153');

INSERT INTO schema_migrations (version) VALUES ('20141220185236');

INSERT INTO schema_migrations (version) VALUES ('20141220185522');

INSERT INTO schema_migrations (version) VALUES ('20141220185729');

INSERT INTO schema_migrations (version) VALUES ('20141221021913');

INSERT INTO schema_migrations (version) VALUES ('20141221185948');

INSERT INTO schema_migrations (version) VALUES ('20141222175402');

INSERT INTO schema_migrations (version) VALUES ('20141223184612');

INSERT INTO schema_migrations (version) VALUES ('20141223204800');

INSERT INTO schema_migrations (version) VALUES ('20141223211947');

INSERT INTO schema_migrations (version) VALUES ('20141223214415');

INSERT INTO schema_migrations (version) VALUES ('20141223214850');

INSERT INTO schema_migrations (version) VALUES ('20141226222026');

INSERT INTO schema_migrations (version) VALUES ('20150102181603');

INSERT INTO schema_migrations (version) VALUES ('20150102182531');

INSERT INTO schema_migrations (version) VALUES ('20150104200739');

INSERT INTO schema_migrations (version) VALUES ('20150104204526');

INSERT INTO schema_migrations (version) VALUES ('20150104211648');

INSERT INTO schema_migrations (version) VALUES ('20150105013001');

INSERT INTO schema_migrations (version) VALUES ('20150106201750');

INSERT INTO schema_migrations (version) VALUES ('20150106235525');

INSERT INTO schema_migrations (version) VALUES ('20150107152652');

INSERT INTO schema_migrations (version) VALUES ('20150107185712');

INSERT INTO schema_migrations (version) VALUES ('20150108184258');

INSERT INTO schema_migrations (version) VALUES ('20150108185140');

INSERT INTO schema_migrations (version) VALUES ('20150108185655');

INSERT INTO schema_migrations (version) VALUES ('20150108213303');

INSERT INTO schema_migrations (version) VALUES ('20150113020537');

INSERT INTO schema_migrations (version) VALUES ('20150113024154');

INSERT INTO schema_migrations (version) VALUES ('20150113032004');

INSERT INTO schema_migrations (version) VALUES ('20150113032515');

INSERT INTO schema_migrations (version) VALUES ('20150113212840');

INSERT INTO schema_migrations (version) VALUES ('20150114003844');

INSERT INTO schema_migrations (version) VALUES ('20150114175818');

INSERT INTO schema_migrations (version) VALUES ('20150114184856');

INSERT INTO schema_migrations (version) VALUES ('20150114190132');

INSERT INTO schema_migrations (version) VALUES ('20150114212428');

INSERT INTO schema_migrations (version) VALUES ('20150114235556');

INSERT INTO schema_migrations (version) VALUES ('20150117220814');

INSERT INTO schema_migrations (version) VALUES ('20150118021505');

INSERT INTO schema_migrations (version) VALUES ('20150118023001');

INSERT INTO schema_migrations (version) VALUES ('20150118153036');

INSERT INTO schema_migrations (version) VALUES ('20150118154016');

INSERT INTO schema_migrations (version) VALUES ('20150118170445');

INSERT INTO schema_migrations (version) VALUES ('20150119185739');

INSERT INTO schema_migrations (version) VALUES ('20150125015419');

INSERT INTO schema_migrations (version) VALUES ('20150125184122');

INSERT INTO schema_migrations (version) VALUES ('20150125233654');

INSERT INTO schema_migrations (version) VALUES ('20150125234452');

INSERT INTO schema_migrations (version) VALUES ('20150125235306');

INSERT INTO schema_migrations (version) VALUES ('20150126010509');

INSERT INTO schema_migrations (version) VALUES ('20150126044652');

INSERT INTO schema_migrations (version) VALUES ('20150126062146');

INSERT INTO schema_migrations (version) VALUES ('20150127210203');

INSERT INTO schema_migrations (version) VALUES ('20150127232431');

INSERT INTO schema_migrations (version) VALUES ('20150128001846');

INSERT INTO schema_migrations (version) VALUES ('20150128194447');

INSERT INTO schema_migrations (version) VALUES ('20150129015103');

INSERT INTO schema_migrations (version) VALUES ('20150207190428');

INSERT INTO schema_migrations (version) VALUES ('20150208050256');

INSERT INTO schema_migrations (version) VALUES ('20150209190840');

INSERT INTO schema_migrations (version) VALUES ('20150209212706');

INSERT INTO schema_migrations (version) VALUES ('20150211232158');

INSERT INTO schema_migrations (version) VALUES ('20150212011747');

INSERT INTO schema_migrations (version) VALUES ('20150212013751');

INSERT INTO schema_migrations (version) VALUES ('20150212020954');

INSERT INTO schema_migrations (version) VALUES ('20150212195809');

INSERT INTO schema_migrations (version) VALUES ('20150213000141');

INSERT INTO schema_migrations (version) VALUES ('20150213030257');

INSERT INTO schema_migrations (version) VALUES ('20150213233607');

INSERT INTO schema_migrations (version) VALUES ('20150214000105');

INSERT INTO schema_migrations (version) VALUES ('20150214001458');

INSERT INTO schema_migrations (version) VALUES ('20150214010933');

INSERT INTO schema_migrations (version) VALUES ('20150214013327');

INSERT INTO schema_migrations (version) VALUES ('20150218013838');

INSERT INTO schema_migrations (version) VALUES ('20150218041208');

INSERT INTO schema_migrations (version) VALUES ('20150218191516');

INSERT INTO schema_migrations (version) VALUES ('20150218192250');

INSERT INTO schema_migrations (version) VALUES ('20150218194810');

INSERT INTO schema_migrations (version) VALUES ('20150222232043');

INSERT INTO schema_migrations (version) VALUES ('20150223003018');

INSERT INTO schema_migrations (version) VALUES ('20150223010310');

INSERT INTO schema_migrations (version) VALUES ('20150223012128');

INSERT INTO schema_migrations (version) VALUES ('20150223054918');

INSERT INTO schema_migrations (version) VALUES ('20150223071518');

INSERT INTO schema_migrations (version) VALUES ('20150223074455');

INSERT INTO schema_migrations (version) VALUES ('20150224023938');

INSERT INTO schema_migrations (version) VALUES ('20150224030340');

INSERT INTO schema_migrations (version) VALUES ('20150224181957');

INSERT INTO schema_migrations (version) VALUES ('20150224190212');

INSERT INTO schema_migrations (version) VALUES ('20150224204739');

INSERT INTO schema_migrations (version) VALUES ('20150224225945');

INSERT INTO schema_migrations (version) VALUES ('20150225012334');

INSERT INTO schema_migrations (version) VALUES ('20150225164141');

INSERT INTO schema_migrations (version) VALUES ('20150225234243');

INSERT INTO schema_migrations (version) VALUES ('20150302214504');

INSERT INTO schema_migrations (version) VALUES ('20150308005522');

INSERT INTO schema_migrations (version) VALUES ('20150308050607');

INSERT INTO schema_migrations (version) VALUES ('20150310054625');

INSERT INTO schema_migrations (version) VALUES ('20150310061341');

INSERT INTO schema_migrations (version) VALUES ('20150312031512');

INSERT INTO schema_migrations (version) VALUES ('20150316221553');

INSERT INTO schema_migrations (version) VALUES ('20150316232329');

INSERT INTO schema_migrations (version) VALUES ('20150316234250');

INSERT INTO schema_migrations (version) VALUES ('20150316235949');

INSERT INTO schema_migrations (version) VALUES ('20150317020349');

INSERT INTO schema_migrations (version) VALUES ('20150319164503');

INSERT INTO schema_migrations (version) VALUES ('20150322000130');

INSERT INTO schema_migrations (version) VALUES ('20150408155841');

INSERT INTO schema_migrations (version) VALUES ('20150408175141');

INSERT INTO schema_migrations (version) VALUES ('20150409010606');

INSERT INTO schema_migrations (version) VALUES ('20150409021435');

INSERT INTO schema_migrations (version) VALUES ('20150409163553');

INSERT INTO schema_migrations (version) VALUES ('20150409181057');

INSERT INTO schema_migrations (version) VALUES ('20150410183123');

INSERT INTO schema_migrations (version) VALUES ('20150420224331');

INSERT INTO schema_migrations (version) VALUES ('20150423001717');

INSERT INTO schema_migrations (version) VALUES ('20150423004846');

INSERT INTO schema_migrations (version) VALUES ('20150505193641');

INSERT INTO schema_migrations (version) VALUES ('20150507001633');

INSERT INTO schema_migrations (version) VALUES ('20150507002728');

INSERT INTO schema_migrations (version) VALUES ('20150507230433');

INSERT INTO schema_migrations (version) VALUES ('20150515001127');

INSERT INTO schema_migrations (version) VALUES ('20150515002732');

INSERT INTO schema_migrations (version) VALUES ('20150515005744');

INSERT INTO schema_migrations (version) VALUES ('20150518181933');

INSERT INTO schema_migrations (version) VALUES ('20150518201634');

INSERT INTO schema_migrations (version) VALUES ('20150518202827');

INSERT INTO schema_migrations (version) VALUES ('20150518203312');

INSERT INTO schema_migrations (version) VALUES ('20150519004943');

INSERT INTO schema_migrations (version) VALUES ('20150525224031');

INSERT INTO schema_migrations (version) VALUES ('20150526000149');

INSERT INTO schema_migrations (version) VALUES ('20150526013829');

INSERT INTO schema_migrations (version) VALUES ('20150527015130');

INSERT INTO schema_migrations (version) VALUES ('20150603203618');

INSERT INTO schema_migrations (version) VALUES ('20150604171632');

INSERT INTO schema_migrations (version) VALUES ('20150608183121');

INSERT INTO schema_migrations (version) VALUES ('20150610224245');

INSERT INTO schema_migrations (version) VALUES ('20150629175954');

INSERT INTO schema_migrations (version) VALUES ('20150629225648');

INSERT INTO schema_migrations (version) VALUES ('20150630040130');

INSERT INTO schema_migrations (version) VALUES ('20150630225301');

INSERT INTO schema_migrations (version) VALUES ('20150702004855');

INSERT INTO schema_migrations (version) VALUES ('20150703094205');

INSERT INTO schema_migrations (version) VALUES ('20150704053421');

INSERT INTO schema_migrations (version) VALUES ('20150714232000');

INSERT INTO schema_migrations (version) VALUES ('20150720044256');

INSERT INTO schema_migrations (version) VALUES ('20150728181104');

INSERT INTO schema_migrations (version) VALUES ('20150803034236');

INSERT INTO schema_migrations (version) VALUES ('20150816040502');

INSERT INTO schema_migrations (version) VALUES ('20150917182016');

INSERT INTO schema_migrations (version) VALUES ('20150917213743');

INSERT INTO schema_migrations (version) VALUES ('20150922230834');

INSERT INTO schema_migrations (version) VALUES ('20150922232325');

INSERT INTO schema_migrations (version) VALUES ('20150923174451');

INSERT INTO schema_migrations (version) VALUES ('20150923180246');

INSERT INTO schema_migrations (version) VALUES ('20150923192355');

INSERT INTO schema_migrations (version) VALUES ('20150923230708');

INSERT INTO schema_migrations (version) VALUES ('20150924011423');

INSERT INTO schema_migrations (version) VALUES ('20151008231749');

INSERT INTO schema_migrations (version) VALUES ('20151013231800');

INSERT INTO schema_migrations (version) VALUES ('20151020185554');

INSERT INTO schema_migrations (version) VALUES ('20151020230411');

INSERT INTO schema_migrations (version) VALUES ('20151027234250');

INSERT INTO schema_migrations (version) VALUES ('20151028171907');

INSERT INTO schema_migrations (version) VALUES ('20151103193845');

