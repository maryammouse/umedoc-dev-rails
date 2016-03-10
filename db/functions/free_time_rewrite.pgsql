create or replace function function_oncall_times_free_times_regenerate(oncall_time oncall_times) returns void as
    $function_body
        declare
            oct_frt record;
            pft_tr tstzrange;
            pft record;
            visit visits%ROWTYPE;
            free_start_time timestamptz;
            free_end_time timestamptz;
            counter int :=0;

        begin
            delete from free_times where oncall_time_id = oncall_time.id;
            raise notice 'deleted free_times with oncall_time_id %', oncall_time.id;

            if oncall_time.bookable = TRUE then
                for oct_frt in
                    select oct.timerange as oct_tr,
                        oct.id as oct_id,
                        frt.timerange as frt_tr,
                        frt.id as frt_id,
                        oct.fee_schedule_id
                    from oncall_times as oct inner join fee_rule_times as frt
                    on (oct.fee_schedule_id = frt.fee_schedule_id)
                    where frt.timerange && oct.timerange
                    loop
                        pft_tr = oct_frt.oct_tr * oct_frt.frt_tr; -- '*' is the intersection operator in this context

                        if (select count(*) from visits
                                where visit.oncall_time_id = oct_frt.oct_id and
                                    visit.timerange && pft_tr) = 0
                            then
                                insert into free_times (oncall_time_id, timerange)
                                        values (oncall_time.id, pft_tr);
                                counter = counter + 1;
                                raise notice 'inserted free_times # % with oncall_time_id %', counter, oncall_time.id;
                                return;
                        else
                            free_start_time := lower(pft_tr);
                            for visit in
                                select * from visits
                                    where visit.oncall_time_id = oct_frt.oct_id and
                                        visit.timerange && pft_tr
                                    loop
                                        free_end_time := lower(visit.timerange);
                                                if (free_end_time - free_start_time) >= interval '5 minutes' then
                                                    insert into free_times (oncall_time_id, timerange)
                                                                        values (oncall_time.id, tstzrange(free_start_time, free_end_time));
                                                    counter = counter + 1;
                                                    raise notice 'inserted free_times # % with oncall_time_id %', counter, oncall_time.id;
                                                end if;
                                                free_start_time = upper(visit.timerange);
                                    end loop;

                                    free_end_time = upper(pft_tr);
                                    if (free_end_time - free_start_time) >= interval '5 minutes' then
                                        insert into free_times (oncall_time_id, timerange)
                                                            values (oncall_time.id, tstzrange(free_start_time, free_end_time));
                                        counter = counter + 1;
                                        raise notice 'inserted free_times # % with oncall_time_id %', counter, oncall_time.id;
                                    end if;
                        end if;
                    end loop;
            end if;
        end;
    $function_body$ language plpgsql;
