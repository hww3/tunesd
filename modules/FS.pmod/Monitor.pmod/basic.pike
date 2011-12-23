#pike __REAL_VERSION__

#if constant(Public.System.FSEvents.EventStream)
#define HAVE_EVENTSTREAM 1
#endif

#if HAVE_EVENTSTREAM
import Public.System;
FSEvents.EventStream eventstream = FSEvents.EventStream(({}), 3.0, FSEvents.kFSEventStreamEventIdSinceNow, FSEvents.kFSEventStreamCreateFlagNone);
  array eventstream_paths = ({});
  void eventstream_callback(string path, int flags, int event_id)
  {
    if(path[-1] == '/') path = path[0..<1];
    if(monitors[path])
    {
//      werror("have a monitor for %O!\n", path);
      monitors[path]->check(0);
    }
    else check(0);
  }
#endif

//
// Basic filesystem monitor.
//
//
// 2009-07-09 Henrik Grubbstr�m
//
//! Basic filesystem monitor.
//!
//! This module is intended to be used for incremental scanning of
//! a filesystem.

//! The default maximum number of seconds between checks of directories
//! in seconds.
//!
//! This value is multiplied with @[default_file_interval_factor] to
//! get the corresponding default maximum number of seconds for files.
//!
//! The value can be changed by calling @[create()].
//!
//! The value can be overridden for individual files or directories
//! by calling @[monitor()].
//!
//! Overload this constant to change the default.
protected constant default_max_dir_check_interval = 60;

//! The default factor to multiply @[default_max_dir_check_interval]
//! with to get the maximum number of seconds between checks of files.
//!
//! The value can be changed by calling @[create()].
//!
//! The value can be overridden for individual files or directories
//! by calling @[monitor()].
//!
//! Overload this constant to change the default.
protected constant default_file_interval_factor = 5;

//! The default minimum number of seconds without changes for a change
//! to be regarded as stable (see @[stable_data_change()].
protected constant default_stable_time = 5;

protected int max_dir_check_interval = default_max_dir_check_interval;
protected int file_interval_factor = default_file_interval_factor;
protected int stable_time = default_stable_time;

// Callbacks

//! File content changed callback.
//!
//! @param path
//!   Path of the file which has had content changed.
//!
//! This function is called when a change has been detected for a
//! monitored file.
//!
//! Called by @[check()] and @[check_monitor()].
//!
//! Overload this to do something useful.
void data_changed(string path);

//! File attribute changed callback.
//!
//! @param path
//!   Path of the file or directory which has changed attributes.
//!
//! @param st
//!   Status information for @[path] as obtained by @expr{file_stat(path, 1)@}.
//!
//! This function is called when a change has been detected for an
//! attribute for a monitored file or directory.
//!
//! Called by @[check()] and @[check_monitor()].
//!
//! @note
//!   If there is a @[data_changed()] callback, it may supersede this
//!   callback if the file content also has changed.
//!
//! Overload this to do something useful.
void attr_changed(string path, Stdio.Stat st);

//! File existance callback.
//!
//! @param path
//!   Path of the file or directory.
//!
//! @param st
//!   Status information for @[path] as obtained by @expr{file_stat(path, 1)@}.
//!
//! This function is called during initialization for all monitored paths,
//! and subpaths for monitored directories. It represents the initial state
//! for the monitor.
//!
//! @note
//!   For directories, @[file_created()] will be called for the subpaths
//!   before the call for the directory itself. This can be used to detect
//!   when the initialization for a directory is finished.
//!
//! Called by @[check()] and @[check_monitor()] the first time a monitored
//! path is checked (and only if it exists).
//!
//! Overload this to do something useful.
void file_exists(string path, Stdio.Stat st);

//! File creation callback.
//!
//! @param path
//!   Path of the new file or directory.
//!
//! @param st
//!   Status information for @[path] as obtained by @expr{file_stat(path, 1)@}.
//!
//! This function is called when either a monitored path has started
//! existing, or when a new file or directory has been added to a
//! monitored directory.
//!
//! Called by @[check()] and @[check_monitor()].
//!
//! Overload this to do something useful.
void file_created(string path, Stdio.Stat st);

