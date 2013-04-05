inherit Fins.Application;


// the default network port to listen on if one isn't specified.
#define SERVERPORT 3689

//#define DBURL "sqlite://tunesd.sqlite3"

string musicpath;
string version = "0.2";

mapping locks = ([]);

mapping sessions = ([]);
int revision_num = 1;

object daap = ((program)"daap_server")(this);
object db;
object check = ((program)"check")(this);

mapping connections = ([]);

program request_program = tunesd.Request;
object port;
int default_port = SERVERPORT;
/*Protocols.DNS_SD.Service*/object bonjour;
/*Protocols.DNS_SD.Service*/object bonjour_http;

object log = Tools.Logging.get_logger("fins.application");

void start()
{
  // attempt to find the music path.
  catch(musicpath = replace(config->get_value("library", "path"), "$HOME", getenv()["HOME"]));
werror("********\n*******\n");  
  // the db is actually loaded by fins into "model", but for the sake of code already written, we keep db as an alias.
  db = model;
  model->start();
  call_out(register_bonjour, 1);
  if(musicpath)
    check->check(musicpath, model);
//  call_out(print_locks, 10);
}

string get_musicpath()
{
  return musicpath;
}

void change_musicpath(string path)
{
  config->set_value("library", "path", path);
  musicpath = replace(config->get_value("library", "path"), "$HOME", getenv()["HOME"]); 
  destruct(check);
  check = ((program)"check")(this);
  check->check(musicpath, model);  
  db->start_cleanup();
}

void print_locks()
{
  werror("locks: %O\n", locks);
  call_out(print_locks, 30);
}

int get_auth_required()
{
  return (config["library"] && config["library"]["password"])?1:0;
}

void set_library_password(string pw)
{
  config->set_value("library", "password", Crypto.make_crypt_md5(pw));
  
  // since itunes doesn't pass auth with streaming requests, we change the db id so that files can't be streamed.
  db->reset_id();
  foreach(locks;object o; object l)
  {
    destruct(l); 
  }
}

void disable_library_password()
{
  config->delete_value("library", "password");
}

int check_library_password(string pw)
{
  int res = 1;
  catch(res = Crypto.verify_crypt_md5(pw, config["library"]["password"]));
  return res;
}

int get_admin_auth_required()
{
  return (config["admin"] && config["admin"]["password"])?1:0;
}

void set_admin_password(string pw)
{
  config->set_value("admin", "password", Crypto.make_crypt_md5(pw));
}

void disable_admin_password()
{
  config->delete_value("admin", "password");
}

int check_admin_password(string pw)
{
  int res = 1;
  catch(res = Crypto.verify_crypt_md5(pw, config["admin"]["password"]));
  return res;
}
// TODO: make this work on windows?
int have_command(string command)
{
  string p;
  p = Process.popen("which " + command);
  return sizeof(p);    
}

object low_register_bonjour(int port, string name, string service)
{
  object bonjour;
  
    if(have_command("avahi-publish"))
    {
      array command = ({"avahi-publish", "-s"});
      command += ({name});
      command += ({"_" + service + "._tcp"});
      command += ({(string)port});
      bonjour = Process.create_process(command);
      sleep(0.5);
      if(bonjour->status() != 0)
      {
        throw(Error.Generic("Unable to register service using avahi-publish.\n"));
      }
      log->info("Advertising tunesd/" + upper_case(service) + " via Bonjour (using avahi-publish).");
    }
    else if(have_command("avahi-publish-service"))
    {
      array command = ({"avahi-publish-service"});
      command += ({name});
      command += ({"_" + service + "._tcp"});
      command += ({(string)port});
      bonjour = Process.create_process(command);
      sleep(0.5);
      if(bonjour->status() != 0)
      {
        throw(Error.Generic("Unable to register service using avahi-publish-service.\n"));
      }
      log->info("Advertising tunesd/" + upper_case(service) + " via Bonjour (using avahi-publish-service).");
    }
  #if constant(_Protocols_DNS_SD)
  #if constant(Protocols.DNS_SD.Service);
    else if(1)
    {
      log->info("Advertising tunesd/" + upper_case(service) + " via Bonjour.");
      bonjour = Protocols.DNS_SD.Service(name, "_" + service + "._tcp", "", (int)port);
    }
  #endif
  #endif
    else if(have_command("dns-sd"))
    {
      array command = ({"dns-sd"});
      command += ({"-R"});
      command += ({name});
      command += ({"_" + service + "._tcp"});
      command += ({"."});
      command += ({(string)port});
    }
    else
    {
      throw(Error.Generic("You must have a Bonjour/Avahi installation in order to run this application.\n"));
    }
  return bonjour;
}

void register_bonjour()
{
  db = model;
werror("app_runner: %O\n", app_runner->get_ports());
  // TODO: we should add a process-end callback to restart the registration
  // if avahi-publish* die for some reason.

  bonjour = low_register_bonjour(app_runner->get_ports()[0]->portno, db->get_name(), "daap");
  bonjour_http = low_register_bonjour(app_runner->get_ports()[0]->portno, db->get_name(), "http");
}

void server_did_revise(int revision)
{
  log->info("change received.");
  revision_num = revision;
  foreach(locks;mixed sessionid;object lock)
  {
    m_delete(locks, sessionid);
    if(!objectp(lock)) continue;
    mixed response = daap->create_update(lock, 1);
    lock->response_and_finish(daap->create_response(response, 200));
  }    
}

mixed handle_http(Protocols.HTTP.Server.Request request)
{
  array|mapping response;
  
  response = daap->handle_request(request);

  if(!response)
  {
    response = ::handle_http(request);
  }
  return response;
}

