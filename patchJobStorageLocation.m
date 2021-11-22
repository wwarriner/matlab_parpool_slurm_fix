function patchJobStorageLocation(profile_name)
% This function should be called before any PCT code is executed in a MATLAB
% session (perhaps by a suitable startup.m file at MATLAB startup?). It will
% create a UUID subfolder in the `JobStorageLocation` for the cluster profile
% with `profile_name` and use that as the new `JobStorageLocation`. It will do
% this only in the current session for the current user.

% Copyright 2016 The MathWorks, Inc.
% Modified by William Warriner, 18 Nov 2021

if nargin < 1
    profile_name = "local";
end

profile_name = string(profile_name);
assert(isscalar(profile_name));

try
    % Check to see if PCT is installed. If not simply return early as there
    % is nothing to do.
    if ~exist("parpool", "file")
        return;
    end

    % Make sure that this can run in normal MATLAB as well as deployed MCR's.
    % Some of the code below checks that we are in a deployed (or overriden)
    % MATLAB, so do this first.
    if ~(isdeployed || parallel.internal.settings.qeDeployedOverride)
        parallel.internal.settings.qeDeployedOverride(true);
    end

    % Search for requested profile.
    S = parallel.Settings;
    profiles = S.findProfile();
    profile = [];
    for index = 1 : numel(profiles)
        if profile_name == profiles(index).Name
            profile = profiles(index);
        end
    end
    if isempty(profile)
        error("Unable to locate cluster profile with name: %s", profile_name);
    end
    
    % Get the job_storage_location from the request profile.
    scheduler = profile.getSchedulerComponent;
    if ~isprop(scheduler, "JobStorageLocation")
        % error
    end
    job_storage_location = get(scheduler, 'JobStorageLocation', 'user');
    if ~ischar(job_storage_location)
        local_profile = parallel.cluster.Local;
        job_storage_location = local_profile.JobStorageLocation;
    end
    
    % Set the UUID subfolder.
    uuid = java.util.UUID.randomUUID.toString;
    uuid = string(uuid);
    uuid_storage_location = fullfile(job_storage_location, uuid);
    [~, ~, ~] = mkdir(uuid_storage_location);
    set(scheduler, 'JobStorageLocation', uuid_storage_location, 'session')
catch e
    disp(getReport(e));
end

end