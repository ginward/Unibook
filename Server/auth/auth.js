/*
 * Authentication class for unibook server
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

/*
 *   Error table:
 *    s01 => Server: server error
 *    r01 => Registration: user exists
 *    a01 => Authentication: user not found
 *    a02 => Authentication: wrong password
 *    a03 => Registration: username or password format wrong
 *    a04 => Authentication: User not verified
 *    t01 => Token: token invalid
 *    t02 => Token expired
 *    c01 => ChangePassword: user not found
 *    c02 => ChangePassword: wrong password
 *    e01 => Postmark mail: cannot send email to postmark
 *    e02 => Postmark mail: user not found
 *    e03 => Not a valid university email address
 *    v01 => Verification: code does not match
 *    v02 => Verification:: user not found
 *    v03 => user not active or email not verified
 */

//json web token for token issues
var jwt = require('jsonwebtoken');
var mongoose = require('mongoose');
//get the configuration file
var config = require('../config');
//mongoose model for user
var user = require('../user/user.js');
var debug = require('debug')('auth');
//get the redis client
var redis = require("redis");
//postmark is used here to send verification emails
var postmark = require("postmark");
//university email list
var university = require('../university');
var path = require('path');
/*
 * Setup the clients
 */
//connect mongoose to database
if(!mongoose.connection.readyState)
mongoose.connect(config.database,config.mongodb_opt);

//create redis client
var client = redis.createClient();
client.on("error", function (err) {
    debug("Error " + err);
});
                    
//postmark for sending emails
var pmark = new postmark.Client(config.POST_MARK_TOKEN);
                    
module.exports = auth = function() {
    
};

//method to register the user
//prerequisite: jsonParser, validateEmail
auth.prototype.registerMiddleware = function(req, res, next) {
    var uname_raw = req.body.username;
    var uname = uname_raw.toLowerCase();
    var pwd = req.body.password;
    var email = req.body.email;
    var name = req.body.name;
    user.findOne({username:uname},function(err, result){
                 if(err) {
                    debug(err);
                    return res.json({ success: false, message: 'Registration failed. Server error.', code: 's01' });
                 }
                 //if there is an existing verified user, registration fails
                 if(result) {
                    debug("Registration: "+uname+"exists!");
                    return res.json({ success: false, message: 'Registration failed. User exists.', code: 'r01' });
                 }
                 var timestamp = new Date().getTime();
                 //generate salt
                 var salt = require('crypto').randomBytes(16).toString('base64');
                 //hash salt
                 var pwd_hash = require('crypto').createHash('sha256').update(pwd+salt,'utf8').digest('base64');
                 //create user in the database, note that the user has not verified his email address yet
                 var userNew = new user({
                                        username:uname,
                                        name:name,
                                        password:pwd_hash,
                                        salt:salt,
                                        uniMail:email,
                                        mailVerified: false,
                                        active:false,
                                        accountTimestamp:timestamp,
                 });
                 userNew.save(function (err){
                           if(err) {
                            debug (err);
                            return res.json({success: false, message: 'Registration failed. Server error.', code: 's01'});
                           }
                 });
                 var json_to_send = {};
                 json_to_send.username = userNew.username;
                 json_to_send.timestamp = userNew.accountTimestamp;
                 //generate the token and send it to the clients
                 var token  = jwt.sign(JSON.parse(JSON.stringify(json_to_send)), config.jwtsecret,{});
                 //send verification email
                 //four digit random number generation
                 var tmp_code = Math.floor(Math.random()*9000) + 1000;console.log(tmp_code);
                 client.hmset(uname+":tmpCode", "tmpCode", tmp_code, "timestamp", timestamp, function(err,res){
                            if(err){
                                debug(err);
                                return;
                              }
                            execEmail(email, tmp_code, function(err, success){
                                if(err){
                                    debug (err);
                                }
                            });
                 });
                 client.hmset(uname+":token","token", token, "timestamp",json_to_send.timestamp, "name", name, "email", email, function(err,reply){
                             if(err) {
                                debug (err);
                                return res.json({success:false, message:"Registration failure, server error", code:"s01"});
                              };
                 //return the function
                 return res.json({success:true, token:token});
                 });

    });
};

//middleware to make sure that username and password satisfies certain format
//username length must fall within [5, 10] characters, password length must fall within [5, 20] chracteres
auth.prototype.valididateUnamePwd = function(req, res, next){
    var username = req.body.username;
    var password = req.body.password;
    if (!username||!password||username.length<5||username.length>20||password.length<5||password.length>30)
        return res.json({success:false, message:"username of password format wrong", code:"a03"});
    next();
}

