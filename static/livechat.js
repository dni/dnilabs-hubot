var socket = io.connect('https://bochelli.herokuapp.com/');

var Message = Backbone.Model.extend();

var MessagesCollection = Backbone.Collection.extend({
  model: Message
});

var Messages = new MessagesCollection;

var MessageView = Backbone.View.extend({
  tagName:  "li",
  template: _.template("<i><%= date.getHours() %>:<%= date.getMinutes() %></i> <%= username %>: <%= message %>"),
  render: function(){
    this.$el.html(this.template(this.model.toJSON()));
    return this;
  }
});

var AppView = Backbone.View.extend({
  id: "livechat",
  template: _.template("<ul id='chat-messages'></ul><input id='chat' type='text' placeholder='Nachricht senden...' />"),
  initialize: function() {
    this.listenTo(Messages, 'add', this.addOne);
  },
  render: function(){
    this.$el.html(this.template());
    return this;
  },
  events: {
    "keypress #chat": "updateOnEnter"
  },
  updateOnEnter: function(e) {
    if (e.keyCode != 13) return;
    var val = e.target.value;
    if (!val) return;
    var message = new Message({
      uid: getCookie("chat-uid"),
      message: val,
      username: "Ich",
      date: new Date()
    });
    Messages.add(message);
    socket.emit("sendmessage", message);
    e.target.value = ""
  },
  addOne: function(msg) {
    var view = new MessageView({model: msg});
    var scroll = this.$el.find("#chat-messages");
    scroll.append(view.render().el);
    scroll.scrollTop = scroll.scrollHeight;
  },
});

var App = new AppView();

jQuery("body").append(App.render().el);

if (!getCookie("chat-uid")) {
  tstamp = (new Date()).getTime();
  setCookie("chat-uid", tstamp, 1);
  console.log("created cookie "+ tstamp);
  if (!getCookie("chat-uid")) {
    console.log("cookie disabled");
  }
}

socket.on('message', function (data) {
  data.date = new Date(data.date);
  var message = new Message(data);
  Messages.add(message);
});

socket.emit("initUser", {
  uid: getCookie("chat-uid"),
  userAgent: window.navigator.userAgent,
  url: window.location.href
});