//! File deletion callback.
//!
//! @param path
//!   Path of the new file or directory that has been deleted.
//!
//! This function is called when either a monitored path has stopped
//! to exist, or when a file or directory has been deleted from a
//! monitored directory.
//!
//! Called by @[check()] and @[check_monitor()].
//!
//! Overload this to do something useful.
void file_deleted(string path);

//! Stable change callback.
//!
//! @param path
//!   Path of the file or directory that has stopped changing.
//!
//! @param st
//!   Status information for @[path] as obtained by @expr{file_stat(path, 1)@}.
//!
//! This function is called when previous changes to @[path] are
//! considered "stable".
//!
//! "Stable" in this case means that there have been no detected
//! changes for at lease @[stable_time] seconds.
//!
//! Called by @[check()] and @[check_monitor()].
//!
//! Overload this to do something useful.
void stable_data_change(string path, Stdio.Stat st);

//! Flags for @[Monitor]s.
enum MonitorFlags {
  MF_RECURSE = 1,
  MF_AUTO = 2,
  MF_INITED = 4,
  MF_HARD = 8,
};

protected constant S_IFMT = 0x7ffff000;

//! Monitoring information for a single filesystem path.
//!
//! @seealso
//!   @[monitor()]
protected class Monitor(string path,
			MonitorFlags flags,
			int max_dir_check_interval,
			int file_interval_factor,
			int stable_time)
{
  int next_poll;
  Stdio.Stat st;
  int last_change = 0x7fffffff;	// Future...
  array(string) files;

  int `<(mixed m) { return next_poll < m; }
  int `>(mixed m) { return next_poll > m; }

  void create()
  {
#if HAVE_EVENTSTREAM
werror("***** eventstream\n");
    int already_added = 0;
    foreach(eventstream_paths;;string p)
    {
      if(has_prefix(path, p))
        already_added = 1;
    }
    if(already_added) return;
    eventstream_paths += ({path});
    if(eventstream->is_started())
      eventstream->stop();
    eventstream->add_path(path);
    eventstream->start();
#endif    
  }

  //! Call a notification callback.
  //!
  //! @param cb
  //!   Callback to call or @[UNDEFINED] for no operation.
  //!
  //! @param path
  //!   Path to notify on.
  //!
  //! @param st
  //!   Stat for the @[path].
  protected void call_callback(function(string, Stdio.Stat|void:void) cb,
			       string path, Stdio.Stat|void st)
  {
    if (!cb) return;
    cb(path, st);
  }

  //! File attribute or content changed callback.
  //!
  //! @param st
  //!   Status information for @[path] as obtained by
  //!   @expr{file_stat(path, 1)@}.
  //!
  //! This function is called when a change has been detected for an
  //! attribute for a monitored file or directory.
  //!
  //! Called by @[check()] and @[check_monitor()].
  //!
  //! @note
  //!   If there is a @[data_changed()] callback, it may supersede this
  //!   callback if the file content also has changed.
  protected void attr_changed(string path, Stdio.Stat st)
  {
    if (global::data_changed) {
      call_callback(global::data_changed, path);
    } else {
      call_callback(global::attr_changed, path, st);
    }
  }

  //! File existance callback.
  //!
  //! @param st
  //!   Status information for @[path] as obtained by
  //!   @expr{file_stat(path, 1)@}.
  //!
  //! This function is called during initialization for all monitored paths,
  //! and subpaths for monitored directories. It represents the initial state
  //! for the monitor.
  //!
  //! @note
  //!   For directories, @[file_created()] will be called for the subpaths
  //!   before the call for the directory itself. This can be used to detect
  //!   when the initialization for a directory is finished.
  //!
  //! Called by @[check()] and @[check_monitor()] the first time a monitored
  //! path is checked (and only if it exists).
  protected void file_exists(string path, Stdio.Stat st)
  {
    call_callback(global::file_exists, path, st);
  }

  //! File creation callback.
  //!
  //! @param st
  //!   Status information for @[path] as obtained by
  //!   @expr{file_stat(path, 1)@}.
  //!
  //! This function is called when either a monitored path has started
  //! existing, or when a new file or directory has been added to a
  //! monitored directory.
  //!
  //! Called by @[check()] and @[check_monitor()].
  protected void file_created(string path, Stdio.Stat st)
  {
    call_callback(global::file_created, path, st);
  }

  //! File deletion callback.
  //!
  //! @param path
  //!   Path of the new file or directory that has been deleted.
  //!
  //! @param old_st
  //!   Stat for the file prior to deletion (if known). Note that
  //!   this argument is not passed along to top level function.
  //!
  //! This function is called when either a monitored path has stopped
  //! to exist, or when a file or directory has been deleted from a
  //! monitored directory.
  //!
  //! Called by @[check()] and @[check_monitor()].
  protected void file_deleted(string path, Stdio.Stat|void old_st)
  {
    call_callback(global::file_deleted, path);
  }

  //! Stable change callback.
  //!
  //! @param st
  //!   Status information for @[path] as obtained by
  //!   @expr{file_stat(path, 1)@}.
  //!
  //! This function is called when previous changes to @[path] are
  //! considered "stable".
  //!
  //! "Stable" in this case means that there have been no detected
  //! changes for at lease @[stable_time] seconds.
  //!
  //! Called by @[check()] and @[check_monitor()].
  protected void stable_data_change(string path, Stdio.Stat st)
  {
    call_callback(global::stable_data_change, path, st);
  }

  protected string _sprintf(int c)
  {
    return sprintf("Monitor(%O, %O, next: %s, st: %O)",
		   path, flags, ctime(next_poll) - "\n", st);
  }

  //! Bump the monitor to an earlier scan time.
  //!
  //! @param seconds
  //!   Number of seconds to bump. Defaults to @expr{30@}.
  void bump(int|void flags, int|void seconds)
  {
    next_poll -= seconds || 30;
    monitor_queue->adjust(this);

    if ((flags & MF_RECURSE) && st->isdir && files) {
      // Bump the files in the directory as well.
      foreach(files, string file) {
	file = canonic_path(Stdio.append_path(path, file));
	Monitor m2 = monitors[file];
	if (m2) {
	  m2->bump(flags, seconds);
	}
      }
    }
  }

  //! Calculate and set a suitable time for the next poll of this monitor.
  //!
  //! @param st
  //!   New stat for the monitor.
  //!
  //! This function is called by @[check()] to schedule the
  //! next check.
  protected void update(Stdio.Stat st)
  {
    int delta = max_dir_check_interval || global::max_dir_check_interval;
    this_program::st = st;
    if (!st || !st->isdir) {
      delta *= file_interval_factor || global::file_interval_factor;
    }
    if (!next_poll) {
      // Attempt to distribute polls evenly at startup.
      delta = 1 + random(delta);
    }
    if (st) {
      int d = 1 + ((time(1) - st->mtime)>>8);
      if (d < 0) d = max_dir_check_interval || global::max_dir_check_interval;
      if (d < delta) delta = d;
      d = 1 + ((time(1) - st->ctime)>>8);
      if (d < 0) d = max_dir_check_interval || global::max_dir_check_interval;
      if (d < delta) delta = d;
    }
    if (last_change <= time(1)) {
      // Time until stable.
      int d = last_change + (stable_time || global::stable_time) - time(1);
      d >>= 1;
      if (d < 0) d = 1;
      if (d < delta) delta = d;
    }
    next_poll = time(1) + (delta || 1);
    monitor_queue->adjust(this);
  }

  //! Check if this monitor should be removed automatically.
  void check_for_release(int mask, int flags)
  {
    if ((this_program::flags & mask) == flags) {
      m_delete(monitors, path);
      release_monitor(this);
    }
  }

  //! Called to create a sub monitor.
  protected void monitor(string path, int flags, int max_dir_interval,
			 int file_interval_factor, int stable_time)
  {
    global::monitor(path, flags, max_dir_check_interval,
		    file_interval_factor, stable_time);
  }

  //! Called when the status has changed for an existing file.
  protected int(0..1) status_change(Stdio.Stat old_st, Stdio.Stat st,
				    int orig_flags, int flags)
  {
    if (st->isdir) {
      array(string) files = get_dir(path) || ({});
      array(string) new_files = files;
      array(string) deleted_files = ({});
      if (this_program::files) {
	new_files -= this_program::files;
	deleted_files = this_program::files - files;
      }
      this_program::files = files;
      foreach(new_files, string file) {
	file = canonic_path(Stdio.append_path(path, file));
	Monitor m2 = monitors[file];
	mixed err = catch {
	    if (m2) {
	      // We have a separate monitor on the created file.
	      // Let it handle the notification.
	      m2->check(flags);
	    }
	  };
	if (this_program::flags & MF_RECURSE) {
	  monitor(file, orig_flags | MF_AUTO | MF_HARD,
		  max_dir_check_interval,
		  file_interval_factor,
		  stable_time);
	  monitors[file]->check();
	} else if (!m2) {
	  file_created(file, file_stat(file, 1));
	}
      }
      foreach(deleted_files, string file) {
	file = canonic_path(Stdio.append_path(path, file));
	Monitor m2 = monitors[file];
	mixed err = catch {
	    if (m2) {
	      // We have a separate monitor on the deleted file.
	      // Let it handle the notification.
	      m2->check(flags);
	    }
	  };
	if (this_program::flags & MF_RECURSE) {
	  // The monitor for the file has probably removed itself,
	  // or the user has done it by hand, in either case we
	  // don't need to do anything more here.
	} else if (!m2) {
	  file_deleted(file);
	}
	if (err) throw(err);
      }
      if (flags & MF_RECURSE) {
	// Check the remaining files in the directory soon.
	foreach(((files - new_files) - deleted_files), string file) {
	  file = canonic_path(Stdio.append_path(path, file));
	  Monitor m2 = monitors[file];
	  if (m2) {
	    m2->bump(flags);
	  }
	}
      }
      if (sizeof(new_files) || sizeof(deleted_files)) return 1;
    } else {
      attr_changed(path, st);
      return 1;
    }
    return 0;
  }

  //! Check for changes.
  //!
  //! @param flags
  //!   @int
  //!     @value 0
  //!       Don't recurse.
  //!     @value 1
  //!       Check all monitors for the entire subtree rooted in @[m].
  //!   @endint
  //!
  //! This function is called by @[check()] for the @[Monitor]s
  //! it considers need checking. If it detects any changes an
  //! appropriate callback will be called.
  //!
  //! @returns
  //!   Returns @expr{1@} if a change was detected and @expr{0@} (zero)
  //!   otherwise.
  //!
  //! @note
  //!   Any callbacks will be called from the same thread as the one
  //!   calling @[check_monitor()].
  //!
  //! @note
  //!   The return value can not be trusted to return @expr{1@} for all
  //!   detected changes in recursive mode.
  //!
  //! @seealso
  //!   @[check()], @[data_changed()], @[attr_changed()], @[file_created()],
  //!   @[file_deleted()], @[stable_data_change()]
  int(0..1) check(MonitorFlags|void flags)
  {
     werror("Checking monitor %O...\n", this);
    Stdio.Stat st = file_stat(path, 1);
    Stdio.Stat old_st = this_program::st;
    int orig_flags = this_program::flags;
    this_program::flags |= MF_INITED;
    update(st);
    if (!(orig_flags & MF_INITED)) {
      // Initialize.
      if (st) {
	if (st->isdir) {
	  array(string) files = get_dir(path) || ({});
	  this_program::files = files;
	  foreach(files, string file) {
	    file = canonic_path(Stdio.append_path(path, file));
	    if (monitors[file]) {
	      // There's already a monitor for the file.
	      // Assume it has already notified about existance.
	      continue;
	    }
	    if (this_program::flags & MF_RECURSE) {
	      monitor(file, orig_flags | MF_AUTO | MF_HARD,
		      max_dir_check_interval,
		      file_interval_factor,
		      stable_time);
	      check_monitor(monitors[file]);
	    } else {
	      file_exists(file, file_stat(file, 1));
	    }
	  }
	}
	// Signal file_exists for path as an end marker.
	file_exists(path, st);
      }
      return 1;
    }
    if (old_st) {
      if (!st || ((old_st->mode & S_IFMT) != (st->mode & S_IFMT))) {
	// File deleted or changed type.

	int delay;
	// Propagate deletions to any submonitors.
	if (files) {
	  foreach(files, string file) {
	    file = canonic_path(Stdio.append_path(path, file));
	    if (monitors[file]) {
	      // Adjust next_poll, so that the monitor will be checked soon.
	      monitors[file]->next_poll = time(1)-1;
	      monitor_queue->adjust(monitors[file]);
	      delay = 1;
	    }
	  }
	}
	if (delay) {
	  // Delay the notification until the submonitors have notified.
	  st = old_st;
	  next_poll = time(1);
	  monitor_queue->adjust(this);
	} else {
	  if (st) {
	    // Avoid race when a file has been replaced with a directory
	    // or vice versa or similar.
	    st = UNDEFINED;

	    // We will catch the new file at the next poll.
	    next_poll = time(1);
	    monitor_queue->adjust(this);
	  } else {
	    // The monitor no longer has a link from its parent directory.
	    this_program::flags &= ~MF_HARD;

	    // Check if we should remove the monitor.
	    check_for_release(MF_AUTO, MF_AUTO);
	  }

	  file_deleted(path, old_st);
	  return 1;
	}
	return 0;
      }
    } else if (st) {
      // File created.

      last_change = time(1);
      file_created(path, st);
      if (st->isdir) {
	array(string) files = get_dir(path) || ({});
	this_program::files = files;
	foreach(files, string file) {
	  file = canonic_path(Stdio.append_path(path, file));
	  if (monitors[file]) {
	    // There's already a monitor for the file.
	    // Assume it has already notified about existance.
	    continue;
	  }
	  if (this_program::flags & MF_RECURSE) {
	    monitor(file, orig_flags | MF_AUTO | MF_HARD,
		    max_dir_check_interval,
		    file_interval_factor,
		    stable_time);
	    check_monitor(monitors[file]);
	  } else {
	    file_created(file, file_stat(file, 1));
	  }
	}
      }
      return 1;
    } else {
      return 0;
    }
    
    //  Note: ctime seems to change unexpectedly when running ImageMagick
    //        on NFS disk so we disable it for the moment [bug 5587].
    if ((st->mtime != old_st->mtime) ||
	/* (st->ctime != old_st->ctime) || */
	(st->size != old_st->size)) {
      last_change = time(1);
      if (status_change(old_st, st, orig_flags, flags)) return 1;
    }
    if ((flags & MF_RECURSE) && (st->isdir)) {
      // Check the files in the directory soon.
      foreach(files, string file) {
	file = canonic_path(Stdio.append_path(path, file));
	Monitor m2 = monitors[file];
	if (m2) {
	  m2->bump(flags);
	}
      }
    }
    if (last_change < time(1) - (stable_time || global::stable_time)) {
      last_change = 0x7fffffff;
      stable_data_change(path, st);
      return 1;
    }
    return 0;
  }
}

