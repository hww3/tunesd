#charset utf8

constant CONTAINER = 1;
constant SKIPPER = 2;
constant TAGITEM = 4;
constant NOVERN = 8;
constant XTAGITEM = 16;
constant GENRE = 32;

constant mp4_tag_map = ([
    "trkn": "Track",
    "\xa9ART": "Artist",
    "\xa9nam": "Title",
    "\xa9alb": "Album",
    "\xa9day": "Year",
    "\xa9gen": "Genre",
    "\xa9cmt": "Comment",
    "\xa9wrt": "Writer",
    "\xa9too": "Tool",
  ]);

constant mp4_atoms = ([
  "moov": CONTAINER,
  "udta": CONTAINER,
  "meta": CONTAINER|SKIPPER,
  "ilst": CONTAINER,
  "trak": CONTAINER,
  "mdia": CONTAINER,
  "minf": CONTAINER,
  "©ART": TAGITEM,
  "©nam": TAGITEM,
  "©too": TAGITEM,
  "©alb": TAGITEM,
  "©day": TAGITEM,
  "©gen": TAGITEM,
  "©wrt": TAGITEM,
  "gnre": TAGITEM|GENRE,
  "trkn": TAGITEM|NOVERN,
  "©cmt": TAGITEM,
  "----": XTAGITEM,
  "mdat": 0,
  "ftyp": 0
  ]);
   
  constant itunes_genres = ([
  1:"Blues",
  2:"Classic Rock",
  3:"Country",
  4:"Dance",
  5:"Disco",
  6:"Funk",
  7:"Grunge",
  8:"Hip-Hop",
  9:"Jazz",
  10:"Metal",
  11:"New Age",
  12:"Oldies",
  13:"Other",
  14:"Pop",
  15:"R&B",
  16:"Rap",
  17:"Reggae",
  18:"Rock",
  19:"Techno",
  20:"Industrial",
  21:"Alternative",
  22:"Ska",
  23:"Death Metal",
  24:"Pranks",
  25:"Soundtrack",
  26:"Euro-Techno",
  27:"Ambient",
  28:"Trip-Hop",
  29:"Vocal",
  30:"Jazz+Funk",
  31:"Fusion",
  32:"Trance",
  33:"Classical",
  34:"Instrumental",
  35:"Acid",
  36:"House",
  37:"Game",
  38:"Sound Clip",
  39:"Gospel",
  40:"Noise",
  41:"AlternRock",
  42:"Bass",
  43:"Soul",
  44:"Punk",
  45:"Space",
  46:"Meditative",
  47:"Instrumental Pop",
  48:"Instrumental Rock",
  49:"Ethnic",
  50:"Gothic",
  51:"Darkwave",
  52:"Techno-Industrial",
  53:"Electronic",
  54:"Pop-Folk",
  55:"Eurodance",
  56:"Dream",
  57:"Southern Rock",
  58:"Comedy",
  59:"Cult",
  60:"Gangsta",
  61:"Top 40",
  62:"Christian Rap",
  63:"Pop/Funk",
  64:"Jungle",
  65:"Native American",
  66:"Cabaret",
  67:"New Wave",
  68:"Psychadelic",
  69:"Rave",
  70:"Showtunes",
  71:"Trailer",
  72:"Lo-Fi",
  73:"Tribal",
  74:"Acid Punk",
  75:"Acid Jazz",
  76:"Polka",
  77:"Retro",
  78:"Musical",
  79:"Rock & Roll",
  80:"Hard Rock",
  81:"Folk",
  82:"Folk/Rock",
  83:"National Folk",
  84:"Swing",
  85:"Fast Fusion",
  86:"Bebob",
  87:"Latin",
  88:"Revival",
  89:"Celtic",
  90:"Bluegrass",
  91:"Avantgarde",
  92:"Gothic Rock",
  93:"Progressive Rock",
  94:"Psychedelic Rock",
  95:"Symphonic Rock",
  96:"Slow Rock",
  97:"Big Band",
  98:"Chorus",
  99:"Easy Listening",
  100:"Acoustic",
  101:"Humour",
  102:"Speech",
  103:"Chanson",
  104:"Opera",
  105:"Chamber Music",
  106:"Sonata",
  107:"Symphony",
  108:"Booty Bass",
  109:"Primus",
  110:"Porn Groove",
  111:"Satire",
  112:"Slow Jam",
  113:"Club",
  114:"Tango",
  115:"Samba",
  116:"Folklore",
  117:"Ballad",
  118:"Power Ballad",
  119:"Rhythmic Soul",
  120:"Freestyle",
  121:"Duet",
  122:"Punk Rock",
  123:"Drum Solo",
  124:"A Capella",
  125:"Euro-House",
  126:"Dance Hall"
  ]);
 
int size;
int offset;

mixed xtra(string s)
{
  int atomsize;
  string atomtype;
  int offset = 0;
  mapping result = ([]);
  while(sizeof(s))
  {
    sscanf(s, "%4c%4s%s", atomsize, atomtype, s);
    // werror(atomtype + "\n");
    string val;
    
    if(atomtype == "data")
    {
      [val, s] = array_sscanf(s, "%*8s%" + (atomsize-16) + "s%s");
      result[atomtype] = val;
    }
    else
    {
      [val, s] = array_sscanf(s, "%*4s%" + (atomsize-12) + "s%s");      
      result[atomtype] = val;
    }
  }
  return result;
}

mapping analyse(object f, int offset0, int offset1)
{
  int atomsize;
  string atomtype;
  mixed data;
  
  mapping m = ([]);
  
  offset = offset0;
  
  while(offset < offset1)
  {
    f->seek(offset);
    sscanf(f->read(4), "%4c", atomsize);
    atomtype = f->read(4);
//    werror("atomtype: %O=%d\n", atomtype, mp4_atoms[atomtype]);
    if(mp4_atoms[atomtype]&CONTAINER)
    {
      data = "";
      m[atomtype] = analyse(f, offset + ((mp4_atoms[atomtype]&SKIPPER)?12:8), offset + atomsize);
    }
    else
    {
      f->seek(offset + 8);
      if(mp4_atoms[atomtype]&TAGITEM)
      {
 //       werror("have a tagitem: %O size: %d\n", atomtype, atomsize);
        data = f->read(atomsize-8)[16..];
        if(mp4_atoms[atomtype]&NOVERN)
        {
  //        werror("atomsize: %O\n", atomsize);
          if((atomsize-16) > 15)
            data = ([array(int)]array_sscanf(data, "%4c%2c")*1);
          else
          data = ([array(int)]array_sscanf(data, "%4c")*1);
        }
        else if(mp4_atoms[atomtype]&GENRE)
          data = itunes_genres[([array(int)]array_sscanf(data, "%2c")*1)[0]] || "Unknown";
          
      }
      else if(mp4_atoms[atomtype]&XTAGITEM)
        data = xtra(f->read(atomsize-8));
      else
        data = f->read(min(atomsize-8, 32));
      
      if(mp4_atoms[atomtype])
      {
       // write("atom: %O: %O\n", atomtype, data);
       if(stringp(data))
         m[atomtype] = utf8_to_string(data);
       else 
         m[atomtype] = data;
      }
      offset += atomsize;
    }
  }
  
  return m;
}

mapping parse(string path)
{
  Stdio.File f = Stdio.File(path, "rb");
  f->seek(-1);
  size=f->tell();
  mapping m = analyse(f, 0, size);
  
  f->close();
  
  return m;
}

int main(int argc, array(string) argv)
{
  werror("%O\n", parse(argv[1]));
  return 0;
}