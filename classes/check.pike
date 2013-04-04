#charset utf8 

inherit Fins.FinsBase;
inherit "metadata_constants":foo;

object log = Tools.Logging.get_logger("scanner");


static void create(object app)
{
  ::create(app);
}

class ID3 {
     inherit ADT.Struct;
     Item head = Chars(3);
     Item title = Chars(30);
     Item artist = Chars(30);
     Item album = Chars(30);
     Item year = Chars(4);
     Item comment = Chars(30);
     Item genre = Byte();
   }

class mon
{
  inherit Filesystem.Monitor.symlinks;

   ADT.Queue delete_queue = ADT.Queue();
   ADT.Queue create_queue = ADT.Queue();
   ADT.Queue exists_queue = ADT.Queue();
   ADT.History history = ADT.History(25);
   object db; 
   
   int should_quit = 0;
   
   // our filesystem monitor uses 2 threads:
   //   1 - a thread to run the actual filesystem check
   //   2 - a thread to process the changes to the filesystem
   //
   //  1 exists in order to prevent the main thread from getting bogged
   //  down when a large number of files exist to monitor and the second
   //  thread is used to minimise the amount of time spent initializing 
   //  the monitor, as the monitor won't see changes until it finishes 
   //  flagging all existing files.
   static void create(mixed ... args)
   {
     symlinks::create(@args);
    Thread.Thread(run_process_thread);
    set_nonblocking(3);
  }
   
   void stop()
   {
     should_quit = 1;
     sleep(3);
   }
   
   void run_process_thread()
   {
//werror("starting run_process_thread()\n");
     while(!should_quit)
     {
       sleep(2);
// werror("running process_entries()\n");
       catch(m->process_entries());
     }
   }

  mapping read_id3(string path, object f)
  {
    mapping m;
    object t;
    if(catch(t = Standards.ID3.Tag(Stdio.File(path))))
      return 0;
    
    m = t->friendly_values();
    if(!sizeof(m))
      m->title = (basename(path)/".")[0];
//werror("t: %O\n", t);    
    if(t->frame_map && t->frame_map["TLEN"])
    {
//      werror("%O\n", t->frame_map["TLEN"][0]->data->value);
      m->length = t->frame_map["TLEN"][0]->data->value;
    }
    if(t->frame_map && t->frame_map["TP1"])
    {
    //      werror("%O\n", t->frame_map["TLEN"][0]->data->value);
      m->artist = (t->frame_map["TP1"][0]->data->data)-"\0";
    }

    m = map(m, lambda(mixed v){return (stringp(v)?String.trim_whites(v):v);});

    // genres seem to be either a string containing the genre name, an integer or an integer 
    // surrounded by parens. we try to sort out this insanity here.
    if(m && has_index(m, "genre")){
 //     werror("genre: %O\n", m->genre);
      int genre;
      if(sscanf(m->genre, "%*[\(]%d)", genre))
        m->genre = id3_genres[(int)m->genre] || "Unknown Genre";
    }

    return m;
  }

// if the file doesn't have a play length in its tags,
// we can use ffmpeg, if it's available.
// ffmpeg -i 
// alternately, we can use get_mp3_length, but it's slow.
// on osx, there's afinfo, too.
int use_ffmpeg;
int use_afinfo;
int length_method_checked;
int get_length(string filename, int ismp3)
{
  if(!length_method_checked)
  {
    use_afinfo = app->have_command("afinfo");
    use_ffmpeg = app->have_command("ffmpeg");;
    if(use_afinfo) log->info("Using afinfo for playtime extraction.");
    if(use_ffmpeg) log->info("Using ffmpeg for playtime extraction.");
    length_method_checked = 1;
  }

  if(use_afinfo)
  { 
    return get_afinfo_length(filename);
  }
  else if(use_ffmpeg)
  {
    return get_ffmpeg_length(filename);
  }
  else if(ismp3)
  {
    return get_mp3_length(filename);
  }
  else return 0;
 
}

int get_ffmpeg_length(string filename)
{
  string len;
  Stdio.File stdin = Stdio.File();
  object si = stdin->pipe();
  Stdio.File stderr = Stdio.File();
  object se = stderr->pipe();
  int o = Process.system("ffmpeg -i \"" + filename + "\"", 0, si, se);
  string output = stderr->read(1000, 1);
  //output += stdin->read();
  sscanf(output, "%*sDuration: %s,%*s", len);
  int h,m;
  float s;
  sscanf(len, "%d:%d:%f", h,m,s);

  int ms = (int)(((h*3600) + (m*60) + s) * 1000);
// werror("=> %d\n", ms);
  return ms;
}

int get_afinfo_length(string filename)
{
//	werror("reading length via afinfo...");
  float len;
/*
  Stdio.File stdin = Stdio.File();
  object si = stdin->pipe();
  Stdio.File stderr = Stdio.File();
  object se = stderr->pipe();
  int o = Process.system("afinfo \"" + filename + "\"", 0, si, se);
  string output = stderr->read(1000, 1);
  output += stdin->read(1000, 1);
*/
  string output = Process.popen("afinfo \"" + filename + "\" 2>&1");
  if(!sizeof(output)) return 0;
  sscanf(output, "%*suration: %f sec", len);

  int ms = (int)(len * 1000);
//werror("done.\n");
  return ms;
}

int get_mp3_length(string filename)
{
  mapping d;
  object o = Audio.Format.MP3();
  werror("getting length for %O", filename);
  float len = 0.0;
  o->read_file(filename);
  while(d = o->get_frame())
  {
   int frame_size;
   if(d->layer == 1) frame_size = 384;
   else frame_size = 1152;
   len += (float)frame_size/(float)d->sampling;
  }

  werror(" => %d\n", ((int)len*1000));
  return (int)(len * 1000);
}  

