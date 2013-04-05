import Fins;

inherit Fins.DocController;

protected program __default_template = Fins.Template.Simple;

//! this is a sample authentication handler module which can be customized
//! to fit the particular needs of your application
//!
//! this provider uses a form to gather authentication information
//! and stores the validated user identifier (what that actually is 
//! will depend on the behavior of the @[find_user] method) in the 
//! session.
//! 
//! the application may pass "return_to" in the request variable mapping
//! which will be used to determine the url the application will return to
//! following a successful authentication.

//! method which is called to determine if a user should be considered "authenticated".
//! this method accepts the request object and should return 
//! zero if the user was not successfully authenticated, or a value
//! which will be placed in the current session as "user".
function(Fins.Request,Fins.Response,Fins.Template.View:mixed) validate_user = md5_validate_user;

//! 
object|function default_action;

//! default startup method. sets @[default_action] to be the root of the 
//! current application. custom applications should override this method 
//! and set this value appropriately.
void start()
{
  default_action = app->controller;
}


//! default user authenticator, for data models where a user object represents
//! a user and the password field contains a MD5 crypt string.
static mixed md5_validate_user(Request id, Response response, Template.View t)
{
  mixed r;
  /*
  r = Fins.Model.find.users( ([ "username": id->variables->username,
                                    ]) );
  */
  if(app->check_admin_password(id->variables->password))
  {
    t->add("username", "admin");
    return "admin";
  }

  // failure!
  return 0;
}

// _login is used for ajaxy logins.
function/*(Request, Response, Template.View, mixed ...:void )*/ _login = login;

public void login(Request id, Response response, Template.View t, mixed ... args)
{
   if(!id->variables->return_to)
   {
      id->variables->return_to = ((id->misc->flash && id->misc->flash->from) ||
                               id->variables->referrer || id->referrer ||
                               app->url_for_action(default_action));
   }

   switch(id->variables->action)
   {
      case "Cancel":
         response->redirect(id->variables->return_to || default_action);
         return;
         break;
      case "Login":
        mixed r = validate_user(id, response, t);
        if(r)
        {
           // success!
           id->misc->session_variables->logout = 0;
           id->misc->session_variables["user"] = r;
           if(!id->variables->return_to)
           {
             response->redirect(default_action);
             return;
           }
           
           if(arrayp(id->variables->return_to))
             id->variables->return_to = id->variables->return_to[0];
           if(search(id->variables->return_to, "?") < -1)
             id->variables->return_to = id->variables->return_to + "&" + time();
           else
             id->variables->return_to = id->variables->return_to + "?" + time();
           response->redirect(id->variables->return_to || default_action);
           return;
        }
        else
        {
           response->flash("Login Incorrect.");
        }
   }

   t->add("return_to", id->variables->return_to);
}

public void logout(Request id, Response response, Template.View t, mixed ... args)
{
  if(id->misc->session_variables->userid)
  {
     id->misc->session_variables->logout = time();
     m_delete(id->misc->session_variables, "user");
  }

  response->flash("You have been successfully logged out.");
  response->redirect(id->referrer||default_action);
}