//! Canonicalize a path.
//!
//! @param path
//!   Path to canonicalize.
//!
//! @returns
//!   The default implementation returns @expr{combine_path(path, ".")@},
//!   i.e. no trailing slashes.
protected string canonic_path(string path)
{
  return combine_path(path, ".");
}

//! Mapping from monitored path to corresponding @[Monitor].
//!
//! The paths are normalized to @expr{canonic_path(path)@},
//!
//! @note
//!   All filesystems are handled as if case-sensitive. This should
//!   not be a problem for case-insensitive filesystems as long as
//!   case is maintained.
protected mapping(string:Monitor) monitors = ([]);

//! Heap containing all active @[Monitor]s.
//!
//! The heap is sorted on @[Monitor()->next_poll].
protected ADT.Heap monitor_queue = ADT.Heap();

//! Create a new monitor.
//!
//! @param max_dir_check_interval
//!   Override of @[default_max_dir_check_interval].
//!
//! @param file_interval_factor
//!   Override of @[default_file_interval_factor].
//!
//! @param stable_time
//!   Override of @[default_stable_time].
protected void create(int|void max_dir_check_interval,
		      int|void file_interval_factor,
		      int|void stable_time)
{
#if HAVE_EVENTSTREAM
  eventstream->callback_func = eventstream_callback;
#endif  
  
  if (max_dir_check_interval > 0) {
    this_program::max_dir_check_interval = max_dir_check_interval;
  }
  if (file_interval_factor > 0) {
    this_program::file_interval_factor = file_interval_factor;
  }
  if (stable_time > 0) {
    this_program::stable_time = stable_time;
  }
  clear();
}

