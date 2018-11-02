function Chat(host, secure) {
    var defaultAvatar = 'https://avatars3.githubusercontent.com/u/17364220?v=3&s=200';
    var markdown = new showdown.Converter();
    var chat = this;
    var protocol = secure ? 'wss://' : 'ws:/'

    chat.imageCache = {};
    chat.ws = new WebSocket(protocol + host + '/chat');

    chat.ws.onopen = function() {
        chat.systemMessage("You are now connected.")
    };

    chat.ws.onclose = function() {
        chat.systemMessage("You have been disconnected from the chat room.")
    }

    $('form').on('submit', function(e) {
        e.preventDefault();
                 
        var message = $('.message-input').val();
                 
        if (message.length == 0 || message.length >= 256) {
            return;
        }
                 
        chat.send(message);
        $('.message-input').val('');
    });
    
    chat.ws.onmessage = function(text) {
        var event = JSON.parse(text.data);

        switch (event.type) {
        case "message":
            chat.bubble(event.message.text, event.message.sender, new Date(event.message.timestamp));
            break
        case "connect":
            chat.systemMessage(event.user.name + " just connected. Say hi!");
            break
        case "disconnect":
            chat.systemMessage(event.user.name + " has just left.");
            break
        case "notice":
            chat.systemMessage(event.message);
            break
        case "error":
            chat.systemMessage(event.message, "error");
            break
        }
    }
    
    chat.send = function(message) {
        chat.ws.send(message);
        
        if (message.indexOf('/') !== 0) {
            chat.bubble(message);
        }
    }

    chat.bubble = function(message, sender, timestamp) {
        var d = timestamp || new Date();
        var message = markdown.makeHtml(message);

        var bubble = $('<div>')
            .addClass('message')
            .addClass('new');

        var text = $('<span>')
            .addClass('text');

        if (sender === true) {
            // System message
            bubble.addClass('system');
            text.html(message);
        } else if (sender) {
            bubble.attr('data-username', sender.name);

            var image = $('<img>')
            .addClass('avatar')
            .attr('src', sender.avatar || defaultAvatar);

            bubble.append(image);
            text.html(sender.name + ': ' + message);
        } else {
            // Outgoing message
            bubble.addClass('personal');
            text.html(message);
        }

        bubble.append(text);

        var m = '00'
        if (m != d.getMinutes()) {
            m = d.getMinutes();
        }
        
        if (m < 10) {
            m = '0' + m;
        }
        
        var time = $('<span class="timestamp">' + d.getHours() + ':' + m + '</div>');
        bubble.append(time);
        
        $('.messages').append(bubble);
        
        var objDiv = $('.messages')[0];
        objDiv.scrollTop = objDiv.scrollHeight;
    }

    chat.systemMessage = function(message) {
        chat.bubble(message, true)
    }
};