//check if the username is unique
//prerequisite: jsonParser
auth.prototype.uniqueUsrMiddleware = function(req, res, next){
    var uname_raw = req.body.username;
    var uname = uname_raw.toLowerCase();
    user.findOne({username:uname},function(err, result){
                 if(err) {
                 debug(err);
                 return res.json({ success: false, message: 'Registration failed. Server error.', code: 's01' });
                 }
                 //if there is an existing verified user, registration fails
                 if(result) {
                    debug("Registration:"+req.body.username+"exists!");
                    return res.json({ success: false, message: 'Registration failed. User exists.', code: 'r01' });
                 }
                 return res.json({success:true});
    });
}

//verify that the provided email address is valid university email
//prerequisite:jsonParser, valididateUnamePwd
auth.prototype.validateEmail = function(req, res, next){
    var email = req.body.email;
    var secondLastItem = email.split('@');
    if(secondLastItem.length!=2) return res.json({success:false, message:"not a valid university email", code:"e03"});
    var addArr = secondLastItem[1].split('.');
    var length = addArr.length;
    if (length<2) return res.json({success:false, message:"not a valid university email", code:"e03"});
    //get the tail of the email address
    var addTail = addArr[length-2] + '.' + addArr[length-1];
    if(addTail in university) {
        //convert the registration email to lowercase
        req.body.email = req.body.email.toLowerCase();
        next();
    }
    else return res.json({success:false, message:"not a valid university email", code:"e03"});
};

//callback(err,success)
var execEmail = function(address, activation, callback){
    
     pmark.sendEmail({
     "From": "unibook@hereips.com",
     "To": address,
     "Subject": "Verify your official university email.",
     "TextBody": "Hello from Unibook! Your activation code for Unibook is " + activation,
      },function(error, sucess){
        if(error){
            debug(error);
            callback({sucess:false, message:'cannot send email for verification to '+address, code:'e01'},null);
            return;
        }
            callback(null,null);
            debug('email sent to'+address);
      });
     
};

//middleware for email verifications
auth.prototype.emailVerificationMiddleware = function(req, res, next){
        var code = req.params.veriCode;
        var uname = req.decoded.username;
        var tmp_code = client.hmget(uname+":tmpCode","tmpCode", function(err, reply){
                if(err){
                    debug(err);
                    return res.json({ success: false, message: 'Email Verification failed. Server error.' , code: 's01' });
                }
                if(reply != code){
                        return res.json({ success: false, message: 'Email Verification failed - code does not match.' , code: 'v01' });
                }
                //change the user account status to active
                user.findOne({username:uname},function(err, result){
                    if (err) {
                        debug(err);
                        return res.json({ success: false, message: 'Email Verification failed. Server error.' , code: 's01' });
                    };
                     //given username is not found on the database
                     if(!result){
                        debug('username'+uname+'not found');
                        return res.json({ success: false, message: 'Email Verification failed. User not found.', code: 'v02' });
                     }
                     result.mailVerified = true;
                     result.active = true;
                     result.save(function(err){
                            if(err){
                                 return res.json ({ success: false, message: 'Email Verificationfailed. Server error.' , code:'s01'});
                            }
                             //remove the temporary code from database
                            client.del(uname+":tmpCode",function(err,success){
                                if(err)
                                    debug(err);
                            });
                            return res.json({success:true});
                    });
                });
        });
};

//method to resend email
//should only be done when authenticated
//callback(err,success)
auth.prototype.resendEmailMiddleware = function(req, res, next){
    var uname = req.decoded.username;
    user.findOne({username:uname},function(err, result){
                 if (err) {
                    debug(err);
                    return res.json({ success: false, message: 'Resend email failed. Server error.' , code: 's01' });
                 };
                 //given username is not found on the database
                 if(!result){
                    debug('username'+uname+'not found');
                    return res.json({ success: false, message: 'Resend email failed. User not found.', code: 'e02' });
                 }
                 var timestamp = new Date().getTime();
                 var email = result.uniMail;
                 //four digit random number generation
                 var tmp_code = Math.floor(Math.random()*9000) + 1000;
                 client.hmset(uname+":tmpCode","tmpCode",tmp_code,"timestamp", timestamp, function(err,reply){
                        if(err||!reply){
                              debug(err);
                              return res.json({ success: false, message: 'Resend email failed. Server error.' , code: 's01' });
                        }
                        execEmail(email,tmp_code,function(err,success){
                            if(err){
                                debug(err);
                                return res.json({ success: false, message: 'Resend email failed. Server error.' , code: 's01' });
                            }
                            return res.json({success:true});
                        });
                 });
                 
    });
};
                    