//! Clear the set of monitored files and directories.
//!
//! @note
//!   Due to circular datastructures, it's recomended
//!   to call this function prior to discarding the object.
void clear()
{
  monitors = ([]);
  monitor_queue = ADT.Heap();
}

//! Calculate a suitable time for the next poll of this monitor.
//!
//! @param m
//!   Monitor to update.
//!
//! @param st
//!   New stat for the monitor.
//!
//! This function is called by @[check_monitor()] to schedule the
//! next check.
protected void update_monitor(Monitor m, Stdio.Stat st)
{
  m->update(st);
}

//! Release a single @[Monitor] from monitoring.
//!
//! @seealso
//!   @[release()]
protected void release_monitor(Monitor m)
{
  m->next_poll = -1000;
  monitor_queue->adjust(m);
  while (monitor_queue->peek() < 0) {
#if __VERSION__ < 7.8
    monitor_queue->top();
#else
    monitor_queue->pop();
#endif
  }
}

//! Create a new @[Monitor] for a @[path].
//!
//! This function is called by @[monitor()] to create a new @[Monitor]
//! object.
//!
//! The default implementation just calls @[Monitor()] with the same
//! arguments.
//!
//! @seealso
//!   @[monitor()]
protected Monitor monitor_factory(string path, MonitorFlags|void flags,
				  int(0..)|void max_dir_check_interval,
				  int(0..)|void file_interval_factor,
				  int(0..)|void stable_time)
{
  werror("monitor_factory(%O)\n", path);
  return Monitor(path, flags, max_dir_check_interval,
		 file_interval_factor, stable_time);
}


