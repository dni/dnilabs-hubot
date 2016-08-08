var socket = io.connect('http://localhost:8080');

var Message = Backbone.Model.extend();

var Messages = Backbone.Collection.extend({
  model: Message
});

var MessageView = Backbone.View.extend({
  tagName:  "li",
  template: "<i><%= date.getHours() %>:<%= date.getMonutes() %></i> <%= username %>: <%= message =>"
});

var AppView = Backbone.View.extend({
  template: "<ul id='chat-messages'></ul><input id='chat' type='text' />",
  initialize: function() {
    this.listenTo(Messages, 'add', this.addOne);
  },
  events: {
    "keypress #chat": "updateOnEnter"
  },
  updateOnEnter: function(e) {
    var msg = e.target.value
    if (e.keyCode == 13 && msg) {
      var message = {
        uid: getCookie("chat-uid");
        message: msg,
        username: "Ich",
        date: new Date()
      };
      Message.add(message);
      socket.emit("sendmessage", message);
    }
  },
  addOne: function(msg) {
    var view = new MessageView({model: msg});
    this.$el.find("#chat-messages").append(view.render().el);
  },
});

var App = new AppView();

socket.on('message', function (data) {
  data.date = new Date(data.date);
  Messages.add(data);
});

socket.emit("initUser", {
  uid: getCookie("chat-uid"),
  userAgent: window.navigator.userAgent,
  url: window.location.href
});
