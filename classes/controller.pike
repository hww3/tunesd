inherit Fins.DocController;
inherit Fins.RootController;

object auth;

int __quiet = 1;

static void create(object application)
{
  ::create(application);
}

void start()
{
  auth = load_controller("auth/controller");
}

void populate_template(object id, object response, object v, mixed ... args)
{
  if(!v) return;
  
  v->add("request", id);
  v->add("action", id->event_name);
  v->add("version", app->version);  
  v->add("appname", "tunesd");
  v->add("songcount", app->db->get_song_count());
  v->add("user", id->misc->session_variables->user);
}

void index(object id, object response, object v, mixed ... args)
{
  v->add("action", "home");
  v->add("connections", app->connections);
  
  werror("connections: %O\n", app->connections);
}

void playlists(object id, object response, object v, mixed ... args)
{
  v->add("playlists", app->db->get_playlists());
}

void library(object id, object response, object v, mixed ... args)
{
  mixed songs = app->db->get_songs();
  v->add("library", songs);
  werror("song: %O\n", songs[0]);
}

void status(object id, object response, object v, mixed ... args)
{
  v->add("create_queue", (array)app->check->m->create_queue);
  v->add("exists_queue", (array)app->check->m->exists_queue);
  v->add("delete_queue", (array)app->check->m->delete_queue);
  v->add("history", values(app->check->m->history));
}


void search(object id, object response, object v, mixed ... args)
{
}

void settings(object id, object response, object v, mixed ... args)
{
  if(app->get_admin_auth_required() && !id->misc->session_variables->user)
  {
    response->flash("msg", "You must be logged in to access settings.");
    response->redirect(index);  
  }
  
  string library = id->variables->library;
   string|int library_password_enable = id->variables->library_password_enable;
   string library_password = id->variables->library_password;

   string|int admin_password_enable = id->variables->admin_password_enable;
   string admin_password = id->variables->admin_password;
  
  library_password_enable = app->get_auth_required();
  admin_password_enable = app->get_admin_auth_required();

  v->add("library_password_enable", library_password_enable);
  v->add("admin_password_enable", admin_password_enable);
  v->add("library", app->get_musicpath());
}

void update_settings(object id, object response, object v, mixed ... args)
{
  if(app->get_admin_auth_required() && !id->misc->session_variables->user)
  {
    response->flash("msg", "You must be logged in to access settings.");
    response->redirect(index);  
  }
  
  werror("variables: %O\n", id->variables);
  
  string library = id->variables->library;
  string|int library_password_enable = id->variables->library_password_enable;
  string library_password = id->variables->library_password;
 
  string|int admin_password_enable = id->variables->admin_password_enable;
  string admin_password = id->variables->admin_password;
  
  m_delete(id->variables, "library_password");
  m_delete(id->variables, "admin_password");
  
  if(id->variables->admin_password_set)
  {
    if(admin_password_enable = (int)admin_password_enable)
    {
      if(admin_password && strlen(admin_password))
      {
        app->set_admin_password(admin_password);
        response->flash("msg", "Admin password set.");        
      }
      else
      {
        response->flash("msg", "Cannot enable admin password, no admin password provided.");
      }
    }
    else
    {
      app->disable_admin_password();  
      response->flash("msg", "Admin password disabled.");
    }
  } 
  
  if(id->variables->library_password_set)
  {
    if(library_password_enable = (int)library_password_enable)
    {
      if(library_password && strlen(library_password))
      {
        app->set_library_password(library_password);
        response->flash("msg", "Library password set.");        
      }
      else
      {
        response->flash("msg", "Cannot enable library password, no library password provided.");
      }
    }
    else
    {
      app->disable_library_password();  
      response->flash("msg", "Library password disabled.");
    }
  } 
  
  if(library && (library != app->get_musicpath()))
  {
    object stat = file_stat(library);
    if(stat && stat->isdir)
    {
      app->change_musicpath(library);
      response->flash("msg", "Library location updated.");
    }
    else
      response->flash("msg", "Unable to update library location. Path \"" + 
        library + "\" does not exist or is not a directory.");
  }  
  
  response->redirect(settings);
}

void add_playlist(object id, object response, object v, mixed ... args)
{
  int rv;
  
  int smart = (int)id->variables->smart;
  string name = id->variables->name;
  string query = id->variables->query;  
  
  mixed err = catch(rv = app->db->add_playlist(id->variables->name, smart, query));

  if(err)
    response->flash("msg", err[0]);
  else if(rv)
    response->flash("msg", "Playlist added.");
  else
    response->flash("msg", "Playlist not added.");
    
  response->redirect(playlists);
}