//! Register a @[path] for monitoring.
//!
//! @param path
//!   Path to monitor.
//!
//! @param flags
//!   @int
//!     @value 0
//!       Don't recurse.
//!     @value 1
//!       Monitor the entire subtree, and any directories
//!       or files that may appear later.
//!     @value 3
//!       Monitor the entire subtree, and any directories
//!       or files that may appear later. Remove the monitor
//!       automatically when @[path] is deleted.
//!   @endint
//!
//! @param max_dir_check_interval
//!   Override of @[default_max_dir_check_interval] for this path
//!   or subtree.
//!
//! @param file_interval_factor
//!   Override of @[default_file_interval_factor] for this path
//!   or subtree.
//!
//! @param stable_time
//!   Override of @[default_stable_time] for this path
//!   or subtree.
//!
//! @seealso
//!   @[release()]
void monitor(string path, MonitorFlags|void flags,
	     int(0..)|void max_dir_check_interval,
	     int(0..)|void file_interval_factor,
	     int(0..)|void stable_time)
{
werror("monitor\n");
  path = canonic_path(path);
  Monitor m = monitors[path];
  if (m) {
    if (!(flags & MF_AUTO)) {
      // The new monitor is added by hand.
      // Adjust the monitor.
      m->flags = flags;
      m->max_dir_check_interval = max_dir_check_interval;
      m->file_interval_factor = file_interval_factor;
      m->stable_time = stable_time;
      m->next_poll = 0;
      monitor_queue->adjust(m);
    }
    if (flags & MF_HARD) {
      m->flags |= MF_HARD;
    }
    // For the other cases there's no need to do anything,
    // since we can keep the monitor as-is.
  } else {
    m = monitor_factory(path, flags, max_dir_check_interval,
			file_interval_factor, stable_time);
    monitors[path] = m;
    monitor_queue->push(m);
  }
}

