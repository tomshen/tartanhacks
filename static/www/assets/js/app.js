window.app = {};

particlesJS('splash-bg', {
  particles: {
    color: '#fff',
    shape: 'triangle',
    opacity: 1,
    size: 2,
    size_random: false,
    nb: $(window).width() / 5,
    line_linked: {
      enable_auto: true,
      distance: 100,
      color: '#fff',
      opacity: 0.9,
      widapp: 1,
      condensed_mode: {
        enable: false,
        rotateX: 600,
        rotateY: 600
      }
    },
    anim: {
      enable: true,
      speed: 1
    }
  },
  interactivity: {
    enable: false
  },
  retina_detect: true
});

Handlebars.registerHelper('if_cond', function(v1, operator, v2, options) {
  switch (operator) {
    case '==':
    case '===':
      if (v1 === v2) {
        return options.fn(this);
      } else {
        return options.inverse(this);
      }
    case '<':
      if (v1 < v2) {
        return options.fn(this);
      } else {
        return options.inverse(this);
      }
    case '<=':
      if (v1 <= v2) {
        return options.fn(this);
      } else {
        return options.inverse(this);
      }
    case '>':
      if (v1 > v2) {
        return options.fn(this);
      } else {
        return options.inverse(this);
      }
    case '>=':
      if (v1 >= v2) {
        return options.fn(this);
      } else {
        return options.inverse(this);
      }
    case '&&':
      if (v1 && v2) {
        return options.fn(this);
      } else {
        return options.inverse(this);
      }
    case '||':
      if (v1 || v2) {
        return options.fn(this);
      } else {
        return options.inverse(this);
      }
    default:
      return options.inverse(this);
  }
});

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
      return app.router();
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
      return next(user);
    }).fail(app.err);
  } else {
    return app.err();
  }
};

app.api.set_me = function(user, next) {
  if (app.profile.loggedIn) {
    return $.ajax({
      type: 'PUT',
      url: '/api/me',
      data: user
    }).done(function() {
      return next();
    }).fail(app.err);
  } else {
    return app.err();
  }
};

app.api.delete_me = function(next) {
  if (app.profile.loggedIn) {
    return $.ajax({
      type: 'DELETE',
      url: '/api/me'
    }).done(function() {
      return app.api.logout(next);
    }).fail(app.err);
  } else {
    return app.err();
  }
};

app.api.register_me = function(data, next) {
  if (app.profile.loggedIn) {
    return $.ajax({
      type: 'POST',
      url: '/api/register',
      data: data
    }).done(function() {
      return app.router();
    }).fail(app.err);
  } else {
    return app.err();
  }
};

app.api.register_status = function(next) {
  return $.get('/api/openStatus', null).done(function(status) {
    status = JSON.parse(status);
    return next(status);
  }).fail(app.err);
};

app.routes = {};

app.templates = {};

app.router = function() {
  var route;
  route = location.hash.slice(1);
  route = route.replace(/^\//, '');
  route = route.replace(/\/$/, '');
  switch (route) {
    case 'about':
      return app.routes.about();
    case 'profile':
      return app.routes.profile();
    case 'profile/edit':
      return app.routes.profile({
        edit: true
      });
    case 'register':
      return app.routes.register();
    case 'register/priority':
      return app.routes.register({
        priority: true
      });
    case 'schedule':
      return app.routes.schedule();
    case '':
      return app.routes.home();
    default:
      return app.routes.err404(route);
  }
};

$(window).on('hashchange', app.router);

$(app.router);

app.templates.about = Handlebars.compile($('#about-template').html());

app.routes.about = function() {
  return $('#content').html(app.templates.about());
};

app.profile = {};

app.profile.loggedIn = false;

app.profile.formHandler = function(e) {
  var user;
  user = $('#profile-form').serialize();
  app.api.set_me(user, function() {
    return location.href = '/#/profile/';
  });
  return e.preventDefault();
};

app.profile.deleteBtnHandler = function(e) {
  if ($('#profile-delete-text').val() === 'delete') {
    return app.api.delete_me();
  }
};

app.templates.profile = Handlebars.compile($('#profile-template').html());

app.routes.profile = function(options) {
  if (options == null) {
    options = {};
  }
  options.loggedIn = app.profile.loggedIn;
  if (!options.loggedIn) {
    $('#content').html(app.templates.profile(options));
    return app.google.renderBtn();
  } else {
    return app.api.get_me(function(user) {
      delete user.isAccepted;
      delete user.isCheckedIn;
      delete user.isRegistered;
      Object.keys(user).map(function(key) {
        if ((user[key] == null) || user[key] === "") {
          return delete user[key];
        }
      });
      if (Object.keys(user).length !== 0) {
        options.user = user;
      }
      $('#content').html(app.templates.profile(options));
      $('#profile-delete').on('click', app.profile.deleteBtnHandler);
      if (options.edit) {
        $('#profile-form').submit(app.profile.formHandler);
        return $('#profile-form-submit').on('click', app.profile.formHandler);
      } else {
        return $('#logout').on('click', app.api.logout);
      }
    });
  }
};

app.register = {};

app.register.formHandler = function(e) {
  var data;
  data = $('#register-form').serialize();
  app.api.register_me(data, function() {
    return app.router();
  });
  return e.preventDefault();
};

app.templates.register = Handlebars.compile($('#register-template').html());

app.routes.register = function(options) {
  return app.api.register_status(function(data) {
    if (options == null) {
      options = {};
    }
    options.status = data.status;
    options.loggedIn = app.profile.loggedIn;
    if (options.loggedIn) {
      return app.api.get_me(function(user) {
        options.user = user;
        $('#content').html(app.templates.register(options));
        $('#register-form').submit(app.register.formHandler);
        return $('#register-form-submit').on('click', app.register.formHandler);
      });
    } else {
      $('#content').html(app.templates.register(options));
      return app.google.renderBtn();
    }
  });
};

app.templates.err = Handlebars.compile($('#error-template').html());

app.routes.err = function() {
  return $('#content').html(app.templates.err());
};

app.templates.err404 = Handlebars.compile($('#error-404-template').html());

app.routes.err404 = function(addr) {
  return $('#content').html(app.templates.err404({
    addr: addr
  }));
};

app.err = app.routes.err;

app.templates.schedule = Handlebars.compile($('#schedule-template').html());

app.routes.schedule = function() {
  return $('#content').html(app.templates.schedule());
};

app.routes.home = app.routes.about;