//middleware for registration
auth.prototype.authenticationMiddleware = function(req, res, next){
    var uname_raw = req.body.username;
    var uname = uname_raw.toLowerCase();
    var pwd = req.body.password;
    req.unibook = {};
    user.findOne({username:uname},function(err, result){
                 if (err) {
                    debug(err);
                    return res.json({ success: false, message: 'Authentication failed. Server error.' , code: 's01' });
                 };
                 //given username is not found on the database
                 if(!result){
                    debug('username'+uname+'not found');
                    return res.json({ success: false, message: 'Authentication failed. User not found.', code: 'a01' });
                 } else if (result){
                    //check if password matches
                    var hash_pwd = require('crypto').createHash('sha256').update(pwd+result.salt,'utf8').digest('base64');
                    if(result.password != hash_pwd){
                        return res.json({ success: false, message: 'Authentication failed. Wrong password.', code: 'a02' });
                    }
                    if(result.mailVerified==false||result.active==false){
                     req.unibook.verified = false;
                    }
                    else {
                     req.unibook.verified = true;
                    }
                    var json_to_send = {};
                    json_to_send.username = result.username;
                    json_to_send.timestamp = result.accountTimestamp;
                    req.unibook.json_to_send = json_to_send;
                    req.unibook.name = result.name;
                    if(!req.decoded){
                     req.decoded = {};
                    }
                    req.decoded.username = uname;
                    next();
                 
                 }
                 
    });
};

//prerequsite: authenticationMiddleware and getUserUniMiddleware
auth.prototype.authResponseMiddleware = function(req, res, next){
    var uname_raw = req.body.username;
    var uname = uname_raw.toLowerCase();
    //now we confirm that the password is correct
    var token  = jwt.sign(JSON.parse(JSON.stringify(req.unibook.json_to_send)), config.jwtsecret,{});
    client.hmset(uname+":token", "token", token, "timestamp", req.unibook.json_to_send.timestamp, "name", req.unibook.name, function(err,reply){
                 if(err) {
                 debug (err);
                 return res.json({success:false, message:"token failure, server error", code:"s01"});
                 };
                 //if not verified
                 if(!req.unibook.verified){
                     return res.json({
                                     success: false,
                                     token: token,
                                     code:"a04",
                                     email:req.unibook.UserUnimail,
                     });
                 }
                 return res.json({
                                 success: true,
                                 token: token,
                                 email:req.unibook.UserUnimail,
                 });
                 
    });
}

//token middleware for expressjs
//very important class for authentication
auth.prototype.tokenMiddleware = function(req, res, next){
    //set up the unibook object
    req.unibook = {};
    // token should be in the header of the http request
    var token = req.headers['x-access-token'];
    if(!token) return res.sendFile(path.join(__dirname, '../web','index.html'));
    //check for ip address
    var ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
    if(token){
        jwt.verify(token, config.jwtsecret, function(err,decoded){
            //authentication failed, stops user from moving on
            if (err) {
                   debug(err);
                   return res.json({ success: false, message: 'token invalid', code: 't01'});
            } else {
                   req.decoded = decoded;
                   accountTimestamp(token, decoded, function(err, name){
                        if(err)
                            return res.json({ success: false, message: 'token expired', code: 't02'});
                        else{
                            req.unibook.name = name;
                            verifyUser(decoded, function(err){
                            if(err){
                                debug(err);
                                req.unibook.verified = false;
                            }
                            next();
                            });
                        }
                    });
            }
        });
    }
    else {
        //if there is no token, return
        debug('no token from ip:'+ip);
        return res.status(403).send({
                                    success: false,
                                    message: 'No token provided.',
                                    code: 't03',
        });
    }
};

/* Very important class for authentication
 * check redis for account timestamp, if the redis stamp is newer than the token, the user has reset the password and the old tokwn expires
 * callback(err,success)
 */
var accountTimestamp = function(token, decoded, callback){
    //check redis for timestamp
    client.hmget(decoded.username+":token","token", "timestamp", "name", function(err,reply){
                if(err) {return callback(err);}
                 else if (decoded.timestamp!=reply[1]||token!=reply[0]){
                return callback("expired");
                }
                else {
                 return callback(null, reply[2]);
                }
    });
};

//prerequisite:tokenMiddleware, accountTimestamp
var verifyUser = function(decoded, callback){
    user.findOne({username:decoded.username}, function(err, result){
        if(err)
            return callback("db error");
        if(!result){
            return callback("User not found");
        }
        if(result.mailVerified==false||result.active==false){
            return callback("User not active");
        }
        return callback(null);
    });
}