//! Release a @[path] from monitoring.
//!
//! @param path
//!   Path to stop monitoring.
//!
//! @param flags
//!   @int
//!     @value 0
//!       Don't recurse.
//!     @value 1
//!       Release the entire subtree.
//!     @value 3
//!       Release the entire subtree, but only those paths that were
//!       added automatically by a recursive monitor.
//!   @endint
//!
//! @seealso
//!   @[monitor()]
void release(string path, MonitorFlags|void flags)
{
  path = canonic_path(path);
  Monitor m = m_delete(monitors, path);
  if (m) {
    release_monitor(m);
  }
  if (flags && m->st && m->st->isdir) {
    if (!sizeof(path) || path[-1] != '/') {
      path += "/";
    }
    foreach(monitors; string mpath; m) {
      if (has_prefix(mpath, path)) {
	m->check_for_release(flags, flags);
      }
    }
  }
}

//! Check whether a path is monitored or not.
//!
//! @param path
//!   Path to check.
//!
//! @returns
//!   Returns @expr{1@} if there is a monitor on @[path],
//!   and @expr{0@} (zero) otherwise.
//!
//! @seealso
//!   @[monitor()], @[release()]
int(0..1) is_monitored(string path)
{
  return !!monitors[canonic_path(path)];
}

//! Check a single @[Monitor] for changes.
//!
//! @param m
//!   @[Monitor] to check.
//!
//! @param flags
//!   @int
//!     @value 0
//!       Don't recurse.
//!     @value 1
//!       Check all monitors for the entire subtree rooted in @[m].
//!   @endint
//!
//! This function is called by @[check()] for the @[Monitor]s
//! it considers need checking. If it detects any changes an
//! appropriate callback will be called.
//!
//! @returns
//!   Returns @expr{1@} if a change was detected and @expr{0@} (zero)
//!   otherwise.
//!
//! @note
//!   Any callbacks will be called from the same thread as the one
//!   calling @[check_monitor()].
//!
//! @note
//!   The return value can not be trusted to return @expr{1@} for all
//!   detected changes in recursive mode.
//!
//! @seealso
//!   @[check()], @[data_changed()], @[attr_changed()], @[file_created()],
//!   @[file_deleted()], @[stable_data_change()]
protected int(0..1) check_monitor(Monitor m, MonitorFlags|void flags)
{
  return m->check(flags);
}