  void process_entries()
  {
	
    while(!delete_queue->is_empty())
    {
      if(should_quit) return;
//werror("pulling from delete queue.\n");
      low_file_deleted(@delete_queue->read());
    }
    
    while(!exists_queue->is_empty())
    {
      if(should_quit) return;
//	werror("pulling from exists queue.\n");
      low_file_exists(@exists_queue->read());      
    }
    
    while(!create_queue->is_empty())
    {
      if(should_quit) return;
//	werror("pulling from create queue.\n");
      low_file_created(@create_queue->read());      
    }
  }

  void file_deleted(string p, Stdio.Stat s)
  {
      delete_queue->write(({p, s}));
  }
  
  void file_created(string p, Stdio.Stat s)
  {
    create_queue->write(({p, s}));
    
  }
  
  void file_exists(string p, Stdio.Stat s)
  {
    log->debug("adding file %s to scan queue.", p);
    exists_queue->write(({p, s}));
    
  }
  
  void low_file_deleted(string p, Stdio.Stat s)
  {
    log->debug("file deleted: %O", p);
    history->push(sprintf("file deleted: %O", p));
    db->remove(p);
  }
  
  void low_file_created(string p, Stdio.Stat s)
  {
    log->debug("file created: %O", p);
    history->push(sprintf("file created: %O", p));
    file_exists(p, s);
  }

  void low_file_exists(string p, Stdio.Stat s)
  {
    mapping atts = ([]);
    if(s->isdir) return;
    if(!s->isdir && s->isreg)
    {
	    history->push(sprintf("file updated: %O", p));
      mapping a;
      if(a = read_id3(p, s))
      {
        atts = atts + a;
	      if(!atts->length) atts->length = get_length(p, 1);
      }
      else if(a = read_atoms(p, s))
      {
        string field;
        if(a->moov && a->moov->udta && a->moov->udta->meta)
        {
          a = a->moov->udta->meta;
        }
        foreach(a->ilst||([]);string key; mixed val)
        {
          
          if(field = atom_map[key])
            atts[field] = val;
   //     else werror("unknown atom %O\n", atom);
        }
        
//werror("atom atts: %O\n", atts);
      }
      
      if(sizeof(atts))
      {  
	if(!atts->length) atts->length = get_length(p, 0);
        if(atts->track && stringp(atts->track))
        {
          int tracknum, trackcount;
          sscanf(atts->track, "%d of %d", tracknum, trackcount);
          if(tracknum)
            atts->track = (string)tracknum;
          if(trackcount)
            atts->trackcount = (string)trackcount;
        }
        else if(atts->track && arrayp(atts->track))
        {
          if(sizeof(atts->track) > 1)
            atts->trackcount = (string)atts->track[1];
          atts->track = (string)atts->track[0];
        }
      //  werror("metadata: %O\n", atts);
      }
    }

    if(sizeof(atts))
    {
      atts["path"] = p;
      atts["size"] = file_stat(p)->size;
      atts["modified"] = file_stat(p)->mtime;
      if(db) 
        db->add(atts);
    }
   else werror("SCAN ERROR: %s\n", p);
  }
}

mapping read_atoms(string p, object s)
{
   object atomsmasher = (object)"atoms";
   
   mapping m;
   mixed e = catch(m = atomsmasher->parse(p));
   if(e) werror("atomsmasher error: %O\n", e[0]);
   //werror("%O\n", m);
   return m;
}

object m;

void check(string path, object db)
{
  m = mon(Filesystem.Monitor.basic.MF_RECURSE);
  m->db = db;
  m->monitor(path, Filesystem.Monitor.basic.MF_RECURSE);
  log->info("registering music path " + path);
  call_out(m->check, 5.0);
}

void stop()
{
  m->stop();
}

void destroy()
{
  stop();
  destruct(m);
}

int main()
{
  m = mon(Filesystem.Monitor.basic.MF_RECURSE);
//  m->monitor("/Users/hww3/Music/iTunes/iTunes Media/Music", FS.Monitor.basic.MF_RECURSE);
//  m->set_nonblocking();

  return -1;  
}