//block the unverified users
auth.prototype.unibookShield = function(req, res, next){
    if(req.unibook.verified==false){
        return res.json({success:false, message:"not verified", code:a04});
    }
    next();
}

//middleware to change the name
//prerequisite: tokenmiddleware
auth.prototype.changeNameMiddleware = function(req, res, next){
    var username = req.decoded.username;
    //change the name both in the database and redis
    user.findOne({username:username}, function(err, result){
         if(err){
            debug(err);
            return res.json({ success: false, message: 'Change name failed. Server error.' , code: 's01' });
         }
         if(!result){
            debug('username'+uname+'not found');
            return res.json({ success: false, message: 'Change name failed. User not found.', code: 'a01' });
         }
         result.name = req.body.newName;
         result.save(function(err){
             if(err) {
                debug(err);
                return res.json({ success: false, message: 'Change name failed. Server error.' , code: 's01' });
             }
            //now change the name of the user on redis server
            client.hmset(username+":token","name",req.params.newName, function(err, reply){
                 if(err) {
                    debug(err);
                    return res.json({ success: false, message: 'Change name failed. Server error.' , code: 's01' });
                 }
                 return res.json({success:true});
            });
         });
    });
};

//middleware to get the university name of a user
//prerequisite: tokenMiddleware or authenticationMiddleware
auth.prototype.getUserUniMiddleware = function(req, res, next){
    if(req.decoded&&req.decoded.username)
        uname = req.decoded.username;
    else
        uname = req.unibook.username;
    user.findOne({username:uname},function(err, result){
                 if (err) {
                    debug(err);
                    return res.json({ success: false, message: 'get user email failed. Server error.' , code: 's01' });
                 };
                 //given username is not found on the database
                 if(!result){
                    debug('username'+uname+'not found');
                    return res.json({ success: false, message: 'get user email failed. User not found.', code: 'a01' });
                 }
                 var tmp_mail = result.uniMail.split("@");
                 var arr = tmp_mail[tmp_mail.length-1].split(".");
                 var last_two = arr[arr.length-2]+"."+arr[arr.length-1];
                 req.unibook.UserUniname = university[last_two];
                 req.unibook.UserUnimail = result.uniMail;
                 if(!req.unibook.UserUniname||!req.unibook.UserUnimail)
                 {
                    return res.json({ success: false, message: 'get user email failed. User not found.', code: 'a01' },null);
                 }
                 next();
    });
}

//function to change user password
//callback(err,success)
auth.prototype.changePWDMiddleware = function(req, res, next){
    var uname = req.body.username;
    var oldPWD = req.body.oldPWD;
    var newPWD = req.body.newPWD;
    user.findOne({username:uname},function(err, result){
                 if(err){
                    debug(err);
                    return res.json({success:false, message:"server error", code:"s01"});
                 };
                 if(!result){
                    debug('username'+uname+'not found');
                    return res.json({success:false, message:'username'+uname+'not found', code:'c01'});
                 } else if (result){
                    //get salt from the database
                    var salt = result.salt;
                    //hash
                    var oldHash = require('crypto').createHash('sha256').update(oldPWD+salt,'utf8').digest('base64');
                    //check if password matches
                    if(result.password != oldHash){
                        return res.json({ success: false, message: 'Change password failed. Wrong password.', code:'c02' });
                    } else {
                        //set the timestamp
                        var timestamp = new Date().getTime();
                        //now we confirm that the password is correct, change the password to the new password
                        //generate salt
                        var salt = require('crypto').randomBytes(16).toString('base64');
                        //hash salt
                        result.password = require('crypto').createHash('sha256').update(newPWD+salt,'utf8').digest('base64');
                        //update salt in the database
                        result.salt = salt;
                        result.accountTimestamp = timestamp;
                        //todo:change redis timestamp
                        result.save(function(err){
                                  if(err){
                                    return res.json({ success: false, message: 'Change password failed. Server error.' , code:'s01'});
                                  }
                        });
                        var token = jwt.sign(JSON.parse(JSON.stringify(user)), config.jwtsecret,{});
                        //write the token and timestamp into redis
                        client.hmset([uname+":token", "token", token, "timestamp", timestamp], function(err, reply){
                            if(err) {
                                     debug(err);
                                     return res.json({ success: false, message: 'Change password failed. Server error.', code:'s01' });
                            }
                            if(!reply){
                              return res.json({ success: false, message: 'Change password failed. Server error.', code:'s01' });
                            }
                            return res.json ({
                                              success: true,
                                              token: token,
                            });
                        });
                    }
                 }
    });
};