//! Check for changes.
//!
//! @param max_wait
//!   Maximum time in seconds to wait for changes. @expr{-1@}
//!   for infinite wait.
//!
//! @param max_cnt
//!   Maximum number of paths to check in this call. @expr{0@}
//!   (zero) for unlimited.
//!
//! @param ret_stats
//!   Optional mapping that will be filled with statistics (see below).
//!
//! A suitable subset of the monitored files will be checked
//! for changes.
//!
//! @returns
//!   The function returns when either a change has been detected
//!   or when @[max_wait] has expired. The returned value indicates
//!   the number of seconds until the next call of @[check()].
//!
//!   If @[ret_stats] has been provided, it will be filled with
//!   the following entries:
//!   @mapping
//!     @member int "num_monitors"
//!       The total number of active monitors when the scan completed.
//!     @member int "scanned_monitors"
//!       The number of monitors that were scanned for updates during the call.
//!     @member int "updated_monitors"
//!       The number of monitors that were updated during the call.
//!     @member int "idle_time"
//!       The number of seconds that the call slept.
//!   @endmapping
//!
//! @note
//!   Any callbacks will be called from the same thread as the one
//!   calling @[check()].
//!
//! @seealso
//!   @[monitor()]
int check(int|void max_wait, int|void max_cnt,
	  mapping(string:int)|void ret_stats)
{
werror("check\n");
  int scan_cnt = max_cnt;
  int scan_wait = max_wait;
  while(1) {
    int ret = max_dir_check_interval;
    int cnt;
    int t = time();
    if (sizeof(monitors)) {
      Monitor m;
      while ((m = monitor_queue->peek()) && (m->next_poll <= t)) {
	cnt += check_monitor(m);
	if (!(--scan_cnt)) {
	  m = monitor_queue->peek();
	  break;
	}
      }
      if (m) {
	ret = m->next_poll - t;
	if (ret <= 0) ret = 1;
      } else {
	scan_cnt--;
      }
    }
    if (cnt || !scan_wait || !scan_cnt) {
      if (ret_stats) {
	ret_stats->num_monitors = sizeof(monitors);
	ret_stats->scanned_monitors = max_cnt - scan_cnt;
	ret_stats->updated_monitors = cnt;
	ret_stats->idle_time = max_wait - scan_wait;
      }
      return ret;
    }
    if (ret < scan_wait) {
      scan_wait -= ret;
      sleep(ret);
    } else {
      if (scan_wait > 0) scan_wait--;
      sleep(1);
    }
  }
}

