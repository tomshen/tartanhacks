window.app = {};

app.google = {};

app.google.render = function() {
  return gapi.signin.render('googleSignIn', {
    callback: 'signInCallback',
    clientid: '70162173884-17kl5i9qdhkj5qbrj3ds4bpg573dg5h0.apps.googleusercontent.com',
    cookiepolicy: 'single_host_origin',
    scope: 'profile'
  });
};

app.google.renderBtn = function() {
  if (typeof gapi !== "undefined" && gapi !== null) {
    return gapi.signin.render('googleSignInBtn', {
      callback: 'signInCallback',
      clientid: '70162173884-17kl5i9qdhkj5qbrj3ds4bpg573dg5h0.apps.googleusercontent.com',
      cookiepolicy: 'single_host_origin',
      scope: 'profile'
    });
  } else {
    return setTimeout(app.google.renderBtn, 100);
  }
};

app.google.callback = function(res) {
  $('#googleSignIn').hide();
  if (res.code != null) {
    return app.api.login(res.code);
  } else {
    return app.err();
  }
};

(function() {
  var po, s;
  window.render = app.google.render;
  window.signInCallback = app.google.callback;
  po = document.createElement('script');
  po.type = 'text/javascript';
  po.async = true;
  po.src = 'https://apis.google.com/js/client:plusone.js?onload=render';
  s = document.getElementsByTagName('script')[0];
  return s.parentNode.insertBefore(po, s);
})();

app.api = {};

app.api.login = function(code) {
  if (!app.profile.loggedIn) {
    return $.post('/api/login', {
      singleUseToken: code
    }).done(function(res) {
      app.profile.loggedIn = true;
      return app.api.get_me(app.router);
    }).fail(app.err);
  } else {
    return app.err();
  }
};

app.api.logout = function() {
  if (app.profile.loggedIn) {
    return $.get('/api/logout', null).done(function() {
      app.profile.loggedIn = false;
      return app.router();
    }).fail(app.err);
  } else {
    return app.err();
  }
};

app.api.get_me = function(next) {
  if (app.profile.loggedIn) {
    return $.get('/api/me', null).done(function(user) {
      user = JSON.parse(user);
      app.profile.isAdmin = (user.isAdmin != null) && user.isAdmin;
      return next(user);
    }).fail(app.err);
  } else {
    return app.err();
  }
};

app.api.get_users = function(next) {
  if (app.profile.isAdmin) {
    return $.get('/api/users', null).done(function(users) {
      users = JSON.parse(users);
      return next(users);
    }).fail(app.err);
  } else {
    return app.err();
  }
};

app.api.delete_user = function(userID, next) {
  if (app.profile.isAdmin) {
    return $.ajax({
      url: "/api/users/" + userID,
      type: 'DELETE',
      success: function(result) {
        return next(result);
      }
    });
  }
};

app.api.accept_user = function(userID, next) {
  if (app.profile.isAdmin) {
    return $.ajax({
      url: "/api/users/" + userID,
      type: 'PUT',
      data: {
        isAccepted: true
      },
      success: function(result) {
        return next(result);
      }
    });
  }
};

app.api.checkin_user = function(userID, next) {
  if (app.profile.isAdmin) {
    return $.ajax({
      url: "/api/users/" + userID,
      type: 'PUT',
      data: {
        isCheckedIn: true
      },
      success: function(result) {
        return next(result);
      }
    });
  }
};

app.api.register_status = function(next) {
  return $.get('/api/openStatus', null).done(function(status) {
    status = JSON.parse(status);
    return next(status);
  }).fail(app.err);
};

app.profile = {};

app.profile.loggedIn = false;

app.profile.isAdmin = false;

app.routes = {};

app.templates = {};

app.router = function() {
  var route;
  route = location.hash.slice(1);
  route = route.replace(/^\//, '');
  route = route.replace(/\/$/, '');
  switch (route) {
    case '':
      return app.routes.home();
    case 'user-list':
      return app.routes.userlist();
    case 'hacker-list':
      return app.routes.hackerlist();
    default:
      return app.routes.err404(route);
  }
};

$(window).on('hashchange', app.router);

$(app.router);

app.templates.login = Handlebars.compile($('#login-template').html());

app.templates.home = Handlebars.compile($('#home-template').html());

app.routes.home = function() {
  if (app.profile.isAdmin) {
    return $('#content').html(app.templates.home());
  } else {
    return $('#content').html(app.templates.login());
  }
};

app.templates.err = Handlebars.compile($('#error-template').html());

app.routes.err = function() {
  $('#content').html(app.templates.err());
  return app.router();
};

app.templates.err404 = Handlebars.compile($('#error-404-template').html());

app.routes.err404 = function(addr) {
  return $('#content').html(app.templates.err404({
    addr: addr
  }));
};

app.err = app.routes.err;

app.lists = {};

app.lists.acceptHandler = function(id) {
  app.api.accept_user(id, function() {
    return app.router();
  });
  return false;
};

app.lists.deleteHandler = function(id) {
  app.api.delete_user(id, function() {
    return app.router();
  });
  return false;
};

app.lists.checkinHandler = function(id) {
  app.api.checkin_user(id, function() {
    return app.router();
  });
  return false;
};

app.templates.hackerlist = Handlebars.compile($('#hacker-list-template').html());

app.routes.hackerlist = function() {
  return app.api.get_users(function(users) {
    users = users.filter(function(elem) {
      return (elem.isAccepted != null) && elem.isAccepted;
    });
    return $('#content').html(app.templates.hackerlist({
      users: users
    }));
  });
};

app.templates.userlist = Handlebars.compile($('#user-list-template').html());

app.routes.userlist = function() {
  return app.api.get_users(function(users) {
    users = users.filter(function(elem) {
      return !(((elem.isAdmin != null) && elem.isAdmin) || ((elem.isMentor != null) && elem.isMentor) || ((elem.isAccepted != null) && elem.isAccepted));
    });
    return $('#content').html(app.templates.userlist({
      users: users
    }));
  });
};
