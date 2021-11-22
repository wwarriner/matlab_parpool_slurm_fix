# MATLAB `parpool` SLURM Fix

The `.m` file in this repository contains a function intended to fix the behavior of MATLAB `parpool` when used on a cluster environment.

The fix described here is intended as a workaround! It is not a totally robust fix and there is a caveat to its use under "How it Works".

## How to Use

Ensure the `.m` file is on the MATLAB `path`. In most cases this means copying it to the folder where your code is. Then, in your code, before running anything else, call `patchJobStorageLocation()`. This will affect the default, i.e. `"local"`, cluster profile.

If you are not using the `"local"` profile, call `patchJobStorageLocation(profile_name)` where `profile_name` is the name of your cluster profile.

## How it Works

A folder with a universally unique random name, based on `java.util.UUID.randomUUID`, is created inside the existing `JobStorageLocation` of the selected profile. This is then set as the `JobStorageLocation` for your user and for your current session only. This means each MATLAB session you create will use its own distinct location for `parpool` files, sidestepping the race condition.

### The Caveat

The approach will cause a proliferation of folders and files in your `$HOME/.matlab/` folder which may need to be cleared out periodically. The file size should be relatively small per use, but it may add up quickly on a cluster.

## The Underlying Issue

Starting from at latest R2016b and running to at least R2021b, MATLAB assumes that only one `parpool` will be created per user on the same system. The way `parpool` works is by copying necessary files for each worker to a static location in the cluster's `JobStorageLocation`, e.g. `$HOME/.matlab/<profile_name>_cluster_jobs/<version>/`, and starting an instance of MATLAB for each worker.

If a cluster user starts multiple MATLAB instances simultaneously, as with `sbatch --array`, race conditions on certain files in the `JobStorageLocation` of the used cluster profile can occur. This can lead to file corruption and `parpool` failing to start or erroring out. Worst-case it can permanently corrupt the `JobStorageLocation` folder, requiring it to be deleted to start fresh.