//! Backend to use.
//!
//! If @expr{0@} (zero) - use the default backend.
protected Pike.Backend backend;

//! Call-out identifier for @[backend_check()] if in
//! nonblocking mode.
//!
//! @seealso
//!   @[set_nonblocking()], @[set_blocking()]
protected mixed co_id;

//! Change backend.
//!
//! @param backend
//!   Backend to use. @expr{0@} (zero) for the default backend.
void set_backend(Pike.Backend|void backend)
{
  int was_nonblocking = !!co_id;
  set_blocking();
  this_program::backend = backend;
  if (was_nonblocking) {
    set_nonblocking();
  }
}

//! Turn off nonblocking mode.
//!
//! @seealso
//!   @[set_nonblocking()]
void set_blocking()
{
werror("blocking\n");
  if (co_id) {
    if (backend) backend->remove_call_out(co_id);
    else remove_call_out(co_id);
    co_id = 0;
  }
}

//! Backend check callback function.
//!
//! This function is intended to be called from a backend,
//! and performs a @[check()] followed by rescheduling
//! itself via a call to @[set_nonblocking()].
//!
//! @seealso
//!   @[check()], @[set_nonblocking()]
protected void backend_check()
{
  co_id = 0;
  int t;
  mixed err = catch {
      t = check(0);
    };
#if HAVE_EVENTSTREAM
// if we are using FSEvents, we don't want to run this check more than once to prime the pumps.
#else
  set_nonblocking(t);
#endif
  if (err) throw(err);
}

//! Turn on nonblocking mode.
//!
//! @param t
//!   Suggested time in seconds until next call of @[check()].
//!
//! Register suitable callbacks with the backend to automatically
//! call @[check()].
//!
//! @[check()] and thus all the callbacks will be called from the
//! backend thread.
//!
//! @note
//!   If nonblocking mode is already active, this function will
//!   be a noop.
//!
//! @seealso
//!   @[set_blocking()], @[check()].
void set_nonblocking(int|void t)
{
  werror("**** set_nonblocking(%d)\n", t);
  if (co_id) return;
  if (zero_type(t)) {
    Monitor m = monitor_queue->peek();
    t = (m && m->next_poll - time(1)) || max_dir_check_interval;
    if (t > max_dir_check_interval) t = max_dir_check_interval;
    if (t < 0) t = 0;
  }
//  if (backend) co_id = backend->call_out(backend_check, t);
//  else co_id = call_out(backend_check, t);
}

//! Set the @[default_max_dir_check_interval].
void set_max_dir_check_interval(int max_dir_check_interval)
{
  if (max_dir_check_interval > 0) {
    this_program::max_dir_check_interval = max_dir_check_interval;
  } else {
    this_program::max_dir_check_interval = default_max_dir_check_interval;
  }
}

//! Set the @[default_file_interval_factor].
void set_file_interval_factor(int file_interval_factor)
{
  if (file_interval_factor > 0) {
    this_program::file_interval_factor = file_interval_factor;
  } else {
    this_program::file_interval_factor = default_file_interval_factor;
  }
}

