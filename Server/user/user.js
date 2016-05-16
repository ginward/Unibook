
/*
 * The user Schema for unibook.
 * Only university students are able to register
 * Copyright Jinhua Wang, 2015
 * The MIT License (MIT)
 * Copyright (c) <2015> <Jinhua Wang>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions
 * of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
var mongoose = require('mongoose');
var schema = new mongoose.Schema({
                                 //make sure the database is indexed by user
                                 username:{ type: String, unique: true },
                                 name:String, 
                                 password:String,
                                 //the salt for creating password hashes
                                 salt:String,
                                 uniMail:String,
                                 //if the email is official university email
                                 mailVerified:Boolean,
                                 //if the account is available for use, false if account frozen
                                 active:Boolean,
                                 //timestamp to make sure the token is up to date. ts syncs with redis and is usually checked at redis
                                 accountTimestamp:String,
                                 //the profile image url
                                 profileURL:{ type: String, default: 'N/A' },
                                 //the timestamp when the profile image is updated
                                 profileTimestamp: {type: String, default:'N/A'},
                                 
});
module.exports = mongoose.model('UniUser', schema);