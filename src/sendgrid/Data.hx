package sendgrid;

typedef SendGridPayload = {
    personalizations : Array<Personalization>,
    from : User,
    ?reply_to :  User,
    subject : String,
    content : Array<Content>
}

typedef Personalization = {
    to : Array<User>,
    ?cc : Array<User>,
    ?bcc : Array<User>
}

typedef User = {
    name : String,
    email : String
}

typedef Content = {
    type : String,
    value : String
}

