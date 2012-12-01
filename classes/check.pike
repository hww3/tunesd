#charset utf8 

inherit Fins.FinsBase;

object log = Tools.Logging.get_logger("scanner");


constant id3v2_map = ([
    "TALB": "album",
    "TIT2": "title",
    "TPE1": "artist",
    "TYER": "year",
    "TRCK": "track",
    "COMM": "comment",
    "TCON": "genre",
    "TLEN": "length",
    "TT2": "title",
    "TP1": "artist",
    "TAL": "album",
    "TRK": "track",
    "TCO": "genre"
  ]);

constant id3_genres = ([
0 : "Blues",
1 : "Classic Rock",
2 : "Country",
3 : "Dance",
4 : "Disco",
5 : "Funk",
6 : "Grunge",
7 : "Hip-Hop",
8 : "Jazz",
9 : "Metal",
10: "New Age",
11: "Oldies",
12: "Other",
13: "Pop",
14: "R&B",
15: "Rap",
16: "Reggae",
17: "Rock",
18: "Techno",
19: "Industrial",
20: "Alternative",
21: "Ska",
22: "Death Metal",
23: "Pranks",
24: "Soundtrack",
25: "Euro-Techno",
26: "Ambient",
27: "Trip-Hop",
28: "Vocal",
29: "Jazz+Funk",
30: "Fusion",
31: "Trance",
32: "Classical",
33: "Instrumental",
34: "Acid",
35: "House",
36: "Game",
37: "Sound Clip",
38: "Gospel",
39: "Noise",
40: "Alternative Rock",
41: "Bass",
42: "Soul",
43: "Punk",
44: "Space",
45: "Meditative",
46: "Instrumental Pop",
47: "Instrumental Rock",
48: "Ethnic",
49: "Gothic",
50: "Darkwave",
51: "Techno-Industrial",
52: "Electronic",
53: "Pop-Folk",
54: "Eurodance",
55: "Dream",
56: "Southern Rock",
57: "Comedy",
58: "Cult",
59: "Gangsta",
60: "Top 40",
61: "Christian Rap",
62: "Pop/Funk",
63: "Jungle",
64: "Native US",
65: "Cabaret",
66: "New Wave",
67: "Psychadelic",
68: "Rave",
69: "Showtunes",
70: "Trailer",
71: "Lo-Fi",
72: "Tribal",
73: "Acid Punk",
74: "Acid Jazz",
75: "Polka",
76: "Retro",
77: "Musical",
78: "Rock & Roll",
79: "Hard Rock",
80: "Folk",
81: "Folk-Rock",
82: "National Folk",
83: "Swing",
84: "Fast Fusion",
85: "Bebob",
86: "Latin",
87: "Revival",
88: "Celtic",
89: "Bluegrass",
90: "Avantgarde",
91: "Gothic Rock",
92: "Progressive Rock",
93: "Psychedelic Rock",
94: "Symphonic Rock",
95: "Slow Rock",
96: "Big Band",
97: "Chorus",
98: "Easy Listening",
99: "Acoustic",
100: "Humour",
101: "Speech",
102: "Chanson",
103: "Opera",
104: "Chamber Music",
105: "Sonata",
106: "Symphony",
107: "Booty Bass",
108: "Primus",
109: "Porn Groove",
110: "Satire",
111: "Slow Jam",
112: "Club",
113: "Tango",
114: "Samba",
115: "Folklore",
116: "Ballad",
117: "Power Ballad",
118: "Rhythmic Soul",
119: "Freestyle",
120: "Duet",
121: "Punk Rock",
122: "Drum Solo",
123: "Acapella",
124: "Euro-House",
125: "Dance Hall",
126: "Goa",
127: "Drum & Bass",
128: "Club & House",
129: "Hardcore",
130: "Terror",
131: "Indie",
132: "BritPop",
133: "Negerpunk",
134: "Polsk Punk",
135: "Beat",
136: "Christian Gangsta Rap",
137: "Heavy Metal",
138: "Black Metal",
139: "Crossover",
140: "Contemporary Christian",
141: "Christian Rock",
142: "Merengue",
143: "Salsa",
144: "Thrash Metal",
145: "Anime",
146: "JPop",
147: "Synthpop"
]);

constant atom_map = 
  ([
     "©alb": "album",
     "©ART": "artist",
     "©day": "year",
     "©nam": "title",
     "©gen": "genre",
     "gnre": "genre",
     "trkn": "track",
     "©wrt": "composer",
     "©cmt": "comment",
     "disk": "disk",
     "cpil": "compilation"
  ]);

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
  inherit FS.Monitor.symlinks;

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
     ::create(@args);
    Thread.Thread(run_process_thread);
    set_nonblocking(3);
  }
   
   void run_process_thread()
   {
//werror("starting run_process_thread()\n");
     while(!should_quit)
     {
       sleep(10);
//werror("running process_entries()\n");
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
werror("pulling from delete queue.\n");
      low_file_deleted(@delete_queue->read());
    }
    
    while(!exists_queue->is_empty())
    {
	werror("pulling from exists queue.\n");
      low_file_exists(@exists_queue->read());      
    }
    
    while(!create_queue->is_empty())
    {
	werror("pulling from create queue.\n");
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
log->debug("adding file %s", p);
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
    if(!s->isdir && s->isreg)
    {
	    history->push(sprintf("file updated: %O", p));
//     werror("file exists: %O\n", p);
      mapping a;
      if(a = read_id3(p, s))
      {
        atts = atts + a;
	if(!atts->length) atts->length = get_length(p, 1);
     //   werror("got id3: %O\n", a);
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
        
//werror("atts: %O\n", atts);
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
//    else werror("SCAN ERROR: %s\n", p);
  }
}

mapping read_atoms(string p, object s)
{
   object atomsmasher = (object)"atoms";
   
   mapping m;
   catch(m = atomsmasher->parse(p));
   //werror("%O\n", m);
   return m;
}

object m;

void check(string path, object db)
{
  m = mon(FS.Monitor.basic.MF_RECURSE);
  m->db = db;
  m->monitor(path, FS.Monitor.basic.MF_RECURSE);
  log->info("registering music path " + path);
  call_out(m->check, 5.0);
}

int main()
{
  m = mon(FS.Monitor.basic.MF_RECURSE);
//  m->monitor("/Users/hww3/Music/iTunes/iTunes Media/Music", FS.Monitor.basic.MF_RECURSE);
//  m->set_nonblocking();

  return -1;  
}

