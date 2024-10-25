function res = rct2_qc_one_session(path_in)

    % params
    crit_min_duration = 15;

    % defaults
    res = struct;
    res.path_in = path_in;
    res.rct2_qc_one_session_suc = false;
    res.rct2_qc_one_session_oc = 'unknown error';

    % attempt to load session
    
        teTitle('RCT2 EEG QC report\n\n');
        teEcho('[rct2_qc_one_session]: Inspecting: %s\n\n', path_in);

        [is, reason, file_tracker, tracker] = teIsSession(path_in);
        if ~is
            fprintf(2, '[rct2_qc_one_session]: Couldn''t read data: %s\n', reason)
            res.rct2_qc_one_session_load_session_error = reason;
            return
        else
            teEcho('[rct2_qc_one_session]: Valid task engine session ✓\n');
            res.rct2_qc_one_session_load_session_error = 'none';
        end

    % instantiate a session object using this data
    
        ses = teSession('tracker', tracker);
        ses.Paths('session') = path_in;
        ses.DiscoverExternalData;

        % look for enobio data
        if ismember('enobio', ses.ExternalData.Keys)
           
            % report data found
            teEcho('[rct2_qc_one_session]: Has enobio data ✓\n');
            res.rct2_qc_one_session_load_enobio_error = 'none';
            
            % attempt to load
            ext_enobio = ses.ExternalData('enobio');
            path_easy = ext_enobio.Paths('enobio_easy');
            try
                ft = eegEnobio2Fieldtrip(path_easy);
            catch ERR_load_enobio
                fprintf(2, '[rct2_qc_one_session]: Load enobio data ✗\n');
                res.rct2_qc_one_session_load_enobio_error =...
                    ERR_load_enobio.message;    
            end
            
            % read metadata
            
                % 20 channels of data
                res.rct2_qc_one_session_enobio_num_channels =...
                    ft.enobio_hdr.numChans;
                if ft.enobio_hdr.numChans == 20
                    res.rct2_qc_one_session_enobio_correct_num_channels = true;
                    teEcho('[rct2_qc_one_session]: Has 20 channels of enobio data ✓\n'); 
                else
                    res.rct2_qc_one_session_enobio_correct_num_channels = false;
                    fprintf(2, '[rct2_qc_one_session]: Has %d channels of enobio data ✗\n',...
                        ft.enobio_hdr.numChans);
                end
                
                % duration
                duration_mins = (ft.enobio_hdr.numSamples ./ ft.enobio_hdr.fs) / 60;
                res.rct2_qc_one_session_enobio_duration_mins = duration_mins;
                if duration_mins > crit_min_duration
                    res.rct2_qc_one_session_enobio_short_duration = false;
                    teEcho('[rct2_qc_one_session]: Enobio duration is %.1f mins ✓\n',...
                        duration_mins);           
                else
                    res.rct2_qc_one_session_enobio_short_duration = true;
                    fprintf(2, '[rct2_qc_one_session]: Short enobio duration: %.1f mins ✗\n',...
                        duration_mins);                    
                end
                
                % events
                has_events_struct = isfield(ft, 'events');
                if has_events_struct
                    res.rct2_qc_one_session_enobio_events_struct_present = true;
                    teEcho('[rct2_qc_one_session]: Enobio events struct present ✓\n');
                else
                    res.rct2_qc_one_session_enobio_events_struct_present = false;
                    fprintf(2, '[rct2_qc_one_session]: Enobio events struct missing ✗\n');
                end                
                
                % num events -- at least 500
                num_events = length(ft.events);
                res.rct2_qc_one_session_enobio_num_events = num_events;
                if num_events > 500
                    res.rct2_qc_one_session_enobio_low_events = false;
                    teEcho('[rct2_qc_one_session]: Has %d Enobio events ✓\n',...
                        num_events);
                else
                    res.rct2_qc_one_session_enobio_low_events = false;
                    fprintf(2, '[rct2_qc_one_session]: Has only %d Enobio events ✗\n',...
                        num_events);
                end                          
                
                % num 255 events (dropouts)
                num_dropouts = sum([ft.events.value] == 255);
                res.rct2_qc_one_session_enobio_num_dropouts = num_dropouts;
                if num_dropouts == 0
                    res.rct2_qc_one_session_enobio_has_dropouts = false;
                    teEcho('[rct2_qc_one_session]: Enobio data has no dropouts ✓\n');
                else
                    res.rct2_qc_one_session_enobio_has_dropouts = true;
                    fprintf(2, '[rct2_qc_one_session]: Enobio data has %d wifi dropouts ✗\n',...
                        num_dropouts);
                end                    
                
        end

    res.rct2_qc_one_session_suc = true;
    res.rct2_qc_one_session_oc = 'ok';

end

