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
function(Fins.Request,Fins.Response,Fins.Template.View:mixed) validate_user = default_validate_user;

//! method which is called to locate a user's password.
//! this method accepts the request object and should return either a
//! user object with "email" and "password" fields, or a mapping with these
//! two indices.
function(Fins.Request,Fins.Response,Fins.Template.View:mixed) find_user_password = default_find_user_password;

//! method which is called to reset a user's password.
//! 
//! @returns
//!   0 upon failure, should also set response flash message describing the difficulty.
function(Fins.Request,Fins.Response,Fins.Template.View,mixed,string:mixed) reset_password = default_reset_password;


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
//! a user and the password is saved as a plain text string. 
static mixed default_validate_user(Request id, Response response, Template.View t) 
{ 
  mixed r;
/*
  r = Fins.Model.find.users( ([ "username": id->variables->username,
                                      "password": id->variables->password
                                    ]) );
*/
  t->add("username", id->variables->username);

  if(r && sizeof(r)) return r[0];
  else return 0;
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
  if(r && (sizeof(r)== 1) && Crypto.verify_crypt_md5(id->variables->password, r[0]["password"]))
  {
    t->add("username", id->variables->username);
    return r[0];
  }

  // failure!
  return 0;
}

//! the name of the template to use for sending the password via email.
string password_template_name = "auth/sendpassword";

//! default password changer
//!
//! changes a user's password by setting the text of a field to the new value.
//! 
//! @note
//!  this method receives a password which the user has typed twice (in order
//!  to prevent typos. This method should perform other QA checks if necessary
//!  (such as password complexity and aging tests).
static mixed default_reset_password(Request id, Response response, Template.View t, mixed user, string newpassword)
{
  user["password"] = newpassword;
  return 1;
}

//! MD5 based password changer
//!
//! changes a user's password by setting the password field to an MD5 hash.
//! 
//! @note
//!  this method receives a password which the user has typed twice (in order
//!  to prevent typos. This method should perform other QA checks if necessary
//!  (such as password complexity and aging tests).
//!
//! @note
//!  this method requires a field length longer than the maximum acceptable
//!  password length. 
static mixed md5_reset_password(Request id, Response response, Template.View t, mixed user, string newpassword)
{
  user["password"] = Crypto.make_crypt_md5(newpassword);
  return 1;
}

//! default user password locator
//! 
static mixed default_find_user_password(Request id, Response response, Template.View t)
{

  mixed r;
  /*
  r = Fins.Model.find.users( ([ "username": id->variables->username
                                    ]) );
  */
  t->add("username", id->variables->username);

  if(r && sizeof(r)) return r[0];
  else return 0;
}

//! MD5-crypt based user password locator
//! 
//! @note
//!  this method will reset the password of the user, as the original password isn't available.
static mixed md5_find_user_password(Request id, Response response, Template.View t)
{

  mixed r;
  
  /*
  r = Fins.Model.find.users( ([ "username": id->variables->username
                                    ]) );
 */
  t->add("username", id->variables->username);
  
  if(!r) return 0;
  
  string newpass = Tools.String.generate_password(10);

  r[0]["password"] = Crypto.make_crypt_md5(newpass);

  if(r && sizeof(r)) return (["email": r[0]["email"], "password": newpass]);
  else return 0;
}

static string generate_password()
{
  return "";
}

//! override this method to set the mail host for retrieved password emails.
static string get_mail_host()
{
  return gethostname();
}

//! override this method to set the return address for retrieved password emails.
static string get_return_address()
{
  return "password-retrieval@" + gethostname();
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

public void changepassword(Request id, Response response, Template.View t, mixed ... args)
{
  t->add("return_to", id->variables->return_to);

  switch(id->variables->action)
  {
    case "Reset":
        mixed r = validate_user(id, response, t);
        if(r)
        {
           // success!
           if((id->variables->newpassword && strlen(id->variables->newpassword)) && id->variables->newpassword == id->variables->newpassword2 )
           {
              if(reset_password(id, response, t, r, id->variables->newpassword))
               response->flash("Password reset successfully.");
               response->redirect(login, ({}), (["return_to": id->variables->return_to]));
           }
           else
           {
             response->flash("No password supplied, or the new password does not match its confirmation.");
           }
        }
        else
        {
           response->flash("Unable to find a user with that username and/or password.");
        }

  }
 
}

public void forgotpassword(Request id, Response response, Template.View t, mixed ... args)
{

  switch(id->variables->action)
  {
    case "Locate":
      mixed r = find_user_password(id, response, t);

      if(!r)
      {
        response->flash("Unable to find a user account with that username. Please try again.\n");
      }
      else
      {
        object tp = view->low_get_view(__default_template, password_template_name);

        tp->add("password", r["password"]);

        string mailmsg = tp->render();

        Protocols.SMTP.Client(get_mail_host())->simple_mail(r["email"],
                              "Your password",
                              get_return_address(),
                              mailmsg);

        response->flash("Your password has been located and will be sent to the email address on record for your account.\n");
        response->redirect(login);
       }
  }
}
